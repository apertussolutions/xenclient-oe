# Apply OpenXT packaging (xenstored/xenconsoled/xen-init-dom0 initscripts and
# alternatives) to meta-virtualization's xen-tools 4.21+stable recipe.
# xen-tools_git.bbappend cannot apply here; its full OpenXT patch queue still
# needs refresh against current xen tip.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
require xen-tools-openxt.inc
