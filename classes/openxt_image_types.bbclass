# raw image - simply copy rootfs tree to deploy directory
IMAGE_CMD:raw() {
    cp -a ${IMAGE_ROOTFS} ${IMGDEPLOYDIR}/${IMAGE_NAME}.raw
}

# OpenXT ext3 tweaks.
# - Disable fscheck.
# - Run fs check after generation.
# IMAGE_NAME already includes IMAGE_NAME_SUFFIX on YP 6.0.
oe_mkext234fs:append() {
    tune2fs -c -1 -i 0 ${IMGDEPLOYDIR}/${IMAGE_NAME}.$fstype
    e2fsck -f -y ${IMGDEPLOYDIR}/${IMAGE_NAME}.$fstype
}

# OpenXT vhd.
# Standard vhd image from an existing filesystem.
CONVERSIONTYPES:append = " vhd"
CONVERSION_CMD:vhd = "qemu-img convert -O vpc -o subformat=fixed ${IMAGE_NAME}.${type} ${IMAGE_NAME}.${type}.vhd"
CONVERSION_DEPENDS_vhd = "qemu-system-native"
