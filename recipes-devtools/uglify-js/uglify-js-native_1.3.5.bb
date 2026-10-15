SUMMARY = "UglifyJS 1.x JavaScript minifier"
HOMEPAGE = "https://github.com/mishoo/UglifyJS"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://README.org;beginline=565;endline=596;md5=c8144d5443475230ba93f062e17cbe87"

SRC_URI = "https://registry.npmjs.org/uglify-js/-/uglify-js-${PV}.tgz"
SRC_URI[sha256sum] = "df282243ed7839aead494e20c2289a14009dbcc79110f7087e5ff96475cadd8b"

S = "${UNPACKDIR}/package"

inherit native

do_configure() {
    :
}

do_compile() {
    :
}

do_install() {
    install -d ${D}${libdir}/node_modules/uglify-js/lib
    install -d ${D}${libdir}/node_modules/uglify-js/bin
    install -m 0644 ${S}/package.json ${S}/uglify-js.js \
        ${D}${libdir}/node_modules/uglify-js
    install -m 0644 ${S}/lib/*.js ${D}${libdir}/node_modules/uglify-js/lib
    install -m 0755 ${S}/bin/uglifyjs ${D}${libdir}/node_modules/uglify-js/bin
}
