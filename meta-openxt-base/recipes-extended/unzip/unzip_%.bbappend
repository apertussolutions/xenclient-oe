# unzip 6.0's unix/configure probes opendir without #include <dirent.h>.
# On 64-bit hosts with modern GCC, the probe "succeeds" to link with an
# implicit int-returning opendir, then fails at runtime → -DNO_DIR is set
# even though dirent is available (HAVE_DIRENT_H). That forces a broken
# private DIR implementation that collides with glibc headers.
#
# Drop -DNO_DIR after configure so the system dirent API is used.
do_compile() {
    oe_runmake -f unix/Makefile flags
    if [ -f flags ]; then
        sed -i 's/-DNO_DIR//g' flags
    fi
    # Same recipe as the "generic" target after flags generation.
    eval oe_runmake -f unix/Makefile unzips ACONF_DEP=flags `cat flags`
}
