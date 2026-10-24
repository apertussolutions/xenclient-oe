FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://vglass-monit-stop"

# An unsupported GPU makes glass exit. Stop monit from restarting it
# for the rest of the boot.
do_install:append() {
    install -d ${D}${sysconfdir}/monit.d
    install -m 0644 ${UNPACKDIR}/vglass-monit-stop ${D}${sysconfdir}/monit.d/vglass
}
