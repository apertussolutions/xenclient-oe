FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit module-signing

SRC_URI += "file://0001-linux-6.18-openxtfb.patch"

KERNEL_MODULE_AUTOLOAD:append:xenclient-uivm += "openxtfb"
