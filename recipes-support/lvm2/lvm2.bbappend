FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += " \
    file://yocto-initscripts.patch \
    file://volatiles.99_cryptsetup \
"

# meta-oe recipe will already _append the autotools do_install(), and
# do_<something>_append() cannot be overridden...
# So instead, overwrite the files since this is a bbappend it should be done
# after the initial do_install:append()
do_install:append() {
    if ! ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        # Use Yocto compatible initscripts instead of the RHEL ones provided by
        # the tarball.
        oe_runmake 'DESTDIR=${D}' install_initscripts_yocto
        mv -f ${D}${sysconfdir}/rc.d/init.d/* ${D}${sysconfdir}/init.d/
        rm -rf ${D}${sysconfdir}/rc.d
    fi
    install -d ${D}${sysconfdir}/default/volatiles
    install -m 0644 ${UNPACKDIR}/volatiles.99_cryptsetup ${D}${sysconfdir}/default/volatiles/99_cryptsetup

    # 69-dm-lvm.rules runs vgchange through systemd-run when a PV appears.
    # Dom0 is sysvinit. The initramfs activates the VG with pvscan instead.
    rm -f ${D}${nonarch_base_libdir}/udev/rules.d/69-dm-lvm.rules
}

FILES:${PN}:remove = "${nonarch_base_libdir}/udev/rules.d/69-dm-lvm.rules"

PACKAGES =+ "${PN}-conf"
RRECOMMENDS:${PN}:append = " ${PN}-conf"

FILES:${PN}-conf = " \
    ${sysconfdir}/lvm/lvm.conf \
"
CONFFILES:${PN}-conf = " \
    ${sysconfdir}/lvm/lvm.conf \
"

FILES:${PN} += " \
    ${sysconfdir}/default/volatiles \
"
RDEPENDS:${PN} += " \
    bash \
"
