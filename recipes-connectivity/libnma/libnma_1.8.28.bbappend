FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}-${PV}:"

# Wrynose OE-core ships gcr 4 (gcr-4.pc). libnma 1.8.28 wants gcr-3.
PACKAGECONFIG:remove = "gcr"

# NetworkManager 1.22 is built without gobject-introspection (no NM-1.0.gir).
EXTRA_OEMESON += "-Dintrospection=false -Dvapi=false"

SRC_URI += " \
    file://default-certs-dir.patch \
"
