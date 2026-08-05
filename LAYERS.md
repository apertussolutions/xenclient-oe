# OpenXT meta-layer layout

This repository is a **monorepo** of three OpenEmbedded layers produced by the
layer-split plan (`BUILD_PLAN.md`).

| Layer | Collection | Priority | Role |
|-------|------------|----------|------|
| `meta-openxt-base` | `openxt-base` | 9 | Headless dom0, toolstack, kernel/Xen, security, installer, stubdomain |
| `meta-openxt-domains` | `openxt-domains` | 10 | NDVM, USBVM, SyncVM |
| `meta-openxt-ui` | `openxt-ui` | 11 | UIVM + optional dom0 display/input integration |

**Dependency direction:** `openxt-base` ← `openxt-domains` ← `openxt-ui`

## bblayers.conf examples

### Headless dom0 (minimum)

```bitbake
BBLAYERS ?= " \
  ... \
  /path/to/xenclient-oe/meta-openxt-base \
"
```

Build: `MACHINE=xenclient-dom0 DISTRO=openxt-main bitbake xenclient-dom0-image`

### Dom0 + service domains (no GUI)

```bitbake
BBLAYERS ?= " \
  ... \
  /path/to/xenclient-oe/meta-openxt-base \
  /path/to/xenclient-oe/meta-openxt-domains \
"
```

Also add `meta-networking` (`networking-layer`) for NetworkManager.

### Full product (UI)

```bitbake
BBLAYERS ?= " \
  ... \
  /path/to/xenclient-oe/meta-openxt-base \
  /path/to/xenclient-oe/meta-openxt-domains \
  /path/to/xenclient-oe/meta-openxt-ui \
"
```

Add `meta-gnome`, `meta-xfce`, `vglass`, and `meta-java` as required by
`LAYERDEPENDS_openxt-ui`. The UI layer auto-loads
`conf/distro/include/openxt-ui.inc` (opengl, Dojo, Java prefs).

When `meta-openxt-ui` is present, `xenclient-dom0-image` gains
`packagegroup-openxt-dom0-display` via bbappend.

## Images by layer

| Image | Layer |
|-------|-------|
| `xenclient-dom0-image` | base (+ display packages if ui present) |
| `xenclient-initramfs-image` | base |
| `xenclient-stubdomain-initramfs-image` | base |
| `xenclient-installer-image` | base |
| `xenclient-ndvm-image` | domains |
| `usbvm-image` | domains |
| `xenclient-syncvm-image` | domains |
| `xenclient-uivm-image` | ui |

## Packagegroups

| Packagegroup | Layer |
|--------------|-------|
| `packagegroup-xenclient-common` | base |
| `packagegroup-xenclient-dom0` (core / headless) | base |
| `packagegroup-xenclient-installer` | base |
| `packagegroup-openxt-ndvm` | domains |
| `packagegroup-openxt-usbvm` | domains |
| `packagegroup-openxt-syncvm` | domains |
| `packagegroup-openxt-dom0-display` | ui |
| `packagegroup-xenclient-xfce-minimal` | ui |

## External layer dependencies

| Dependency | base | domains | ui |
|------------|:----:|:-------:|:--:|
| core / openembedded / meta-python | ✓ | via base | via base |
| virtualization-layer | ✓ | | |
| selinux | ✓ | | |
| intel | ✓ | | |
| meta-openxt-haskell-platform | ✓ | | |
| meta-openxt-ocaml-platform | ✓ | | |
| networking-layer | | ✓ | |
| gnome-layer / xfce-layer / vglass / meta-java | | | ✓ |

## Compatibility note

The former single collection name `xenclient-oe` is **retired**. Product
`bblayers.conf` files must list the three paths (or a subset) above.
Image basenames are unchanged for deploy tooling.

Git tag `pre-layer-split` marks the tree before this restructure.
