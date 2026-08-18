# OE already packages ${PN}-bnx2 / ${PN}-bnx2x. Only extend iwlwifi-misc here.
FILES:${PN}-iwlwifi-misc += " \
    ${nonarch_base_libdir}/firmware/iwlwifi-*pnvm* \
"
