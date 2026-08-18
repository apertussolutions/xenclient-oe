# intel-microcode is MACHINE specific for some reason.

# Since dom0 is shipped as a full image, the installer copies relevant files
# from /boot to the boot partition. Upstream recipe writes
# ${WORKDIR}/microcode_${PV}.cpio in do_compile (no longer a .bin in UNPACKDIR).
do_install:append() {
    install -d "${D}/boot"
    install -m 0644 "${WORKDIR}/microcode_${PV}.cpio" "${D}/boot/microcode_${PV}.cpio"
    ln -sfr "${D}/boot/microcode_${PV}.cpio" "${D}/boot/microcode_intel.bin"
}

# Override do_deploy to suit OpenXT existing bootstrap.
do_deploy() {
    install -m 0644 "${WORKDIR}/microcode_${PV}.cpio" "${DEPLOYDIR}/microcode_intel.bin"
}

FILES:${PN} += "/boot"
