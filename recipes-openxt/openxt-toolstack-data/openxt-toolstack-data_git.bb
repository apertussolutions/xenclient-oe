DESCRIPTION = "OpenXT xenmgr data"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM="file://COPYING;md5=4641e94ec96f98fabc56ff9cc48be14b"
DEPENDS = "xenclient-rpcgen-native xenclient-idl nodejs-native"

PV = "0+git${SRCPV}"

SRCREV = "${AUTOREV}"
SRC_URI = "gitsm://${OPENXT_GIT_MIRROR}/toolstack-data.git;protocol=${OPENXT_GIT_PROTOCOL};branch=${OPENXT_BRANCH}"

S = "${WORKDIR}/git"
OUTPUT_DIR = "${S}/dist/script/services"
IDL_DIR = "${STAGING_DATADIR}/idl"

export IDL_DIR

inherit xenclient

do_configure() {
    IDLS="xenmgr.xml xenmgr_vm.xml xenmgr_host.xml vm_nic.xml vm_disk.xml \
        input_daemon.xml ctxusb_daemon.xml xenvm.xml surfman.xml \
        updatemgr.xml network.xml network_daemon.xml network_domain.xml xcpmd.xml"

    mkdir ${WORKDIR}/xc-rpc
    for i in ${IDLS}; do
        xc-rpcgen --javascript --client -o ${WORKDIR}/xc-rpc ${IDL_DIR}/$i
    done
}

do_compile() {
    cd ${S}
    node ${S}/src/dojo/dojo.js load=build --profile ${S}/profiles/xenclient --releaseDir ${S}/dist

    rm -rf ${S}/citrix/common/templates
    rm -rf ${S}/citrix/xenclient/templates

    # Remove unused themes
    rm -rf ${S}/dijit/themes/claro
    rm -rf ${S}/dijit/themes/nihilo
    rm -rf ${S}/dijit/themes/soria
}

do_install() {
    # site source
    install -d -m 755 ${D}/usr/lib/xui
    cp -dR --no-preserve=ownership ${S}/src/site/* ${D}/usr/lib/xui/.

    # xc api
    install -d -m 755 ${D}/usr/lib/xui/script/services
    cp -dR --no-preserve=ownership ${WORKDIR}/xc-rpc/* ${D}/usr/lib/xui/script/services/.

    # dojo
    install -d -m 755 ${D}/usr/lib/xui/lib
    for d in ${S}/dist/*/; do
        cp -dR --no-preserve=ownership ${d} ${D}/usr/lib/xui/lib/.
    done
}

FILES_${PN} = "/usr/lib/xui"
