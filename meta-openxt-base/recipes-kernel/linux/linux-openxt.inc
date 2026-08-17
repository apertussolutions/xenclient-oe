require recipes-kernel/linux/linux-openxt-copy-objtool.inc
require classes/kernel-module-signing.bbclass

DEPENDS += "bc-native"

S = "${UNPACKDIR}/linux-${PV}"

# Don't use update-alternatives for kernel at all. 
pkg_postinst:kernel-image () {
    mv $D/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}-${KERNEL_VERSION} $D/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}
}

pkg_postrm:kernel-image () {
    rm -f $D/${KERNEL_IMAGEDEST}/${KERNEL_IMAGETYPE}
}

# meta-oe linux.inc historically read ${WORKDIR}/defconfig; on wrynose file://
# entries land in UNPACKDIR. Ensure defconfig is visible either way.
do_configure:prepend() {
    if [ -f "${UNPACKDIR}/defconfig" ] && [ ! -e "${WORKDIR}/defconfig" ]; then
        ln -sf "${UNPACKDIR}/defconfig" "${WORKDIR}/defconfig"
    fi
}

# gcc 15 defaults to -std=gnu23; Linux 6.1 realmode and headers still need C11.
EXTRA_OEMAKE += "KCFLAGS=-std=gnu11"
