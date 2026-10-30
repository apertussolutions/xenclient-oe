LICENSE = "BSD-3-Clause & AFL-2.0"
LIC_FILES_CHKSUM = "file://dojo-release-${PV}-src/dijit/LICENSE;md5=420b6319a08678ab5d97203953210ad3    \
                    file://dojo-release-${PV}-src/dojo/LICENSE;md5=420b6319a08678ab5d97203953210ad3     \
                    file://dojo-release-${PV}-src/dojox/LICENSE;md5=420b6319a08678ab5d97203953210ad3    \
                    file://dojo-release-${PV}-src/util/LICENSE;md5=420b6319a08678ab5d97203953210ad3"

SRC_URI[md5sum] = "d070b0809f4ceeebc4fac340dea6a729"
SRC_URI[sha256sum] = "6bd043a07534464c7dc8eb1f5fd2e65e869f058c7461ccc1a30871ac38c8cc6f"

FILESEXTRAPATHS:prepend := "${THISDIR}/dojosdk-native-${PV}:"

require recipes-devtools/dojo/dojosdk-native.inc

SRC_URI += "file://use-java-native-copy-rather-than-forking.patch"

# icedtea7-native 2.1.3 does not compile with GCC 15. Dojo only needs a
# JVM to run Rhino, so the wrapper uses the host java.
DEPENDS:remove = "icedtea7-native"

do_install:append() {
    cat << EOF > ${D}${bindir}/dojo-${PV}
#!/bin/sh
export PATH="/usr/bin:\${PATH}"
# Rhino calls FileChannel.transferFrom. Java 21 hides sun.nio.ch.
export JAVA_TOOL_OPTIONS="\${JAVA_TOOL_OPTIONS:+\$JAVA_TOOL_OPTIONS }--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
@DOJOHOME@/util/buildscripts/build.sh "\$@"
EOF
    chmod 0755 ${D}${bindir}/dojo-${PV}
}
