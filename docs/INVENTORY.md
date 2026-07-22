# OpenXT layer inventory (post multi-PR split)

Date: 2026-07-22T21:11:59Z
Branch: layer-split/pr-stack
Tip: 837d1eb343c1777210d658315922a7b15b050b23
Base: 746006febd453d621750d11360a9445484c6f104
Tag: pre-layer-split

Note: bitbake dependency graphs skipped (no OE build environment).

## meta-openxt-base
- bb: 116
- bbappend: 46
- machines: openxt-installer.conf xenclient-common.conf xenclient-dom0.conf xenclient-stubdomain.conf 
- images: xenclient-dom0-image.bb xenclient-initramfs-image.bb xenclient-installer-image.bb xenclient-stubdomain-initramfs-image.bb xenclient-version.inc 

## meta-openxt-domains
- bb: 13
- bbappend: 2
- machines: usbvm.conf xenclient-ndvm.conf xenclient-syncvm.conf 
- images: usbvm-image.bb xenclient-ndvm-image.bb xenclient-syncvm-image.bb 

## meta-openxt-ui
- bb: 21
- bbappend: 12
- machines: xenclient-syncui.conf xenclient-uivm.conf 
- images: xenclient-dom0-image.bbappend xenclient-uivm-image.bb 

## Commit stack (BUILD_PLAN PR sequence)
837d1eb3 meta-openxt-ui: extract UIVM and dom0 display integration
c2c912c0 meta-openxt-domains: extract NDVM, USBVM, and SyncVM
9362ba35 meta-openxt-base: relocate platform into base layer directory
73b279b0 packagegroups: add ndvm, usbvm, and syncvm groups
14f0a3bd qemu-dm: make glass integration optional
e97d8832 packagegroups: split dom0 into core and display
