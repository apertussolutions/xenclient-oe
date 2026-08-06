#!/bin/bash
# Build OpenXT product images using kas for configuration + bitbake for the build.
#
# Requires a kas workspace (see scripts/kas-init-build-env). If the shell has
# not already sourced the init script, this tool ensures a workspace using
# OPENXT_KAS_WORKSPACE / OPENXT_KAS_INSTANCE (or defaults).
#
# Kas generates conf/ and checks out layers; we then run bitbake with a
# known-good host PATH (Python 3.11, cmake, ghc) because conf env PATH would
# override oe-init's PATH inside kas's own build plugin.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPTS_DIR}/common.sh"
# shellcheck source=kas-workspace.sh
. "${SCRIPTS_DIR}/kas-workspace.sh"

require_cmd kas

cd "${OPENXT_ROOT}"

openxt_kas_ensure_workspace

export OPENXT_CERTS_DIR="${OPENXT_CERTS_DIR}"
if [ ! -f "${OPENXT_CERTS_DIR}/dev-cacert.pem" ]; then
	if [ -x "${OPENXT_ROOT}/scripts/generate-certs.sh" ]; then
		OPENXT_CERTS_DIR="${OPENXT_CERTS_DIR}" OPENXT_BUILD_DIR="${KAS_BUILD_DIR}" \
			"${OPENXT_ROOT}/scripts/generate-certs.sh" || true
	fi
fi

if [ ! -e "${OPENXT_ROOT}/layers" ]; then
	die "missing ${OPENXT_ROOT}/layers (run: source ./scripts/kas-init-build-env)"
fi

IMAGES=(
	initramfs
	stubdomain
	dom0
	installer
	ndvm
	usbvm
	syncvm
	uivm
)
if [ "$#" -gt 0 ]; then
	IMAGES=("$@")
fi

log "OPENXT_KAS_WORKSPACE=${OPENXT_KAS_WORKSPACE}"
log "OPENXT_KAS_INSTANCE=${OPENXT_KAS_INSTANCE}"
log "KAS_BUILD_DIR=${KAS_BUILD_DIR}"
log "OPENXT_LAYERS_DIR=${OPENXT_LAYERS_DIR}"
log "DL_DIR=${DL_DIR}"
log "SSTATE_DIR=${SSTATE_DIR}"
log "OPENXT_CERTS_DIR=${OPENXT_CERTS_DIR}"
if [ -n "${OPENXT_PYTHON3:-}" ]; then
	log "host python for bitbake: $(${OPENXT_PYTHON3} --version 2>&1)"
fi

target_for() {
	case "$1" in
		dom0) echo xenclient-dom0-image ;;
		initramfs) echo xenclient-initramfs-image ;;
		stubdomain) echo xenclient-stubdomain-initramfs-image ;;
		installer) echo xenclient-installer-image ;;
		ndvm) echo xenclient-ndvm-image ;;
		usbvm) echo usbvm-image ;;
		syncvm) echo xenclient-syncvm-image ;;
		uivm) echo xenclient-uivm-image ;;
		*) die "unknown image key: $1" ;;
	esac
}

failures=0
for img in "${IMAGES[@]}"; do
	cfg="${OPENXT_ROOT}/kas/${img}.yml"
	[ -f "${cfg}" ] || die "missing kas config: ${cfg}"
	target="$(target_for "${img}")"
	log "===== kas configure ${img} (${cfg}) ====="
	# Plain entry YAML — layer paths and shared caches come from committed
	# kas/common/base.yml (path: layers/..., DL_DIR = \${TOPDIR}/../...).
	if ! kas checkout "${cfg}"; then
		log "FAIL ${img} (kas checkout)"
		failures=$((failures + 1))
		continue
	fi

	log "===== bitbake ${target} ====="
	(
		set +u
		cd "${KAS_BUILD_DIR}"
		# shellcheck disable=SC1091
		BITBAKEDIR="${OPENXT_LAYERS_DIR}/bitbake" \
			source "${OPENXT_LAYERS_DIR}/openembedded-core/oe-init-build-env" "${KAS_BUILD_DIR}"
		set -u
		export PATH="$(openxt_kas_hosttools_path_prefix):${PATH}"
		openxt_kas_apply_python_wrappers || true
		if bitbake "${target}"; then
			log "OK ${img}"
		else
			rc=$?
			log "FAIL ${img} (bitbake rc=${rc})"
			exit "${rc}"
		fi
	) || failures=$((failures + 1))
done

if [ "${failures}" -ne 0 ]; then
	die "${failures} image build(s) failed"
fi

log "all requested kas builds succeeded"
log "next: ./scripts/stage-repository.sh && ./scripts/deploy-iso.sh"
