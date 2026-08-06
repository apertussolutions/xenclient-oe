#!/bin/bash
# Assemble bordel-style raw/ + packages.main repository from deploy/images trees.
#
# Collects installer, dom0, service-domain, and UIVM artefacts (kas or legacy
# build-* deploys via OPENXT_IMAGE_ROOTS) into OPENXT_STAGE_DIR.
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

STAGE="${OPENXT_STAGE_DIR}"
RAW="${STAGE}/raw"
REPO="${STAGE}/repository/packages.main"
MANIFEST="${OPENXT_MANIFEST:-${OPENXT_ROOT}/scripts/manifest}"

require_file "${MANIFEST}"
mkdir -p "${RAW}/installer" "${REPO}"

log "image roots: ${OPENXT_IMAGE_ROOTS}"
log "staging into ${STAGE}"

copy_to() {
	local src="$1"
	local dst="$2"
	mkdir -p "$(dirname "${dst}")"
	cp -a "${src}" "${dst}"
	log "  $(basename "${dst}") <- ${src}"
}

# --- Installer machine artefacts -------------------------------------------
inst_rootfs=$(openxt_find_image_glob 'openxt-installer/xenclient-installer-image-openxt-installer.cpio.gz' \
	|| openxt_find_image_glob 'openxt-installer/xenclient-installer-image-*.cpio.gz' \
	|| true)
[ -n "${inst_rootfs}" ] || die "installer rootfs.cpio.gz not found (build kas/installer.yml)"

copy_to "${inst_rootfs}" "${RAW}/installer/rootfs.cpio.gz"

inst_iso_dir=$(openxt_find_image 'openxt-installer/iso')
[ -n "${inst_iso_dir}" ] || die "openxt-installer/iso/ not found"
rm -rf "${RAW}/installer/iso"
cp -a "${inst_iso_dir}" "${RAW}/installer/iso"
log "  installer/iso/"

if netboot_dir=$(openxt_find_image 'openxt-installer/netboot'); then
	rm -rf "${RAW}/installer/netboot"
	cp -a "${netboot_dir}" "${RAW}/installer/netboot"
	log "  installer/netboot/"
fi

for pair in \
	"openxt-installer/bzImage-openxt-installer.bin:installer/vmlinuz" \
	"openxt-installer/xen.gz:installer/xen.gz" \
	"openxt-installer/tboot.gz:installer/tboot.gz" \
	"openxt-installer/microcode_intel.bin:installer/microcode_intel.bin" \
	"openxt-installer/license-SINIT-ACMs.txt:installer/license-SINIT-ACMs.txt" \
	"openxt-installer/grub-efi-bootx64.efi:grubx64.efi" \
	"openxt-installer/isohdpfx.bin:isohdpfx.bin" \
	"openxt-installer/control.tar.bz2:control.tar.bz2"
do
	src_rel="${pair%%:*}"
	dst_rel="${pair##*:}"
	if src=$(openxt_find_image "${src_rel}"); then
		copy_to "${src}" "${RAW}/${dst_rel}"
	else
		log "  WARNING: missing optional ${src_rel}"
	fi
done

# ACM modules (current .bin names used by isolinux.cfg)
for acm in snb_ivb.bin bdw_hsw.bin skl_kbl_aml.bin cfl_wkl_cml.bin \
	cml_s.bin cml_s_tgp.bin rkls.bin tgl.bin adl.bin; do
	if src=$(openxt_find_image "openxt-installer/${acm}"); then
		copy_to "${src}" "${RAW}/installer/${acm}"
	fi
done

# --- Product rootfs images (repository payloads) ---------------------------
# dom0
if src=$(openxt_find_image_glob 'xenclient-dom0/xenclient-dom0-image-xenclient-dom0.ext3.gz' \
	|| openxt_find_image_glob 'xenclient-dom0/xenclient-dom0-image-*.ext3.gz'); then
	copy_to "${src}" "${RAW}/dom0-rootfs.ext3.gz"
else
	die "dom0 rootfs not found (build kas/dom0.yml)"
fi

# ndvm
if src=$(openxt_find_image_glob 'xenclient-ndvm/xenclient-ndvm-image-xenclient-ndvm.ext3.disk.vhd.gz' \
	|| openxt_find_image_glob 'xenclient-ndvm/xenclient-ndvm-image-*.ext3.disk.vhd.gz'); then
	copy_to "${src}" "${RAW}/ndvm-rootfs.ext3.disk.vhd.gz"
