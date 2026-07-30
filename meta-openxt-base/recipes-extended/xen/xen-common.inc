FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# OpenXT hypervisor defconfig only. The OpenXT patchqueue is integrated into
# the openxt-4.21 branch of apertussolutions/openxt-xen (see xen*_git.bbappend).
SRC_URI_append = " \
    file://defconfig \
"

# Unset variables inherited from meta-virt dunfell to avoid multilib
# dependency.  0001-tools-firmware-Build-firmware-as-ffreestanding.patch makes
# it unnecessary (from Xen 4.15).  These can be removed in OE hardknott or
# later.
GLIBC32_x86-64 = ""
ADD_SYSROOT32_CFLAGS_x86-64 = ""

PACKAGECONFIG =+ "xsm"
PACKAGECONFIG =+ "hvm"

#--
# Add ovmf binary path
PACKAGECONFIG[hvm] = "--with-system-seabios="/usr/share/firmware/bios.bin" --with-system-ovmf="/usr/share/firmware/ovmf.bin",--disable-seabios,seabios ipxe vgabios ovmf,"

# The deploy task is detected as MACHINE-specific due to the variables it uses.
# The task is not required here so drop it.
deltask deploy
