DESCRIPTION = "Application to fill pciback quirks"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=4641e94ec96f98fabc56ff9cc48be14b"
DEPENDS = "json-c pciutils"

PV = "0+git${SRCPV}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/patches:"
SRC_URI = "git://github.com/achartier/heimdallr.git;protocol=https;branch=master \
           file://pci-quirks.json \
           file://fix-json-pkgconfig-name.patch \
           file://json-0.13-interface-change.patch \
           "
SRCREV = "16b0da1e69e92ef8c0834e8a377c13aea823cfa2"


# Upstream Makefile sets FLAGS with -Werror and does CFLAGS += $(FLAGS).
# Pass an updated FLAGS via EXTRA_OEMAKE so -Wno-deprecated-declarations is
# present under -Werror; avoid CFLAGS:append glued onto a trailing -pipe.
EXTRA_OEMAKE = "FLAGS='-g -ggdb -std=c99 -pedantic -W -Wall -Wextra -Werror -Wno-deprecated-declarations'"

inherit pkgconfig

do_install() {
        oe_runmake DESTDIR="${D}/usr/bin" install

        install -d ${D}${sysconfdir}
        install -m 0644 ${UNPACKDIR}/pci-quirks.json ${D}${sysconfdir}
}
