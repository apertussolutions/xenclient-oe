# m4-ptest RDEPENDS locale packages from glibc-locale.
# Those are not DEPENDS of m4, so build-deps QA fails.
INSANE_SKIP:${PN}-ptest += "build-deps"
