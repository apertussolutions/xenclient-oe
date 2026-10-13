# bash-ptest RDEPENDS on locale-base packages from glibc-locale.
# Those are not DEPENDS of bash, so build-deps QA fails.
INSANE_SKIP:${PN}-ptest += "build-deps"
