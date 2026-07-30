# Use the rebased OpenXT Xen tree (openxt-4.21) instead of xenbits + patchqueue.
XEN_REL = "4.21"
XEN_BRANCH = "openxt-4.21"
SRCREV = "d61d766c6e02d7ec866d29a7affb366c02b91a83"
LIC_FILES_CHKSUM = "file://COPYING;md5=d1a1e216f80b6d8da95fec897d0dbec9"

# Reset meta-virtualization SRC_URI (and its dunfell-era patches).
SRC_URI = "git://github.com/apertussolutions/openxt-xen.git;protocol=https;branch=${XEN_BRANCH}"

require xen-common.inc
require xen-tools-openxt.inc

# Workaround for setuptools3 overriding autotools-brokensep
B = "${S}"

DEFAULT_PREFERENCE = "1"

PACKAGES += "vchan-socket-proxy"
FILES_vchan-socket-proxy = " \
    ${bindir}/vchan-socket-proxy \
"
RDEPENDS_${PN}-libxenlight += "vchan-socket-proxy"
