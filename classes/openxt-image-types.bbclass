oxt_ext3 () {
    I0=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext3
    I=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.xc.ext3
    mv $I0 $I

    tune2fs -c -1 -i 0 $I
    e2fsck -f -y $I || true

    rm -f $I0
}

oxt_vhd () {
    I0=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.xc.ext3
    I=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.xc.ext3.vhd

    TGT_VHD_SIZE=`expr $ROOTFS_SIZE / 1024`
    if [ `expr $TGT_VHD_SIZE % 2` -eq 1 ]; then
        TGT_VHD_SIZE=`expr $TGT_VHD_SIZE + 1`
    else
        TGT_VHD_SIZE=`expr $TGT_VHD_SIZE + 2`
    fi

    vhd convert $I0 $I ${TGT_VHD_SIZE}

    rm -f $I0
}

IMAGE_TYPES += "raw xc.ext3 xc.ext3.vhd"

IMAGE_TYPEDEP_xc.ext3 = "ext3"
IMAGE_TYPEDEP_xc.ext3.vhd = "xc.ext3"

IMAGE_CMD_raw = "cp -a ${IMAGE_ROOTFS} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.raw"
IMAGE_CMD_xc.ext3 = "oxt_ext3"
IMAGE_CMD_xc.ext3.vhd = "oxt_vhd"

IMAGE_DEPENDS_xc.ext3 = "e2fsprogs-native"
IMAGE_DEPENDS_xc.ext3.vhd = "hs-vhd-native"
