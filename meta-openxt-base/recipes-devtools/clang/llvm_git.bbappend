# Host g++ builds TLS objects without -fPIC by default; linking them into
# libLLVM.so then fails (R_X86_64_TPOFF32). Force PIC for native dylibs.
EXTRA_OECMAKE:append:class-native = " -DCMAKE_POSITION_INDEPENDENT_CODE=ON"
