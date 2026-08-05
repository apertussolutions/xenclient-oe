#!/bin/bash
# Prepare a PXE tree from staged OpenXT images (skeleton).
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

STAGE="${OPENXT_STAGE_DIR}"
PXE="${STAGE}/pxe"
mkdir -p "${PXE}/tftp" "${PXE}/http"

if [ ! -d "${STAGE}/packages.main" ] || [ -z "$(ls -A "${STAGE}/packages.main" 2>/dev/null || true)" ]; then
	"${OPENXT_ROOT}/scripts/stage-repository.sh"
fi

log "PXE skeleton under ${PXE}"
log "Copying staged packages into http/ for optional HTTP boot"
if [ -d "${STAGE}/packages.main" ]; then
	rsync -a --delete "${STAGE}/packages.main/" "${PXE}/http/packages.main/" 2>/dev/null \
		|| cp -a "${STAGE}/packages.main/." "${PXE}/http/packages.main/" 2>/dev/null \
		|| true
fi

cat > "${PXE}/README.txt" << EOF
OpenXT PXE tree (skeleton)
==========================
http/   — package payload for HTTP-assisted install
tftp/   — place pxelinux.0 / grubnet / iPXE scripts here

Populate tftp/ from installer/syslinux artefacts once deploy-iso is complete.
Optional: rsync ${PXE}/ to your TFTP/HTTP servers.
EOF

log "wrote ${PXE}/README.txt"
