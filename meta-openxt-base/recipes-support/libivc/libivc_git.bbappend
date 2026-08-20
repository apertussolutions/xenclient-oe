# YP 6.0: SPDX license token, and CMake debug paths leak into the .so.
LICENSE = "GPL-2.0-only"
INSANE_SKIP:${PN} += "buildpaths"
INSANE_SKIP:${PN}-dbg += "buildpaths"
