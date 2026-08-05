DESCRIPTION = "Dom0 display/UI integration packages"
LICENSE = "GPLv2 & MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6 \
                    file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

# Packages that couple dom0 to UIVM / glass / input UX.
RDEPENDS_${PN} = " \
    vglass \
    disman \
    uid \
    xenmgr-data \
    argo-input-receiver \
    linux-input \
    xenclient-splash-images \
    xenclient-boot-sound \
    alsa-utils-alsactl \
    alsa-utils-scripts \
    alsa-utils-alsamixer \
    read-edid \
    audio-helper \
    xenclient-language-sync \
"
