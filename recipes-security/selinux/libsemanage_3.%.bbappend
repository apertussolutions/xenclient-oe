# linux-openxt 6.1 POLICYDB_VERSION_MAX is 33. meta-selinux writes
# policy-version = 35 into the on-target semanage.conf; a later semodule
# rebuild would install a binary this kernel will not load.
do_install:append() {
    if [ -f ${D}${sysconfdir}/selinux/semanage.conf ]; then
        sed -i 's/^policy-version[[:space:]]*=.*/policy-version = 33/' \
            ${D}${sysconfdir}/selinux/semanage.conf
    fi
}
