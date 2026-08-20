# OpenXT initscript / xenstored packaging for meta-virt xen-tools 4.21+stable.
# Do not require xen-tools-openxt.inc wholesale: it re-adds PACKAGES that
# meta-virt 4.21 already defines (libxenhypfs, xenhypfs, ...).

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = "\
    file://xenconsoled.initscript \
    file://xenstored.initscript \
    file://xen-init-dom0.initscript \
    file://xl.conf \
    file://0001-vchan-socket-proxy-add-reconnect-marker-support.patch \
"

PROVIDES =+ "virtual/xenstored"
RPROVIDES:${PN}-xenstored = "virtual-xenstored"

# meta-virt packages the binary as xen-tools-vchan; OpenXT recipes
# RDEPEND on the historical package name vchan-socket-proxy.
RPROVIDES:${PN}-vchan += "vchan-socket-proxy"

# OpenXT uses init scripts rather than systemd; rename xenstored for alternatives.
FILES:${PN}-console += "${INIT_D_DIR}/xenconsoled"
FILES:${PN}-xenstored = " \
    ${sbindir}/xenstored.${PN}-xenstored \
    ${localstatedir}/lib/xenstored \
    ${INIT_D_DIR}/xenstored.${PN}-xenstored \
    ${sysconfdir}/xen/xenstored.conf \
"
FILES:${PN}-xl += " ${INIT_D_DIR}/xen-init-dom0"

INITSCRIPT_PACKAGES =+ " \
    ${PN}-console \
    ${PN}-xenstored \
    ${PN}-xl \
"
INITSCRIPT_NAME:${PN}-console = "xenconsoled"
INITSCRIPT_PARAMS:${PN}-console = "defaults 20 80"
INITSCRIPT_NAME:${PN}-xenstored = "xenstored"
INITSCRIPT_PARAMS:${PN}-xenstored = "defaults 05 95"
INITSCRIPT_NAME:${PN}-xl = "xen-init-dom0"
INITSCRIPT_PARAMS:${PN}-xl = "defaults 21 79"

pkg_postinst:${PN}-xenstored () {
    update-alternatives --install ${sbindir}/xenstored xenstored xenstored.${PN}-xenstored 200
    update-alternatives --install ${INIT_D_DIR}/xenstored xenstored-initscript xenstored.${PN}-xenstored 200
}
pkg_prerm:${PN}-xenstored () {
    update-alternatives --remove xenstored xenstored.${PN}-xenstored
    update-alternatives --remove xenstored-initscript xenstored.${PN}-xenstored
}

do_install:append() {
    install -d ${D}${INIT_D_DIR}
    install -m 0755 ${UNPACKDIR}/xenconsoled.initscript \
                    ${D}${INIT_D_DIR}/xenconsoled
    install -m 0755 ${UNPACKDIR}/xen-init-dom0.initscript \
                    ${D}${INIT_D_DIR}/xen-init-dom0

    install -d ${D}${sysconfdir}/xen
    install -m 0644 ${UNPACKDIR}/xl.conf \
                    ${D}${sysconfdir}/xen/xl.conf

    if [ -e ${D}${sbindir}/xenstored ]; then
        mv ${D}${sbindir}/xenstored ${D}${sbindir}/xenstored.${PN}-xenstored
    fi
    install -m 0755 ${UNPACKDIR}/xenstored.initscript \
                    ${D}${INIT_D_DIR}/xenstored.${PN}-xenstored
    # The C xenstored uses one additional command line argument:
    sed 's/EXECUTABLE --/EXECUTABLE --internal-db --/' \
        -i ${D}${INIT_D_DIR}/xenstored.${PN}-xenstored

    rm -f ${D}/${libdir}/xen/bin/init-xenstore-domain
    rm -rf ${D}/${INIT_D_DIR}/xencommons
    rm -rf ${D}/${INIT_D_DIR}/xendriverdomain
    rm -rf ${D}/${sysconfdir}/xen/scripts/colo-proxy-setup
    rm -rf ${D}/${sysconfdir}/xen/scripts/launch-xenstore
    rm -rf ${D}/${sysconfdir}/xen/scripts/block-dummy
    rm -rf ${D}/${sysconfdir}/default/xencommons
}
