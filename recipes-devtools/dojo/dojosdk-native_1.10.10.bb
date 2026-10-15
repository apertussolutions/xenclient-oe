LICENSE = "BSD-3-Clause & AFL-2.0"
LIC_FILES_CHKSUM = "file://dojo-release-${PV}-src/dijit/LICENSE;md5=420b6319a08678ab5d97203953210ad3 \
                    file://dojo-release-${PV}-src/dojo/LICENSE;md5=1087ff878a91292e89baa31313792005 \
                    file://dojo-release-${PV}-src/dojox/LICENSE;md5=420b6319a08678ab5d97203953210ad3 \
                    file://dojo-release-${PV}-src/util/LICENSE;md5=1087ff878a91292e89baa31313792005"

SRC_URI[sha256sum] = "c231f39e8243e05e8d279aeff3ca9b2d0539310bf4ffa7bb13c2f98ddd3d26e3"
require recipes-devtools/dojo/dojosdk-native.inc

DEPENDS = "nodejs-native uglify-js-native"

do_install:append() {
    cat << EOF > ${D}${bindir}/dojo-${PV}
#!/bin/sh
export DOJOHOME="@DOJOHOME@"
export NODE_PATH="@NODE_MODULES@\${NODE_PATH:+:\$NODE_PATH}"
exec "\$DOJOHOME/util/buildscripts/build.sh" "\$@"
EOF
    chmod 0755 ${D}${bindir}/dojo-${PV}
}

sysroot_fix_dojo_node_path() {
    sed -i -e "s#@NODE_MODULES@#${libdir}/node_modules#g" \
        "${SYSROOT_DESTDIR}${bindir}/dojo-${PV}"
}

SYSROOT_PREPROCESS_FUNCS += "sysroot_fix_dojo_node_path"
