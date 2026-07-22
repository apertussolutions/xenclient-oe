FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://volatiles \
"

do_install_append() {
    install -d -m 700 ${D}${sysconfdir}/default/volatiles
    install -m 600 ${WORKDIR}/volatiles \
        ${D}${sysconfdir}/default/volatiles/50_monit
}
