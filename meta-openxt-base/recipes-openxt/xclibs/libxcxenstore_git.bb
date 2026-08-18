DESCRIPTION = "Xenstore library"
LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://../COPYING;md5=321bf41f280cf805086dd5a720b37785"
DEPENDS = "xen-tools libxclogging libevent"

require xclibs.inc

S = "${UNPACKDIR}/${BP}/xcxenstore"

ASNEEDED = ""

inherit autotools-brokensep pkgconfig

# sample/teststore.c fails under GCC 15 -Werror=implicit-function-declaration
# (missing unistd.h / lib headers) and is not installed — skip it.
EXTRA_OEMAKE += "SUBDIRS=src"
