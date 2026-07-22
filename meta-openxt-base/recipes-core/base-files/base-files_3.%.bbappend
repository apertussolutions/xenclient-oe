FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += " \
    file://fstab.early \
    file://openxt-aliases.sh \
"
dirs1777 = " \
    /tmp \
    ${localstatedir}/lock \
    ${localstatedir}/tmp \
"
dirs2775 = " \
    /home \
    ${prefix}/src \
    ${localstatedir}/local \
"
dirs755_append = " \
    ${localstatedir}/log \
    /media/ram \
"
dirs755_remove = " \
    ${localstatedir}/volatile/log \
    ${localstatedir}/volatile/tmp \
"

dirs755_append_xenclient-dom0 = " \
    /storage \
    ${localstatedir}/cores \
"

volatiles = ""
conffiles = " \
    ${sysconfdir}/host.conf \
    ${sysconfdir}/issue \
    ${sysconfdir}/issue.net \
    ${sysconfdir}/profile \
    ${sysconfdir}/default \
"

do_install_append() {
    install -m 0644 ${WORKDIR}/fstab.early ${D}${sysconfdir}/fstab.early
    install -m 0755 -d ${D}${sysconfdir}/profile.d
    install -m 0644 ${WORKDIR}/openxt-aliases.sh ${D}${sysconfdir}/profile.d/openxt-aliases.sh
}
