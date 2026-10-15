FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}-${PV}:"

SRC_URI += " \
    file://openxt-menus.patch \
    file://disable-available-to-all-users-checkbox.patch \
    file://always-use-psk-hash.patch \
    file://disable-show-password.patch \
    file://disable-auto-ethernet.patch \
    file://meson-i18n-merge-file-kwargs.patch \
    file://org.openxt.nmapplet.xml \
"

do_configure:prepend() {
    gdbus-codegen --generate-c-code ${S}/src/popup-menu --c-namespace OpenXT --interface-prefix org.openxt. ${UNPACKDIR}/org.openxt.nmapplet.xml
    # gdbus-codegen emits an absolute #include, which fails the buildpaths QA check.
    sed -i 's,#include ".*/popup-menu.h",#include "popup-menu.h",' ${S}/src/popup-menu.c
}
