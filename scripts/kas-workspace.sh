# Shared OpenXT kas workspace helpers.
# shellcheck shell=bash
# Sourced by kas-init-build-env and kas-build-all.sh (not executed).
#
# Layout (after init):
#   $OPENXT_KAS_WORKSPACE/
#     layers/ downloads/ sstate-cache/ certs/
#     build-<instance>/          # KAS_BUILD_DIR
#   $OPENXT_ROOT/layers -> $WORKSPACE/layers   # gitignored symlink
#
# Committed kas YAML uses path: layers/<repo> (relative to monorepo root) and
# DL_DIR/SSTATE_DIR = ${TOPDIR}/../... so plain `kas build kas/dom0.yml` works
# with no config concatenation and no openxt_kas_cfg_for helper.

# Environment (set by init / builders):
#   OPENXT_ROOT              monorepo root (xenclient-oe)
#   OPENXT_KAS_WORKSPACE     workspace base (layers, downloads, sstate, builds)
#   OPENXT_KAS_INSTANCE      build instance name (default: default)
#   KAS_BUILD_DIR            instance build dir (kas conf/tmp)
#   DL_DIR / SSTATE_DIR      shared caches under workspace
#   OPENXT_LAYERS_DIR        $WORKSPACE/layers
#   OPENXT_CERTS_DIR         signing certs
#   OPENXT_LAYER_IMPORT      optional explicit dir of pre-cloned layers to link

openxt_kas_default_workspace() {
	# Sibling of the monorepo so the git tree stays clean.
	printf '%s\n' "$(cd "${OPENXT_ROOT}/.." && pwd)/openxt-kas"
}

# Expand user paths and make absolute when the path already exists;
# otherwise resolve the parent and append the final component.
openxt_kas_abspath_maybe_new() {
	local raw="$1"
	# shellcheck disable=SC2086
	raw="$(eval echo ${raw})"
	if [ -d "${raw}" ]; then
		cd "${raw}" && pwd
		return 0
	fi
	local parent base
	parent="$(dirname "${raw}")"
	base="$(basename "${raw}")"
	if [ -d "${parent}" ]; then
		printf '%s/%s\n' "$(cd "${parent}" && pwd)" "${base}"
	else
		printf '%s\n' "${raw}"
	fi
}

# External repos that live under workspace/layers (and monorepo layers/ link).
OPENXT_KAS_LAYER_NAMES=(
	bitbake
	openembedded-core
	meta-openembedded
	meta-intel
	meta-selinux
	meta-virtualization
	meta-qt5
	meta-vglass
	meta-openxt-ocaml-platform
	meta-openxt-haskell-platform
	meta-java
)

openxt_kas_resolve_paths() {
	: "${OPENXT_ROOT:?OPENXT_ROOT must be set}"

	local raw_ws
	raw_ws="${OPENXT_KAS_WORKSPACE:-$(openxt_kas_default_workspace)}"
	OPENXT_KAS_WORKSPACE="$(openxt_kas_abspath_maybe_new "${raw_ws}")"

	OPENXT_KAS_INSTANCE="${OPENXT_KAS_INSTANCE:-default}"
	OPENXT_KAS_INSTANCE="$(printf '%s' "${OPENXT_KAS_INSTANCE}" | tr -c 'A-Za-z0-9._-' '_')"

	OPENXT_LAYERS_DIR="${OPENXT_LAYERS_DIR:-${OPENXT_KAS_WORKSPACE}/layers}"
	export OPENXT_KAS_WORKSPACE OPENXT_KAS_INSTANCE OPENXT_LAYERS_DIR

	export KAS_BUILD_DIR="${KAS_BUILD_DIR:-${OPENXT_KAS_WORKSPACE}/build-${OPENXT_KAS_INSTANCE}}"
	export OPENXT_BUILD_DIR="${KAS_BUILD_DIR}"
	export DL_DIR="${DL_DIR:-${OPENXT_KAS_WORKSPACE}/downloads}"
	export SSTATE_DIR="${SSTATE_DIR:-${OPENXT_KAS_WORKSPACE}/sstate-cache}"
	export OPENXT_CERTS_DIR="${OPENXT_CERTS_DIR:-${OPENXT_KAS_WORKSPACE}/certs}"
	export OPENXT_DEPLOY_DIR="${OPENXT_DEPLOY_DIR:-${KAS_BUILD_DIR}/tmp/deploy}"
	export OPENXT_STAGE_DIR="${OPENXT_STAGE_DIR:-${KAS_BUILD_DIR}/staging}"
}

