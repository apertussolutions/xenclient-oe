DESCRIPTION = "Packages for the OpenXT Network Domain (NDVM)"
LICENSE = "GPLv2 & MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6 \
                    file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

RDEPENDS_${PN} = " \
    util-linux-mount \
    util-linux-umount \
    openssh \
    kernel-modules \
    libargo \
    libargo-bin \
    dbus \
    xenclient-dbusbouncer \
    linux-firmware-iwlwifi \
    linux-firmware-bnx2 \
    xenclient-ndvm-tweaks \
    rsyslog \
    argo-module \
    xen-tools-libxenstore \
    xen-tools-xenstore \
    wget \
    ethtool \
    xenclient-nws \
    modemmanager \
    ppp \
    iputils-ping \
    dbd-tools-vm \
    xen-vif-scripts-ndvm \
    grub-xen-conf \
"
