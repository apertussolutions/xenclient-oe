# raw image - simply copy rootfs tree to deploy directory
# IMAGE_NAME already includes IMAGE_NAME_SUFFIX via image-artifact-names.
IMAGE_CMD:raw() {
    cp -a ${IMAGE_ROOTFS} ${IMGDEPLOYDIR}/${IMAGE_NAME}.raw
}

# OpenXT ext3 tweaks.
# - Disable fscheck.
# - Run fs check after generation.
oe_mkext234fs:append() {
    tune2fs -c -1 -i 0 ${IMGDEPLOYDIR}/${IMAGE_NAME}.$fstype
    e2fsck -f -y ${IMGDEPLOYDIR}/${IMAGE_NAME}.$fstype
}

# vhd conversion is provided by OE image_types.bbclass (CONVERSION_CMD:vhd).
