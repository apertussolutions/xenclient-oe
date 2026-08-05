# Shared helpers for OpenXT pre/post build scripts.
# shellcheck shell=bash

# Resolve repository root (parent of scripts/).
openxt_repo_root() {
	local here
	here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	cd "${here}/.." && pwd
}

OPENXT_ROOT="${OPENXT_ROOT:-$(openxt_repo_root)}"

# Prefer kas workspace instance (KAS_BUILD_DIR) when already exported by
# kas-init-build-env; otherwise fall back to monorepo ./build.
OPENXT_BUILD_DIR="${KAS_BUILD_DIR:-${OPENXT_BUILD_DIR:-${OPENXT_ROOT}/build}}"
OPENXT_CERTS_DIR="${OPENXT_CERTS_DIR:-${OPENXT_BUILD_DIR}/certs}"
OPENXT_DEPLOY_DIR="${OPENXT_DEPLOY_DIR:-${OPENXT_BUILD_DIR}/tmp/deploy}"
OPENXT_STAGE_DIR="${OPENXT_STAGE_DIR:-${OPENXT_BUILD_DIR}/staging}"
OPENXT_RELEASE="${OPENXT_RELEASE:-10.0.0}"
OPENXT_VERSION="${OPENXT_VERSION:-${OPENXT_RELEASE}}"
OPENXT_BUILD_ID="${OPENXT_BUILD_ID:-0}"
OPENXT_UPGRADEABLE_RELEASES="${OPENXT_UPGRADEABLE_RELEASES:-9.0.0 9.0.1 9.0.2}"
OPENXT_ISO_LABEL="${OPENXT_ISO_LABEL:-OpenXT-${OPENXT_VERSION}}"

# Colon-separated list of deploy/images roots to search.
# Prefer the active kas instance, then other instances under the workspace.
_openxt_default_image_roots() {
	local roots=()
	local d ws
	ws="${OPENXT_KAS_WORKSPACE:-}"
	if [ -z "${ws}" ] && [ -d "$(cd "${OPENXT_ROOT}/.." && pwd)/openxt-kas" ]; then
		ws="$(cd "${OPENXT_ROOT}/.." && pwd)/openxt-kas"
	fi

	for d in \
		"${OPENXT_BUILD_DIR}/tmp-glibc/deploy/images" \
		"${OPENXT_BUILD_DIR}/tmp/deploy/images" \
		"${OPENXT_DEPLOY_DIR}/images"
	do
		[ -d "$d" ] && roots+=("$d")
	done

	if [ -n "${ws}" ] && [ -d "${ws}" ]; then
		local inst
		for inst in "${ws}"/build-*/tmp-glibc/deploy/images; do
			[ -d "${inst}" ] && roots+=("${inst}")
		done
		for inst in "${ws}"/build-*/tmp/deploy/images; do
			[ -d "${inst}" ] && roots+=("${inst}")
		done
	fi

	# Also honour explicit OPENXT_IMAGE_ROOTS (prepended below by caller env)
	if [ -n "${OPENXT_IMAGE_ROOTS:-}" ]; then
		local IFS=':'
		# shellcheck disable=SC2206
		local extra=(${OPENXT_IMAGE_ROOTS})
		roots=("${extra[@]}" "${roots[@]}")
	fi
	(IFS=':'; echo "${roots[*]}")
}

OPENXT_IMAGE_ROOTS="${OPENXT_IMAGE_ROOTS:-$(_openxt_default_image_roots)}"

log() {
	printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

die() {
	log "ERROR: $*"
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_file() {
	[ -f "$1" ] || die "required file missing: $1"
}

require_dir() {
	[ -d "$1" ] || die "required directory missing: $1"
}

# Find first existing file matching path under any image root.
# Usage: openxt_find_image <relpath-under-images>   e.g. openxt-installer/isohdpfx.bin
openxt_find_image() {
	local rel="$1"
	local root
	local IFS=':'
	for root in ${OPENXT_IMAGE_ROOTS}; do
		if [ -e "${root}/${rel}" ]; then
			printf '%s\n' "${root}/${rel}"
			return 0
		fi
	done
	return 1
}

# Find first existing path matching a glob under image roots.
# Usage: openxt_find_image_glob 'xenclient-dom0/xenclient-dom0-image-*.ext3.gz'
openxt_find_image_glob() {
	local pattern="$1"
	local root matches
	local IFS=':'
	for root in ${OPENXT_IMAGE_ROOTS}; do
		# shellcheck disable=SC2086
		matches=$(compgen -G "${root}/${pattern}" || true)
		if [ -n "${matches}" ]; then
			printf '%s\n' ${matches} | sort | tail -1
			return 0
		fi
	done
	return 1
}
