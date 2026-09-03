# OpenXT feature patch queue for a xenbits.xen.org tree.
# The default xen_git / xen-tools_git recipes fetch OPENXT_XEN_URI (the
# OpenXT xen fork) where these commits are already on the branch, so they
# must not require this file.
#
# To build from xenbits instead:
#   OPENXT_XEN_URI = "git://xenbits.xen.org/xen.git"
#   OPENXT_XEN_BRANCH = "stable-${OPENXT_XEN_REL}"
#   require xen-patches.inc
# (the queue still needs a refresh against 4.21.)

# XSA patches take precedence and belong at the head of the queue.
# This ensures that any collisions with other patches get addressed
# by modifying the OpenXT-specific patches, not the XSA patches.

SRC_URI:append = " \
    file://0001-python-pygrub-pass-DISTUTILS-xen.4.12.patch \
    file://kconfig-grant-table-v2-interface.patch \
    file://kconfig-grant-table-exotic.patch \
    file://hvm-pm-hibernate-s-state.patch;patch=1 \
    file://smbios.patch;patch=1 \
    file://evtchn-do-not-set-pending-if-s3.patch;patch=1 \
    file://hvm-rtc.patch;patch=1 \
    file://hvm-rtc-refresh-time.patch;patch=1 \
    file://acpi-pm-feature.patch \
    file://xenconsoled-syslog.patch;patch=1 \
    file://Dell-980-txt-shutdown-acpi-access-width.patch;patch=1 \
    file://parse-video-from-mbi.patch;patch=1 \
    file://opt-disable-vmcs-shadowing.patch;patch=1 \
    file://hvmloader-legacy-seabios-optionroms.patch;patch=1 \
    file://gpt-s3-resume-reason.patch;patch=1 \
    file://increase-ap-startup-time.patch;patch=1 \
    file://acpi-slic-support.patch \
    file://tboot-xen-evtlog-support.patch \
    file://libxl-syslog.patch \
    file://libxl-vif-cleanup.patch \
    file://libxl-vif-make-ioemu-and-stubdom-mac-addresses-configurable.patch \
    file://libxl-openxt-helpers.patch \
    file://libxl-openxt-tweaks.patch \
    file://libxl-domain-state.patch \
    file://libxl-fixup-cmdline-ops.patch \
    file://libxl-fix-reboot.patch \
    file://libxl-display-manager-support.patch \
    file://libxl-xenmgr-support.patch \
    file://libxl-no-PV-qemu.patch \
    file://libxl-hard-shutdown.patch \
    file://libxl-argo-xswait.patch \
    file://libxl-move-extra-qemu-args-to-the-end.patch \
    file://libxl-support-hvm-readonly-disks.patch \
    file://libxl-vwif-support.patch \
    file://libxl-atapi-pt.patch \
    file://libxl-avoid-creating-unusable-cdrom-vbd-xs-nodes.patch \
    file://libxl-allow-non-qdisk-cdrom.patch \
    file://libxl-fix-flr.patch \
    file://libxl-allow-save-vnuma.patch \
    file://libxl-block-scripts-log-to-syslog.patch \
    file://0001-convert-block-tap-for-shared.patch \
    file://domain-reboot.patch \
    file://efi-hardcode-openxt-cfg.patch \
    file://shim-support-for-shim-lock-measure.patch \
    file://efi-require-shim.patch \
    file://tboot-measure-and-launch-from-xen-efi.patch \
    file://argo-add-viptables.patch \
    file://argo-quiet-xsm-check-during-init.patch \
    file://libxl-seabios-ipxe.patch \
    file://memory-scrub-on-domain-shutdown.patch \
    file://ocamlfind-static.patch \
    file://ocaml-makefiles-sysroot.patch \
    file://patch-xen-disable-efi-gettime.patch \
    file://libxl-add-ovmf-varstored.patch \
    file://libxl-disable-dom0-qemu.patch \
    file://libxl-xen-disable-dom0-qemu.patch \
    file://libxl-add-xen-acpi-pm.patch \
    file://0001-vchan-socket-proxy-add-reconnect-marker-support.patch \
    file://0002-tools-libxl-enable-in-band-reconnect-marker-for-stub.patch \
"
