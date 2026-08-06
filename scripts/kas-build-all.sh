#!/bin/bash
# Build all OpenXT product images via kas (headless + domains + UI), then stage/ISO.
#
# Uses local layer clones when present (kas/common/local-layers.yml) and shares
# downloads/sstate with the sibling build-base tree when available.
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_cmd kas

cd "${OPENXT_ROOT}"

export KAS_BUILD_DIR="${KAS_BUILD_DIR:-${OPENXT_BUILD_DIR}}"
mkdir -p "${KAS_BUILD_DIR}"

# Prefer existing shared caches from validation builds
PARENT="$(cd "${OPENXT_ROOT}/.." && pwd)"
if [ -d "${PARENT}/build-base/downloads" ]; then
	export DL_DIR="${DL_DIR:-${PARENT}/build-base/downloads}"
fi
if [ -d "${PARENT}/build-base/sstate-cache" ]; then
	export SSTATE_DIR="${SSTATE_DIR:-${PARENT}/build-base/sstate-cache}"
fi

# Host tools (cmake/patch) for Trixie builders
if [ -d "${PARENT}/hosttools-bin" ]; then
	export PATH="${PARENT}/hosttools-bin:${PARENT}/hosttools-prefix/bin:${PARENT}/bin:${PATH}"
fi

INCLUDE_ARGS=()
if [ -f "${OPENXT_ROOT}/kas/common/local-layers.yml" ] && [ -d "${PARENT}/layers/openembedded-core" ]; then
	INCLUDE_ARGS+=(-I "${OPENXT_ROOT}/kas/common/local-layers.yml")
	log "using local layer clones under ${PARENT}/layers"
fi

# Certs for the kas build dir
export OPENXT_CERTS_DIR="${OPENXT_CERTS_DIR:-${KAS_BUILD_DIR}/certs}"
if [ ! -f "${OPENXT_CERTS_DIR}/dev-cacert.pem" ]; then
	# reuse validation certs if present
	if [ -d "${PARENT}/build-base/certs" ]; then
		mkdir -p "${OPENXT_CERTS_DIR}"
		cp -a "${PARENT}/build-base/certs/." "${OPENXT_CERTS_DIR}/"
	else
		"${OPENXT_ROOT}/scripts/generate-certs.sh"
	fi
fi

# Build order: initramfs/stubdomain before dom0; domains; ui; installer last ok any time
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

# Allow subset: ./kas-build-all.sh ndvm usbvm syncvm
if [ "$#" -gt 0 ]; then
	IMAGES=("$@")
fi

log "KAS_BUILD_DIR=${KAS_BUILD_DIR}"
log "DL_DIR=${DL_DIR:-<kas default>}"
log "SSTATE_DIR=${SSTATE_DIR:-<kas default>}"

failures=0
for img in "${IMAGES[@]}"; do
	cfg="${OPENXT_ROOT}/kas/${img}.yml"
	[ -f "${cfg}" ] || die "missing kas config: ${cfg}"
	log "===== kas build ${img} ====="
	if kas build "${INCLUDE_ARGS[@]+"${INCLUDE_ARGS[@]}"}" "${cfg}"; then
		log "OK ${img}"
	else
		rc=$?
		log "FAIL ${img} (rc=${rc})"
		failures=$((failures + 1))
	fi
done

if [ "${failures}" -ne 0 ]; then
	die "${failures} kas image build(s) failed"
fi

log "all requested kas builds succeeded"
log "next: ./scripts/stage-repository.sh && ./scripts/deploy-iso.sh"
