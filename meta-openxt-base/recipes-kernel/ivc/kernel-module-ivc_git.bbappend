FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-linux-5.14-bind-interdomain-evtchn-without-xenbus.patch"

inherit module-signing
