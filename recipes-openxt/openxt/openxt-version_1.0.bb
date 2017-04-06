# Copyright (C) 2017 Daniel P. Smith <dpsmith@apertussolutions.com>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Generates version file"
LICENSE = "MIT"

SRC_URI = ""

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}
    cat > ${DEPLOYDIR}/version <<EOF
BUILDNAME="${BUILDNAME}"

BUILD="${XENCLIENT_BUILD}"
BUILD_DATE="${XENCLIENT_BUILD_DATE}"
BUILD_BRANCH="${XENCLIENT_BUILD_BRANCH}"
VERSION="${XENCLIENT_VERSION}"
RELEASE="${XENCLIENT_RELEASE}"
TOOLS="${XENCLIENT_TOOLS}"
UPGRADEABLE_RELEASES="${XENCLIENT_UPGRADEABLE_RELEASES}"
EOF

}
