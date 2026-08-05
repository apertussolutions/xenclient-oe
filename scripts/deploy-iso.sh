#!/bin/bash
# Produce a hybrid BIOS/EFI installer ISO from staged OpenXT artefacts.
#
# First-pass: validates tools and staged installer image presence; full
# bordel-parity xorriso recipe is a follow-up.
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_cmd xorriso

STAGE="${OPENXT_STAGE_DIR}"
OUT_DIR="${STAGE}/iso"
ISO_NAME="openxt-installer-${OPENXT_RELEASE}.iso"
ISO_PATH="${OUT_DIR}/${ISO_NAME}"

mkdir -p "${OUT_DIR}"

if [ ! -d "${STAGE}/packages.main" ] || [ -z "$(ls -A "${STAGE}/packages.main" 2>/dev/null || true)" ]; then
	log "staging tree empty; running stage-repository.sh"
	"${OPENXT_ROOT}/scripts/stage-repository.sh"
fi

# Prefer installer rootfs / ISO payload if already produced by the image recipe.
INSTALLER_CANDIDATES=(
	"${STAGE}/packages.main/xenclient-installer-image"*
	"${OPENXT_BUILD_DIR}/tmp/deploy/images/openxt-installer/"*
	"${OPENXT_BUILD_DIR}/tmp-glibc/deploy/images/openxt-installer/"*
)

payload=""
for pattern in "${INSTALLER_CANDIDATES[@]}"; do
	# shellcheck disable=SC2086
	for f in ${pattern}; do
		if [ -e "$f" ]; then
			payload="$f"
			break 2
		fi
	done
done

if [ -z "${payload}" ]; then
	die "no installer deploy artefact found; build kas/installer.yml first"
fi

log "installer payload: ${payload}"
log "NOTE: full hybrid ISO assembly (syslinux + EFI + isohybrid) is not yet ported from bordel."
log "Creating a placeholder archive at ${ISO_PATH}.placeholder for pipeline wiring."

{
	echo "OpenXT installer ISO placeholder"
	echo "release=${OPENXT_RELEASE}"
	echo "payload=${payload}"
	echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "${ISO_PATH}.placeholder"

log "wrote ${ISO_PATH}.placeholder"
log "TODO: replace with xorriso -as mkisofs ... && isohybrid --uefi ${ISO_PATH}"
