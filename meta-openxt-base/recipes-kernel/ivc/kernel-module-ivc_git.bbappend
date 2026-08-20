FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-linux-5.14-bind-interdomain-evtchn-without-xenbus.patch"

# YP 6.0 rejects the obsolete GPLv2 token.
LICENSE = "GPL-2.0-only"

inherit module-signing