openxt_kas_link_or_keep() {
	local dest="$1" src="$2"
	if [ -e "${dest}" ] || [ -L "${dest}" ]; then
		return 0
	fi
	ln -sfn "${src}" "${dest}"
}

openxt_kas_setup_dirs() {
	openxt_kas_resolve_paths
	mkdir -p \
		"${OPENXT_KAS_WORKSPACE}" \
		"${OPENXT_LAYERS_DIR}" \
		"${DL_DIR}" \
		"${SSTATE_DIR}" \
		"${OPENXT_CERTS_DIR}" \
		"${KAS_BUILD_DIR}" \
		"${OPENXT_KAS_WORKSPACE}/bin"

	# Re-resolve after mkdir so paths are absolute.
	OPENXT_KAS_WORKSPACE="$(cd "${OPENXT_KAS_WORKSPACE}" && pwd)"
	OPENXT_LAYERS_DIR="$(cd "${OPENXT_LAYERS_DIR}" && pwd)"
	DL_DIR="$(cd "${DL_DIR}" && pwd)"
	SSTATE_DIR="$(cd "${SSTATE_DIR}" && pwd)"
	OPENXT_CERTS_DIR="$(cd "${OPENXT_CERTS_DIR}" && pwd)"
	KAS_BUILD_DIR="$(cd "${KAS_BUILD_DIR}" && pwd)"
	export OPENXT_KAS_WORKSPACE OPENXT_LAYERS_DIR DL_DIR SSTATE_DIR OPENXT_CERTS_DIR
	export KAS_BUILD_DIR OPENXT_BUILD_DIR="${KAS_BUILD_DIR}"

	# Monorepo-relative layers/ path used by committed kas YAML (path: layers/...).
	# Point it at the workspace layers tree (symlink, gitignored).
	if [ -L "${OPENXT_ROOT}/layers" ]; then
		ln -sfn "${OPENXT_LAYERS_DIR}" "${OPENXT_ROOT}/layers"
	elif [ -e "${OPENXT_ROOT}/layers" ] && [ ! -L "${OPENXT_ROOT}/layers" ]; then
		# Real directory already present (e.g. prior kas checkout into monorepo).
		# Leave it; workspace layers dir may be separate unless user sets
		# OPENXT_LAYERS_DIR to that path.
		:
	else
		ln -sfn "${OPENXT_LAYERS_DIR}" "${OPENXT_ROOT}/layers"
	fi

	# Convenience link for humans browsing the workspace.
	openxt_kas_link_or_keep "${OPENXT_LAYERS_DIR}/xenclient-oe" "${OPENXT_ROOT}"

	# Optional explicit import of pre-cloned layers (no auto-discovery).
	if [ -n "${OPENXT_LAYER_IMPORT:-}" ]; then
		if [ ! -d "${OPENXT_LAYER_IMPORT}" ]; then
			echo "WARNING: OPENXT_LAYER_IMPORT is not a directory: ${OPENXT_LAYER_IMPORT}" >&2
		else
			local import_dir name
			import_dir="$(cd "${OPENXT_LAYER_IMPORT}" && pwd)"
			for name in "${OPENXT_KAS_LAYER_NAMES[@]}"; do
				if [ -e "${import_dir}/${name}" ] && [ ! -e "${OPENXT_LAYERS_DIR}/${name}" ]; then
					openxt_kas_link_or_keep "${OPENXT_LAYERS_DIR}/${name}" \
						"$(cd "${import_dir}/${name}" && pwd)"
				fi
			done
		fi
	fi

	{
		echo "# OpenXT kas workspace — generated by kas-init-build-env"
		echo "OPENXT_KAS_WORKSPACE=${OPENXT_KAS_WORKSPACE}"
		echo "OPENXT_ROOT=${OPENXT_ROOT}"
		echo "OPENXT_LAYERS_DIR=${OPENXT_LAYERS_DIR}"
		echo "created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	} > "${OPENXT_KAS_WORKSPACE}/.openxt-kas-workspace"
}

openxt_kas_find_python311() {
	local c
	for c in \
		"${OPENXT_PYTHON3:-}" \
		"${OPENXT_KAS_WORKSPACE}/bin/python3" \
		"${OPENXT_KAS_WORKSPACE}/bin/python3.11" \
		"$(cd "${OPENXT_ROOT}/.." && pwd)/bin/python3" \
		"$(command -v python3.11 2>/dev/null || true)"
	do
		[ -n "${c}" ] || continue
		[ -x "${c}" ] || continue
		if "${c}" -c 'import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 11) else 1)' 2>/dev/null; then
			readlink -f "${c}"
			return 0
		fi
	done
	if command -v python3.11 >/dev/null 2>&1; then
		readlink -f "$(command -v python3.11)"
		return 0
	fi
	return 1
}

openxt_kas_hosttools_path_prefix() {
	local parts=()
	local d
	for d in \
		"${OPENXT_HOSTTOOLS_BIN:-}" \
		"${OPENXT_KAS_WORKSPACE}/hosttools-bin" \
		"${OPENXT_KAS_WORKSPACE}/hosttools-prefix/bin" \
		"${OPENXT_KAS_WORKSPACE}/bin" \
		"$(cd "${OPENXT_ROOT}/.." && pwd)/bin"
	do
		[ -n "${d}" ] && [ -d "${d}" ] && parts+=("${d}")
	done
	parts+=("/usr/local/haskell/bin")
	[ -n "${HOME:-}" ] && parts+=("${HOME}/.local/bin")
	if [ -d "${OPENXT_LAYERS_DIR}/openembedded-core/scripts" ]; then
		parts+=("${OPENXT_LAYERS_DIR}/openembedded-core/scripts")
	fi
	if [ -d "${OPENXT_LAYERS_DIR}/bitbake/bin" ]; then
		parts+=("${OPENXT_LAYERS_DIR}/bitbake/bin")
	fi
	parts+=(/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin)
	local IFS=':'
	printf '%s\n' "${parts[*]}"
}

openxt_kas_apply_python_wrappers() {
	local py311=""
	py311="$(openxt_kas_find_python311 || true)"
	[ -n "${py311}" ] || return 0
	local d
	for d in "${OPENXT_LAYERS_DIR}/bitbake/bin" "${OPENXT_LAYERS_DIR}/openembedded-core/scripts"; do
		[ -d "${d}" ] || continue
		ln -sfn "${py311}" "${d}/python3"
		ln -sfn "${py311}" "${d}/python"
	done
	mkdir -p "${OPENXT_KAS_WORKSPACE}/bin"
	ln -sfn "${py311}" "${OPENXT_KAS_WORKSPACE}/bin/python3"
	ln -sfn "${py311}" "${OPENXT_KAS_WORKSPACE}/bin/python"
	export OPENXT_PYTHON3="${py311}"
}

openxt_kas_export_host_env() {
	openxt_kas_resolve_paths
	export PATH="$(openxt_kas_hosttools_path_prefix)${PATH:+:${PATH}}"
	# Dunfell bitbake: allow DL_DIR / SSTATE_DIR from the environment.
	if [ -n "${BB_ENV_PASSTHROUGH_ADDITIONS:-}" ] || [ -n "${BB_ENV_EXTRAWHITE:-}" ]; then
		export BB_ENV_PASSTHROUGH_ADDITIONS="${BB_ENV_PASSTHROUGH_ADDITIONS:-${BB_ENV_EXTRAWHITE:-}} DL_DIR SSTATE_DIR OPENXT_CERTS_DIR"
		export BB_ENV_EXTRAWHITE="${BB_ENV_EXTRAWHITE:-} DL_DIR SSTATE_DIR OPENXT_CERTS_DIR"
	else
		export BB_ENV_PASSTHROUGH_ADDITIONS="DL_DIR SSTATE_DIR OPENXT_CERTS_DIR"
		export BB_ENV_EXTRAWHITE="DL_DIR SSTATE_DIR OPENXT_CERTS_DIR"
	fi
	openxt_kas_apply_python_wrappers || true
}

openxt_kas_ensure_workspace() {
	openxt_kas_setup_dirs
	openxt_kas_export_host_env
}
