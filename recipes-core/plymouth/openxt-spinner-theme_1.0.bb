LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit allarch

DEPENDS = "plymouth"

SRC_URI := " \
	file://animation-0001.png \
	file://animation-0002.png \
	file://animation-0003.png \
	file://animation-0004.png \
	file://animation-0005.png \
	file://animation-0006.png \
	file://animation-0007.png \
	file://animation-0008.png \
	file://animation-0009.png \
	file://animation-0010.png \
	file://animation-0011.png \
	file://animation-0012.png \
	file://animation-0013.png \
	file://animation-0014.png \
	file://animation-0015.png \
	file://animation-0016.png \
	file://animation-0017.png \
	file://animation-0018.png \
	file://animation-0019.png \
	file://animation-0020.png \
	file://animation-0021.png \
	file://animation-0022.png \
	file://animation-0023.png \
	file://animation-0024.png \
	file://animation-0025.png \
	file://animation-0026.png \
	file://animation-0027.png \
	file://animation-0028.png \
	file://animation-0029.png \
	file://animation-0030.png \
	file://animation-0031.png \
	file://animation-0032.png \
	file://animation-0033.png \
	file://animation-0034.png \
	file://animation-0035.png \
	file://animation-0036.png \
	file://box.png \
	file://bullet.png \
	file://entry.png \
	file://lock.png \
	file://openxt-spinner.plymouth \
	file://throbber-0001.png \
	file://throbber-0002.png \
	file://throbber-0003.png \
	file://throbber-0004.png \
	file://throbber-0005.png \
	file://throbber-0006.png \
	file://throbber-0007.png \
	file://throbber-0008.png \
	file://throbber-0009.png \
	file://throbber-0010.png \
	file://throbber-0011.png \
	file://throbber-0012.png \
	file://watermark.png \
"

S := "${WORKDIR}"

do_install() {
	install -d ${D}${datadir}/plymouth/themes/openxt-spinner

	install -m 0644 ${S}/*.png ${D}${datadir}/plymouth/themes/openxt-spinner
	install -m 0644 ${S}/openxt-spinner.plymouth ${D}${datadir}/plymouth/themes/openxt-spinner
}

FILES_${PN} := "${datadir}/plymouth/themes/*"

pkg_postinst_${PN}() {
#!/bin/sh

cat >$D/etc/plymouth/plymouthd.conf <<EOF
[Daemon]
Theme=openxt-spinner
EOF
}
