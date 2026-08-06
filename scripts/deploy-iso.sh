#!/bin/bash
# Generate a hybrid BIOS/EFI OpenXT installer ISO (bordel-compatible layout).
#
# Port of OpenXT/openxt do_build.sh:generic_do_installer_iso + do_installer_iso.sh
# for the kas/scripts workflow.
#
# Prerequisites:
#   - Product images available under OPENXT_IMAGE_ROOTS (kas or build-* deploys)
#   - xorriso, mkfs.fat (dosfstools), mtools
#   - Development certs for repository signing (optional but recommended)
#
# Environment (see scripts/common.sh):
#   OPENXT_STAGE_DIR, OPENXT_IMAGE_ROOTS, OPENXT_VERSION, OPENXT_BUILD_ID,
#   OPENXT_ISO_LABEL, OPENXT_CERTS_DIR
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# dosfstools often installs to /sbin (not on non-root PATH)
export PATH="/sbin:/usr/sbin:${PATH}"

require_cmd xorriso
require_cmd dd
require_cmd sync
# mkfs.fat may be mkfs.vfat
if command -v mkfs.fat >/dev/null 2>&1; then
	MKFS_FAT=mkfs.fat
elif command -v mkfs.vfat >/dev/null 2>&1; then
	MKFS_FAT=mkfs.vfat
else
	die "required command not found: mkfs.fat (install dosfstools)"
fi
require_cmd mmd
require_cmd mcopy

STAGE="${OPENXT_STAGE_DIR}"
RAW="${STAGE}/raw"
REPO="${STAGE}/repository"
ISO_WORK="${STAGE}/iso/installer"
ISO_OUT="${STAGE}/iso/installer.iso"
ISO_LABEL="${OPENXT_ISO_LABEL}"

# Ensure staged raw/ + packages.main exist
if [ ! -f "${RAW}/installer/rootfs.cpio.gz" ] || [ ! -d "${REPO}/packages.main" ]; then
	log "staging incomplete; running stage-repository.sh"
	"${OPENXT_ROOT}/scripts/stage-repository.sh"
fi

require_file "${RAW}/installer/rootfs.cpio.gz"
require_dir "${RAW}/installer/iso"
require_file "${RAW}/isohdpfx.bin"
require_file "${RAW}/grubx64.efi"
require_dir "${REPO}/packages.main"

log "building installer ISO work tree at ${ISO_WORK}"
rm -rf "${ISO_WORK}"
mkdir -p "${ISO_WORK}/isolinux"

# isolinux / syslinux bits from installer image deploy
cp -a "${RAW}/installer/iso/." "${ISO_WORK}/isolinux/"
# Expand version tokens in boot banner
if [ -f "${ISO_WORK}/isolinux/bootmsg.txt" ]; then
	sed -i \
		-e "s|\$OPENXT_VERSION|${OPENXT_VERSION}|g" \
		-e "s|\$OPENXT_BUILD_ID|${OPENXT_BUILD_ID}|g" \
		"${ISO_WORK}/isolinux/bootmsg.txt"
fi

copy_boot() {
	local name="$1"
	local src="$2"
	if [ -f "${src}" ]; then
		cp -a "${src}" "${ISO_WORK}/isolinux/${name}"
		log "  isolinux/${name}"
	else
		die "missing boot payload: ${src}"
	fi
}

copy_boot xen.gz "${RAW}/installer/xen.gz"
copy_boot vmlinuz "${RAW}/installer/vmlinuz"
copy_boot tboot.gz "${RAW}/installer/tboot.gz"
copy_boot rootfs.gz "${RAW}/installer/rootfs.cpio.gz"

# ACMs + microcode listed in isolinux.cfg
for f in snb_ivb.bin bdw_hsw.bin skl_kbl_aml.bin cfl_wkl_cml.bin \
	cml_s.bin cml_s_tgp.bin rkls.bin tgl.bin adl.bin \
	microcode_intel.bin license-SINIT-ACMs.txt; do
	if [ -f "${RAW}/installer/${f}" ]; then
		cp -a "${RAW}/installer/${f}" "${ISO_WORK}/isolinux/${f}"
		log "  isolinux/${f}"
	else
		log "  WARNING: ACM/ucode missing: ${f}"
	fi
done

# packages.main repository (XC-PACKAGES, XC-REPOSITORY, images, signature)
log "  embedding packages.main repository"
cp -a "${REPO}/." "${ISO_WORK}/"

# EFI system partition image (El Torito alt-boot)
EFIBOOTIMG="${ISO_WORK}/isolinux/efiboot.img"
log "  create ${EFIBOOTIMG}"
dd if=/dev/zero bs=1M count=5 of="${EFIBOOTIMG}" status=none
"${MKFS_FAT}" "${EFIBOOTIMG}" >/dev/null
mmd -i "${EFIBOOTIMG}" ::EFI
mmd -i "${EFIBOOTIMG}" ::EFI/BOOT
mcopy -i "${EFIBOOTIMG}" "${RAW}/grubx64.efi" ::EFI/BOOT/BOOTX64.EFI
sync

# Hybrid ISO via xorriso (OpenXT/openxt do_installer_iso.sh)
mkdir -p "$(dirname "${ISO_OUT}")"
log "  xorriso -> ${ISO_OUT} (label=${ISO_LABEL})"
xorriso -as mkisofs \
	-o "${ISO_OUT}" \
	-isohybrid-mbr "${RAW}/isohdpfx.bin" \
	-c "isolinux/boot.cat" \
	-b "isolinux/isolinux.bin" \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e "isolinux/efiboot.img" \
	-no-emul-boot \
	-isohybrid-gpt-basdat \
	-r \
	-J \
	-l \
	-V "${ISO_LABEL}" \
	-f \
	"${ISO_WORK}"

# Keep work tree for inspection unless OPENXT_ISO_KEEP_WORK=0
if [ "${OPENXT_ISO_KEEP_WORK:-1}" = "0" ]; then
	rm -rf "${ISO_WORK}"
fi

# Also publish a versioned symlink/name
VERSIONED="${STAGE}/iso/openxt-installer-${OPENXT_RELEASE}.iso"
ln -sfn "$(basename "${ISO_OUT}")" "${VERSIONED}"

sz=$(du -h "${ISO_OUT}" | awk '{print $1}')
log "ISO ready: ${ISO_OUT} (${sz})"
log "  label=${ISO_LABEL} version=${OPENXT_VERSION} build=${OPENXT_BUILD_ID}"
# Basic sanity: ISO 9660 magic
if command -v file >/dev/null 2>&1; then
	file "${ISO_OUT}" || true
fi
if command -v isoinfo >/dev/null 2>&1; then
	isoinfo -d -i "${ISO_OUT}" 2>/dev/null | head -15 || true
elif command -v xorriso >/dev/null 2>&1; then
	xorriso -indev "${ISO_OUT}" -pvd_info 2>/dev/null | head -20 || true
fi
