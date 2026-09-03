FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Hypervisor kconfig used by xen-openxt.inc. OpenXT feature patches live on
# the xen_git tree (OPENXT_XEN_URI / OPENXT_XEN_BRANCH). To build from
# xenbits instead, also require xen-patches.inc (queue is stale vs 4.21).
SRC_URI:append = " \
    file://defconfig \
"

# Unset variables once injected by older meta-virtualization to avoid multilib
# dependency.  0001-tools-firmware-Build-firmware-as-ffreestanding.patch makes
# it unnecessary (from Xen 4.15).  Revisit if meta-virtualization/wrynose still
# exports these.
GLIBC32:x86-64 = ""
ADD_SYSROOT32_CFLAGS:x86-64 = ""

PACKAGECONFIG =+ "xsm"
PACKAGECONFIG =+ "hvm"

#--
# Add ovmf binary path
# vgabios dropped upstream in meta-virtualization (dev86-native gone; SeaBIOS covers VGA).
PACKAGECONFIG[hvm] = "--with-system-seabios="/usr/share/firmware/bios.bin" --with-system-ovmf="/usr/share/firmware/ovmf.bin",--disable-seabios,seabios ipxe ovmf,"

# meta-virt xen.inc still passes STDVGA_ROM/CIRRUSVGA_ROM pointing at the
# removed vgabios ipk. OpenXT hvmloader embeds in-tree VGABIOS-lgpl-latest.bin
# (see tools/firmware/hvmloader/Makefile); drop the stale command-line override.
EXTRA_OEMAKE:remove = "STDVGA_ROM=${STAGING_DIR_HOST}/usr/share/firmware/vgabios-0.8a.bin"
EXTRA_OEMAKE:remove = "CIRRUSVGA_ROM=${STAGING_DIR_HOST}/usr/share/firmware/vgabios-0.8a.cirrus.bin"

# The deploy task is detected as MACHINE-specific due to the variables it uses.
# The task is not required here so drop it.
deltask deploy
