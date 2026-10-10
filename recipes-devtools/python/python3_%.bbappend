# python3-ptest RDEPENDS on locale-base-tr-tr from glibc-locale, which is
# not a DEPENDS of python3. oe-core already skips dev-deps for this package.
INSANE_SKIP:${PN}-ptest += "build-deps"
