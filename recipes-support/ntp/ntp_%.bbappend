FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://volatiles"

do_install:append() {
    install -d ${D}${sysconfdir}/default/volatiles
    install -m 0644 ${UNPACKDIR}/volatiles ${D}${sysconfdir}/default/volatiles/99_ntp
}

FILES:${PN} += "${sysconfdir}/default/volatiles/99_ntp"
