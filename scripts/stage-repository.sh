#!/bin/bash
# Collect kas/BitBake deploy artefacts into a packages.main-style staging tree.
#
# Looks under OPENXT_DEPLOY_DIR (default build/tmp/deploy) for images and
# copies known basenames into OPENXT_STAGE_DIR.
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

STAGE="${OPENXT_STAGE_DIR}"
DEPLOY="${OPENXT_DEPLOY_DIR}"
IMAGES_ROOT="${DEPLOY}/images"

mkdir -p "${STAGE}/packages.main" "${STAGE}/iso" "${STAGE}/pxe" "${STAGE}/update"

if [ ! -d "${IMAGES_ROOT}" ]; then
	# Also try tmp-glibc layout used by some distros
	if [ -d "${OPENXT_BUILD_DIR}/tmp-glibc/deploy/images" ]; then
		IMAGES_ROOT="${OPENXT_BUILD_DIR}/tmp-glibc/deploy/images"
	else
		die "no deploy images tree found under ${DEPLOY} (build first with kas)"
	fi
fi

log "staging from ${IMAGES_ROOT} -> ${STAGE}"

# machine/image patterns produced by OpenXT
copy_glob() {
	local pattern="$1"
	local dest="$2"
	local found=0
	# shellcheck disable=SC2086
	for f in ${IMAGES_ROOT}/${pattern}; do
		if [ -e "$f" ]; then
			found=1
			log "  $(basename "$f")"
			cp -a "$f" "${dest}/"
		fi
	done
	return $((1 - found))
}

staged=0
# Dom0 / installer / stub
copy_glob "xenclient-dom0/xenclient-dom0-image*" "${STAGE}/packages.main" && staged=1 || true
copy_glob "xenclient-dom0/xenclient-initramfs-image*" "${STAGE}/packages.main" && staged=1 || true
copy_glob "xenclient-stubdomain/*stubdomain*" "${STAGE}/packages.main" && staged=1 || true
copy_glob "openxt-installer/xenclient-installer-image*" "${STAGE}/packages.main" && staged=1 || true
# Domains
copy_glob "xenclient-ndvm/*" "${STAGE}/packages.main" && staged=1 || true
copy_glob "usbvm/*" "${STAGE}/packages.main" && staged=1 || true
copy_glob "xenclient-syncvm/*" "${STAGE}/packages.main" && staged=1 || true
# UI
copy_glob "xenclient-uivm/*" "${STAGE}/packages.main" && staged=1 || true

if [ "${staged}" -eq 0 ]; then
	log "WARNING: no image artefacts matched; tree created empty"
	find "${IMAGES_ROOT}" -maxdepth 2 -type f 2>/dev/null | head -40 || true
else
	log "staging complete: ${STAGE}/packages.main"
	ls -la "${STAGE}/packages.main" | head -40
fi
