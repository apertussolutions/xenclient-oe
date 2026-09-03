# Version knobs live in conf/distro/openxt-main.conf (OPENXT_XEN_*).
SRCREV = "${OPENXT_XEN_SRCREV}"
XEN_REL = "${OPENXT_XEN_REL}"
XEN_BRANCH = "${OPENXT_XEN_BRANCH}"
LIC_FILES_CHKSUM = "file://COPYING;md5=d1a1e216f80b6d8da95fec897d0dbec9"

# Reset meta-virt SRC_URI (xenbits + its patches). Feature work is on
# OPENXT_XEN_URI / OPENXT_XEN_BRANCH; xen-openxt.inc handles packaging.
SRC_URI = "${OPENXT_XEN_URI};branch=${XEN_BRANCH}"

require xen-common.inc
require xen-openxt.inc

DEFAULT_PREFERENCE = "1"
