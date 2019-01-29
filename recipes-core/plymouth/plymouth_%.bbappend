
# OE's recipe explicitly builds X11 support, we don't want that.
DEPENDS = "libcap libpng cairo udev"

# Override RDEPENDS to strip dracut
RDEPENDS_${PN}-initrd = "bash"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://70-seat.rules"

do_install_append() {
	install -d ${D}/lib/udev/rules.d
	install -m 0644 ${WORKDIR}/70-seat.rules ${D}/lib/udev/rules.d/70-seat.rules

	rm ${D}/usr/share/plymouth/plymouthd.defaults
}
