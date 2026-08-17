DESCRIPTION = "scripts to aid in the configuration and maintenance of the TPM"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
    file://tpm-functions \
    file://dellminvers-detect.sh \
    file://montavina-detect.sh \
    file://pcr1-detect.sh \
    file://pcr1-fix.sh \
"

RDEPENDS:${PN} = " \
    tpm-tools \
    tpm2-tools \
"

FILES:${PN} = "${libdir}/tpm-scripts"

do_install() {
    install -d ${D}${libdir}/tpm-scripts
    install -m 0755 ${WORKDIR}/tpm-functions ${D}${libdir}/tpm-scripts
    install -d ${D}${libdir}/tpm-scripts/quirks.d
    for detect in ${WORKDIR}/*-detect.sh; do
        [ -e "${detect}" ] || continue
        install -m 0755 ${detect} ${D}${libdir}/tpm-scripts/quirks.d
    done
    for fix in ${WORKDIR}/*-fix.sh; do
        [ -e "${fix}" ] || continue
        install -m 0755 ${fix} ${D}${libdir}/tpm-scripts/quirks.d
    done
}
