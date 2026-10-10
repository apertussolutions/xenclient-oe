EXTRA_OECONF:append = " \
    --disable-Bsymbolic \
"

# glib-2.0-ptest RDEPENDS on locale-base-* packages from glibc-locale.
# Those are not DEPENDS of glib, so build-deps QA fails. oe-core already
# skips dev-deps for this package.
INSANE_SKIP:${PN}-ptest += "build-deps"
