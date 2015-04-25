SUMMARY = "A /dev/crypto device driver"
HOMEPAGE = "http://cryptodev-linux.org/"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "http://download.gna.org/cryptodev-linux/${BPN}-${PV}.tar.gz"

SRC_URI[md5sum] = "eade38998313c25fd7934719cdf8a2ea"
SRC_URI[sha256sum] = "75f1425c8ea1f8cae523905a5a046a35092327a6152800b0b86efc4e56fb3e2f"

do_compile() {
	:
}

# Just install cryptodev.h which is the only header file needed to be exported
do_install() {
	install -D ${S}/crypto/cryptodev.h ${D}${includedir}/crypto/cryptodev.h
}

ALLOW_EMPTY_${PN} = "1"
BBCLASSEXTEND = "native nativesdk"