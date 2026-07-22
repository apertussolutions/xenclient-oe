DESCRIPTION = "Core (headless) packages for OpenXT/XenClient dom0"
LICENSE = "GPLv2 & MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6      \
                    file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

# Control-plane only. Display/UI packages live in
# packagegroup-openxt-dom0-display (later meta-openxt-ui).
RDEPENDS_${PN} = " \
    openssh \
    openssh-sshd-tcp-init \
    util-linux-mount \
    util-linux-umount \
    xen-tools-console \
    xen-tools-hvmloader \
    xen \
    xen-efi \
    xen-tools-flask-tools \
    xen-tools-libxenguest \
    xen-tools-libxenlight \
    xen-tools-libxenstat \
    xen-tools-libxlutil \
    xen-tools-xenstat \
    virtual/xenstored \
    xen-tools-xl \
    xen-xsm-policy \
    grub \
    shim \
    tboot \
    tboot-utils \
    e2fsprogs-tune2fs \
    e2fsprogs-resize2fs \
    kernel-modules \
    libargo-bin \
    lvm2 \
    bridge-utils \
    iptables \
    iproute2 \
    qemu-dm \
    seabios \
    ovmf-firmware \
    xcpmd \
    xenclient-dom0-tweaks \
    xenclient-config-access \
    xenclient-cryptdisks \
    cryptsetup \
    xenclient-get-config-key \
    xenclient-root-ro \
    curl \
    trousers \
    trousers-data \
    tpm-tools \
    tpm-tools-sa \
    xenclient-tpm-setup \
    pciutils-ids \
    acms \
    openssl \
    ntpdate \
    dd-buffered \
    vhd-scripts \
    secure-vm \
    xenclient-sec-scripts \
    pmtools \
    svirt-interpose \
    selinux-load \
    ethtool \
    intel-microcode \
    rsyslog \
    rsyslog-conf-dom0 \
    logrotate \
    dialog \
    xenclient-nwd \
    wget \
    xenclient-repo-certs \
    usb-modeswitch \
    upgrade-db \
    rpc-proxy \
    dbd \
    atapi-pt-helper \
    qmp-helper \
    compleat \
    xec \
    dmidecode \
    netcat \
    libicbinn-server \
    screen \
    xenclient-pcrdiff \
    eject \
    iputils-ping \
    vusb-daemon \
    updatemgr \
    xenmgr \
    xen-tools-xenstore \
    tpm2-tss \
    tpm2-tools \
    blktap3 \
    pesign \
    ipxe \
    udev-extraconf-dom0 \
"

RPROVIDES_${PN} += "packagegroup-openxt-dom0-core"
