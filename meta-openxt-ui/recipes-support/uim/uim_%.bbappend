FILESEXTRAPATHS:prepend := "${THISDIR}/patches:"

# GTK toolbar branding is target-only; uim-native has no gtk2 sources built.
SRC_URI:append:class-target = " \
    file://openxt-branding.patch \
    file://disable-right-click-menu.patch \
    file://filter-input-methods.patch \
    file://hide-toolbar-from-env.patch \
"

CFLAGS:append = " -DOPENXT_BRANDING"

# This should not be necessary, yet autoconf will not set PKG_CONFIG
# automatically (it does for other projects...), which in turn will fail all
# PKG_CHECK_MODULES.
export PKG_CONFIG="pkg-config"
