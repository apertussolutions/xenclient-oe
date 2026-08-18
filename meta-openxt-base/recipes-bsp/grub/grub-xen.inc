# Hack to work around grub2.inc settings SRC_URI.
# Locate openembedded-core for FILESEXTRAPATHS. Try, in order:
#   1) TOPDIR/../../layers/oe-core  (openxt project: builds/<instance>)
#   2) TOPDIR/../layers/oe-core     (layer-build: build-base next to layers)
#   3) TOPDIR/layers/oe-core        (bordel-style)
OE_CORE_PATH ?= "${@ \
    (lambda t: \
        next((p for p in ( \
            t + '/../../layers-wrynose/openembedded-core', \
            t + '/../../layers/openembedded-core', \
            t + '/../layers/openembedded-core', \
            t + '/layers/openembedded-core', \
        ) if __import__('os').path.isdir(p)), \
        t + '/../layers/openembedded-core'))(d.getVar('TOPDIR'))}"
FILESEXTRAPATHS:prepend := "${OE_CORE_PATH}/meta/recipes-bsp/grub/files:"
require recipes-bsp/grub/grub2.inc

# OpenXT still builds PVH/PV grub from 2.04; OE-Core grub2.inc checksum
# tracks the distro grub PV (2.14 on wrynose). Override for this recipe.
SRC_URI[sha256sum] = "f10c85ae3e204dbaec39ae22fa3c5e99f0665417e91c2cb49b7e5031658ba6ea"

require conf/image-uefi.conf

# Need to be disabled otherwise there are wint_t type not defined errors
SECURITY_CFLAGS = ""

# Prevent generation of .text.unlikely which would be placed ahead of the
# expected _start at the beginning of the .text section.  .text.unlikely
# would then get executed and fault.
CFLAGS:append = " -fno-reorder-functions"

DEPENDS:append:class-target = " grub-efi-native"
RDEPENDS:${PN}:class-target = "grub-common virtual-grub-bootconf"

SRC_URI += " \
	file://grub-xen.cfg \
"

S = "${UNPACKDIR}/grub-${PV}"

CACHED_CONFIGUREVARS += "ac_cv_path_HELP2MAN="
EXTRA_OECONF += "--enable-efiemu=no"

GRUBPLATFORM ?= "xen"
GRUB_TARGET ?= "x86_64"
GRUBEXT ?= "${GRUBPLATFORM}-pvh"
GRUB_BINARY = "grub-${GRUBEXT}"

PACKAGECONFIG = "device-mapper"

GRUB_BUILDIN ?= "linux ext2 fat part_msdos part_gpt normal \
                 iso9660 configfile search loadenv test \
                 echo legacycfg memdisk tar gzio"

do_mkimage() {
	cd ${B}
	# The early.cfg is limited, so it loads a full config from memdisk
	echo "normal (memdisk)/grub-xen.cfg" > grub-bootstrap.cfg
	# The memdisk config searches for a grub.cfg on the local boot media,
	# or falls back to loading bzImage
	tar -c -C ${WORKDIR} -f ${B}/memdisk.tar grub-xen.cfg
	tar tf memdisk.tar
	grub-mkimage -c grub-bootstrap.cfg -p / -d ./grub-core/ \
	               -O ${GRUB_TARGET}-${GRUBPLATFORM} \
	               -o ./${GRUB_BINARY} \
	               -m memdisk.tar \
	               ${GRUB_BUILDIN}
}

addtask mkimage before do_install after do_compile

do_mkimage:class-native() {
	:
}

do_install:class-target() {
    install -d "${D}${libdir}/xen/boot"
    install -m 644 "${GRUB_BINARY}" "${D}${libdir}/xen/boot"
    ln -s "${GRUB_BINARY}" "${D}${libdir}/xen/boot/${GRUB_BINARY}.bin"
}

FILES:${PN} = "${libdir}/xen/boot"

# grub.xen_pvh is a 32bit binary, so it may not match.
INSANE_SKIP:${PN} += "arch"
