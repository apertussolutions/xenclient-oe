
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


PACKAGES += " \
	    plymouth-theme-details \
	    plymouth-theme-fade-in \
	    plymouth-theme-glow \
	    plymouth-theme-script \
	    plymouth-theme-solar \
	    plymouth-theme-spinfinity \
	    plymouth-theme-spinner \
	    plymouth-theme-text \
	    plymouth-theme-tribar \
            "

FILES_${PN} = "\
		/bin/* \
		/etc/* \
		/lib/* \
		/sbin/* \
		/var* \
		/usr/include/* \
		/usr/lib/* \
		/usr/sbin/* \
		/usr/share/plymouth/bizcom.png \
	      "

SUMMARY_plymouth-theme-details = ""
RDEPENDS_plymouth-theme-details = "${PN}"
FILES_plymouth-theme-details = "${datadir}/plymouth/themes/details"
pkg_postinst_plymouth-theme-details() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/details/details.plymouth
}

SUMMARY_plymouth-theme-fade-in = ""
RDEPENDS_plymouth-theme-fade-in = "${PN}"
FILES_plymouth-theme-fade-in = "${datadir}/plymouth/themes/fade-in/*"
pkg_postinst_plymouth-theme-fade-in() {
	if [ -n "$D" ]; then
		themes_dir="$D/usr/share/plymouth/themes"
		cp $themes_dir/fade-in/fade-in.plymouth $themes_dir/default.plymouth
	fi
}

SUMMARY_plymouth-theme-glow = ""
RDEPENDS_plymouth-theme-glow = "${PN}"
FILES_plymouth-theme-glow = "${datadir}/plymouth/themes/glow/*"
pkg_postinst_plymouth-theme-glow() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/glow/glow.plymouth
}

SUMMARY_plymouth-theme-script = ""
RDEPENDS_plymouth-theme-script = "${PN}"
FILES_plymouth-theme-script = "${datadir}/plymouth/themes/script/*"
pkg_postinst_plymouth-theme-script() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/script/script.plymouth
}

SUMMARY_plymouth-theme-solar = ""
RDEPENDS_plymouth-theme-solar = "${PN}"
FILES_plymouth-theme-solar = "${datadir}/plymouth/themes/solar/*"
pkg_postinst_plymouth-theme-solar() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/solar/solar.plymouth
}

SUMMARY_plymouth-theme-spinfinity = ""
RDEPENDS_plymouth-theme-spinfinity = "${PN}"
FILES_plymouth-theme-spinfinity = "${datadir}/plymouth/themes/spinfinity/*"
pkg_postinst_plymouth-theme-spinfinity() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/spinfinity/spinfinity.plymouth
}

SUMMARY_plymouth-theme-spinner = ""
RDEPENDS_plymouth-theme-spinner = "${PN}"
FILES_plymouth-theme-spinner = "${datadir}/plymouth/themes/spinner/*"
pkg_postinst_plymouth-theme-spinner() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/spinner/spinner.plymouth
}

SUMMARY_plymouth-theme-text = ""
RDEPENDS_plymouth-theme-text = "${PN}"
FILES_plymouth-theme-text = "${datadir}/plymouth/themes/text/*"
pkg_postinst_plymouth-theme-text() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/text/text.plymouth
}

SUMMARY_plymouth-theme-tribar = ""
RDEPENDS_plymouth-theme-tribar = "${PN}"
FILES_plymouth-theme-tribar = "${datadir}/plymouth/themes/tribar/*"
pkg_postinst_plymouth-theme-tribar() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/tribar/tribar.plymouth
}
