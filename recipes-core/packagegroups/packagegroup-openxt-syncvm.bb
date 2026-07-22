DESCRIPTION = "Packages for the OpenXT Synchronizer Domain (SyncVM)"
LICENSE = "GPLv2 & MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6 \
                    file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

RDEPENDS_${PN} = " \
    kernel-modules \
    argo-module \
    libargo \
    libargo-bin \
    rsyslog \
    openssh \
    wget \
    sync-client \
    xenclient-syncvm-tweaks \
    blktap3 \
    grub-xen-conf \
"
