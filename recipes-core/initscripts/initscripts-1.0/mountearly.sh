#
# mountearly.sh
# Mount early tmpfs required for early daemon (udevd,...).
#

. /etc/default/rcS
. /etc/init.d/functions

# Can be defined in /etc/default/mountearly?
if [ -f /etc/default/mountearly ]; then
    . /etc/default/mountearly
fi
# Environment.
EARLY_FSTAB="${EARLY_FSTAB:-/etc/fstab.early}"

begin "Mounting early filesystems..."
if [ ! -e "${EARLY_FSTAB}" ]; then
    success "No early filesystems to mount (${EARLY_FSTAB})."
    exit 0
fi

# The kernel mounts devtmpfs on /dev before init, which hides any
# /dev/pts directory shipped in the rootfs. bootlogd starts before
# mountall.sh, so create the mount point here.
mkdir -p /dev/pts

# With busybox, requires: CONFIG_FEATURE_MOUNT_OTHERTAB
if ! mount -a -T "${EARLY_FSTAB}" ; then
    failure "Failed to mount early filesystems."
    exit 1
fi

success "Early filesystems ready."
