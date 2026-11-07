# lastlog2's volatile entry chowns /var/lib/lastlog. That directory is on
# the read-only root, and pam_lastlog is not used. Remove the entry and the
# directory it was the only occupant of, or do_package reports the empty
# directory as installed but not shipped.
do_install:append() {
    rm -f ${D}${sysconfdir}/default/volatiles/99_lastlog2
    rmdir ${D}${sysconfdir}/default/volatiles 2>/dev/null || :
}