else
	die "ndvm rootfs not found (build kas/ndvm.yml)"
fi

# uivm
if src=$(openxt_find_image_glob 'xenclient-uivm/xenclient-uivm-image-xenclient-uivm.ext3.vhd.gz' \
	|| openxt_find_image_glob 'xenclient-uivm/xenclient-uivm-image-*.ext3.vhd.gz'); then
	copy_to "${src}" "${RAW}/uivm-rootfs.ext3.vhd.gz"
else
	die "uivm rootfs not found (build kas/uivm.yml)"
fi

# syncvm (optional)
if src=$(openxt_find_image_glob 'xenclient-syncvm/xenclient-syncvm-image-xenclient-syncvm.ext3.vhd.gz' \
	|| openxt_find_image_glob 'xenclient-syncvm/xenclient-syncvm-image-*.ext3.vhd.gz'); then
	copy_to "${src}" "${RAW}/syncvm-rootfs.ext3.vhd.gz"
fi

# xc-tools.iso (optional)
if src=$(openxt_find_image_glob '*/xc-tools.iso' || openxt_find_image 'xc-tools.iso'); then
	copy_to "${src}" "${RAW}/xc-tools.iso"
fi

# --- Build packages.main from manifest -------------------------------------
log "building packages.main from ${MANIFEST}"
: > "${REPO}/XC-PACKAGES"
rm -f "${REPO}/XC-REPOSITORY" "${REPO}/XC-SIGNATURE"

while read -r name format opt_req src dest; do
	# skip comments / blank
	case "${name}" in
		''|\#*) continue ;;
	esac
	if [ ! -e "${RAW}/${src}" ]; then
		if [ "${opt_req}" = "required" ]; then
			die "required package missing: ${src}"
		fi
		log "  skip optional missing ${src}"
		continue
	fi
	cp -a "${RAW}/${src}" "${REPO}/${src}"
	filesize=$(du -b "${REPO}/${src}" | awk '{print $1}')
	sha=$(sha256sum "${REPO}/${src}" | awk '{print $1}')
	echo "${name} ${filesize} ${sha} ${format} ${opt_req} ${src} ${dest}" \
		| tee -a "${REPO}/XC-PACKAGES" >/dev/null
	log "  package ${name} (${src})"
done < "${MANIFEST}"

PACKAGES_SHA256SUM=$(sha256sum "${REPO}/XC-PACKAGES" | awk '{print $1}')

# Pad XC-REPOSITORY to 1 MiB (repository signing expects fixed size).
{
	cat <<EOF
xc:main
pack:Base Pack
product:OpenXT
build:${OPENXT_BUILD_ID}
version:${OPENXT_VERSION}
release:${OPENXT_RELEASE}
upgrade-from:${OPENXT_UPGRADEABLE_RELEASES}
packages:${PACKAGES_SHA256SUM}
EOF
	yes ""
} | head -c 1048576 > "${REPO}/XC-REPOSITORY"

# Sign repository when certs are available
CERT="${REPO_DEV_SIGNING_CERT:-${OPENXT_CERTS_DIR}/dev-cacert.pem}"
KEY="${REPO_DEV_SIGNING_DEV:-${OPENXT_CERTS_DIR}/dev-cakey.pem}"
# Accept bordel's alternate KEY var name
if [ ! -f "${KEY}" ] && [ -f "${OPENXT_CERTS_DIR}/dev-cakey.pem" ]; then
	KEY="${OPENXT_CERTS_DIR}/dev-cakey.pem"
fi
if [ -f "${CERT}" ] && [ -f "${KEY}" ]; then
	log "signing repository with ${CERT}"
	"${OPENXT_ROOT}/scripts/sign-repo.sh" "${CERT}" "${KEY}" "${REPO}"
else
	log "WARNING: no signing certs at ${OPENXT_CERTS_DIR}; XC-SIGNATURE not created"
	log "  run: OPENXT_CERTS_DIR=... ./scripts/generate-certs.sh"
fi

log "staging complete:"
log "  raw:        ${RAW}"
log "  repository: ${REPO}"
ls -la "${REPO}" | head -30
