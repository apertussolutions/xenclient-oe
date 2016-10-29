# Copyright (C) 2015 Unknown User <unknown@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "A tool to examine and manipulate VHD images"
HOMEPAGE = "https://github.com/andreiw/vhdtool"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "util-linux"

SRC_URI = "git://github.com/andreiw/vhdtool.git;branch=master \
          "

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

LDFLAGS_append = " -luuid"

do_install () {
    install -d ${D}/${bindir}
    install -m 0755 vhdtool ${D}/${bindir}
}

SRC_URI[md5sum] = "bde04de0b3d1c93ebd7c168e6e7b5994"
SRC_URI[sha256sum] = "c9a23c4523af1da329e7daef3ca3b6b4e1b0f74d2f19d65523baeb082c748c19"

BBCLASSEXTEND = "native"
