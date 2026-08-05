#!/bin/bash
# Create an OTA update.tar from staged OpenXT images (skeleton).
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

STAGE="${OPENXT_STAGE_DIR}"
OUT="${STAGE}/update/update-${OPENXT_RELEASE}.tar"

mkdir -p "$(dirname "${OUT}")"

if [ ! -d "${STAGE}/packages.main" ] || [ -z "$(ls -A "${STAGE}/packages.main" 2>/dev/null || true)" ]; then
	"${OPENXT_ROOT}/scripts/stage-repository.sh"
fi

require_cmd tar

if [ -z "$(ls -A "${STAGE}/packages.main" 2>/dev/null || true)" ]; then
	die "packages.main is empty; build product images first"
fi

log "creating ${OUT}"
tar -C "${STAGE}/packages.main" -cf "${OUT}" .
log "wrote ${OUT} ($(du -h "${OUT}" | awk '{print $1}'))"
log "TODO: sign update.tar and attach OpenXT upgrade metadata"
