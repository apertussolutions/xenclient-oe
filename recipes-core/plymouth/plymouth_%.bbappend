
# OE's recipe explicitly builds X11 support, we don't want that.
DEPENDS = "libcap libpng cairo udev"

# Override RDEPENDS to strip dracut
RDEPENDS_${PN}-initrd = "bash"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://70-seat.rules \
	file://plymouth.init \
	"

inherit update-rc.d

do_install_append() {
	install -d ${D}/lib/udev/rules.d
	install -m 0644 ${WORKDIR}/70-seat.rules ${D}/lib/udev/rules.d/70-seat.rules

	install -d ${D}/${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/plymouth.init ${D}/${sysconfdir}/init.d/plymouth

	rm ${D}/usr/share/plymouth/plymouthd.defaults
}

INITSCRIPT_PACKAGES = "${PN}-initscript"
INITSCRIPT_NAME = "${PN}"
# Surfman is 72 in runlevel 5, run start just before to exit plymouth
INITSCRIPT_PARAMS = "start 71 5 . stop 71 0 1 2 3 4 6 ."

PACKAGES += " \
	    ${PN}-initscript \
	    ${PN}-theme-details \
	    ${PN}-theme-fade-in \
	    ${PN}-theme-glow \
	    ${PN}-theme-script \
	    ${PN}-theme-solar \
	    ${PN}-theme-spinfinity \
	    ${PN}-theme-spinner \
	    ${PN}-theme-text \
	    ${PN}-theme-tribar \
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

SUMMARY_${PN}-initscript = ""
RDEPENDS_${PN}-initscript = "${PN}"
FILES_${PN}-initscript = "${datadir}/plymouth/themes/details"

SUMMARY_${PN}-theme-details = ""
RDEPENDS_${PN}-theme-details = "${PN}"
FILES_${PN}-theme-details = "${datadir}/plymouth/themes/details"
pkg_postinst_plymouth-theme-details() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/details/details.plymouth
}

SUMMARY_${PN}-theme-fade-in = ""
RDEPENDS_${PN}-theme-fade-in = "${PN}"
FILES_${PN}-theme-fade-in = "${datadir}/plymouth/themes/fade-in/*"
pkg_postinst_plymouth-theme-fade-in() {
	if [ -n "$D" ]; then
		themes_dir="$D/usr/share/plymouth/themes"
		cp $themes_dir/fade-in/fade-in.plymouth $themes_dir/default.plymouth
	fi
}

SUMMARY_${PN}-theme-glow = ""
RDEPENDS_${PN}-theme-glow = "${PN}"
FILES_${PN}-theme-glow = "${datadir}/plymouth/themes/glow/*"
pkg_postinst_plymouth-theme-glow() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/glow/glow.plymouth
}

SUMMARY_${PN}-theme-script = ""
RDEPENDS_${PN}-theme-script = "${PN}"
FILES_${PN}-theme-script = "${datadir}/plymouth/themes/script/*"
pkg_postinst_plymouth-theme-script() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/script/script.plymouth
}

SUMMARY_${PN}-theme-solar = ""
RDEPENDS_${PN}-theme-solar = "${PN}"
FILES_${PN}-theme-solar = "${datadir}/plymouth/themes/solar/*"
pkg_postinst_plymouth-theme-solar() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/solar/solar.plymouth
}

SUMMARY_${PN}-theme-spinfinity = ""
RDEPENDS_${PN}-theme-spinfinity = "${PN}"
FILES_${PN}-theme-spinfinity = "${datadir}/plymouth/themes/spinfinity/*"
pkg_postinst_plymouth-theme-spinfinity() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/spinfinity/spinfinity.plymouth
}

SUMMARY_${PN}-theme-spinner = ""
RDEPENDS_${PN}-theme-spinner = "${PN}"
FILES_${PN}-theme-spinner = "${datadir}/plymouth/themes/spinner/*"
pkg_postinst_plymouth-theme-spinner() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/spinner/spinner.plymouth
}

SUMMARY_${PN}-theme-text = ""
RDEPENDS_${PN}-theme-text = "${PN}"
FILES_${PN}-theme-text = "${datadir}/plymouth/themes/text/*"
pkg_postinst_plymouth-theme-text() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/text/text.plymouth
}

SUMMARY_${PN}-theme-tribar = ""
RDEPENDS_${PN}-theme-tribar = "${PN}"
FILES_${PN}-theme-tribar = "${datadir}/plymouth/themes/tribar/*"
pkg_postinst_plymouth-theme-tribar() {
#!/bin/sh

ln -rs $D/usr/share/plymouth/plymouthd.defaults themes/tribar/tribar.plymouth
}
