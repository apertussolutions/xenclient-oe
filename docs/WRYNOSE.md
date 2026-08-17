# Porting OpenXT meta-layers to Yocto 6.0 (Wrynose)

**Branch:** `layer-split-wrynose` (from `layer-split-v3`)  
**Target:** Yocto Project 6.0 LTS “Wrynose”  
**Source baseline:** Dunfell-compatible three-layer split (`meta-openxt-base`,
`meta-openxt-domains`, `meta-openxt-ui`)

This document tracks the port. Wrynose is a large jump from Dunfell (YP 3.1 →
6.0); work is incremental.

## Status

| Area | Status |
|------|--------|
| Branch created from layer-split-v3 | Done |
| `LAYERSERIES_COMPAT` → `wrynose` (all three layers) | Done |
| BitBake override syntax `_` → `:` (OE convert-overrides) | Done |
| Distro: `INIT_MANAGER = "sysvinit"` | Done |
| Distro: `DISTRO_FEATURES_OPTED_OUT` / `:append`/`:remove` | Done |
| Distro: `MULTI_PROVIDER_WHITELIST` → `BB_MULTI_PROVIDER_ALLOWED` | Done |
| Machine: `MACHINE_FEATURES_BACKFILL_CONSIDERED` → `MACHINE_FEATURES_OPTED_OUT` | Done |
| `inherit distutils3` → `setuptools3` | Done |
| SPDX `LICENSE` strings (GPLv2 → GPL-2.0-only, …) | Done |
| `LIC_FILES_CHKSUM` `COMMON_LICENSE_DIR` paths | Done |
| Recipe version bumps vs OE-Core / meta-oe wrynose | Pending |
| Kernel / linux-libc-headers alignment for wrynose | Pending |
| Xen / meta-virtualization wrynose integration | Pending |
| SELinux (meta-selinux wrynose) / refpolicy | Pending |
| Haskell / OCaml platform layers on wrynose | Pending |
| openxt kas: pin repos to wrynose + this branch | Pending |
| Parse-only / image builds | Pending |

## Dependency pins (openxt kas — not yet switched)

When ready, `openxt/kas/common/base.yml` (and composition defaults) should move
from `dunfell` to `wrynose` (or matching LTS branch names), for example:

| Repo | Dunfell today | Wrynose target |
|------|---------------|----------------|
| bitbake | 1.46 | wrynose-series bitbake |
| openembedded-core | dunfell | wrynose |
| meta-openembedded | dunfell | wrynose |
| meta-intel / meta-selinux / meta-virtualization | dunfell | wrynose |
| meta-qt5 | dunfell | wrynose (or successor) |
| xenclient-oe | layer-split-v3 | **layer-split-wrynose** |
| meta-openxt-{ocaml,haskell}-platform | trixie | TBD (wrynose branch) |

Do **not** point the existing dunfell ISO pipeline at this branch until those
external layers exist and parse.

## Mechanical conversion notes

Override conversion used OE-Core’s `scripts/contrib/convert-overrides.py` with
OpenXT machines: `xenclient-dom0`, `xenclient-ndvm`, `xenclient-uivm`,
`xenclient-stubdomain`, `xenclient-syncvm`, `xenclient-syncui`,
`openxt-installer`, `usbvm`.

Examples:

```bitbake
# before (dunfell)
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
do_install_append() { ... }
DISTRO_FEATURES_append += "pam selinux"
PACKAGECONFIG_append_pn-gdb = " tui"

# after (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
do_install:append() { ... }
DISTRO_FEATURES:append = " pam selinux"
PACKAGECONFIG:append:pn-gdb = " tui"
```

`:append` / `:remove` / `:prepend` assignments use `=` (not `+=`).

## Distro policy (wrynose-specific)

- **Init:** OpenXT stays on **sysvinit** (`INIT_MANAGER = "sysvinit"`). Wrynose
  defaults nodistro to systemd and drops sysv compatibility inside systemd.
- **Features:** Opt out of default `wayland`, `vulkan`, `ptest`. Headless builds
  do not force opengl; UI layer appends `opengl` and `openxt-ui`.
- **Kernel:** Still prefers `linux-openxt` 6.1%; expect work against wrynose’s
  newer reference kernels and `OLDEST_KERNEL` (5.15).

## SPDX conversion notes

Used OE-Core wrynose `scripts/contrib/convert-spdx-licenses.py` on all three
layers, then hand-fixed residual ambiguous `BSD` entries:

| Recipe | Before | After | Rationale |
|--------|--------|-------|-----------|
| `varstored` | BSD | BSD-2-Clause | upstream LICENSE is 2-clause |
| `tboot` | BSD | BSD-3-Clause | source headers are 3-clause |

Also rewrote `${COMMON_LICENSE_DIR}/GPL-2.0` → `GPL-2.0-only` (and LGPL-2.1)
so checksum paths match wrynose `common-licenses/` filenames. MD5 for
`GPL-2.0-only` matches the former `GPL-2.0` file.

Left as intentional non-generic SPDX:

- `Proprietary` (installer tweaks)
- `Intel-ACMs` (custom text under `files/additional-licenses/`)

## Recommended next increments

1. **Stand up a wrynose kas composition** in openxt (separate from dunfell
   `iso-test`) pointing at this branch + wrynose external layers.
2. **bitbake -p** (parse) for `MACHINE=xenclient-dom0 DISTRO=openxt-main` and
   fix the first wave of missing providers / renamed classes / recipe PV pins.
3. Port **bbappends** against upstream recipe renames (NetworkManager, openssh,
   grub, systemd-vs-sysv packages, etc.).
4. Align **kernel / Xen / SELinux / language platforms** with wrynose layer
   revisions.
5. Rebuild **initramfs → stubdomain → dom0 → domains → uivm → ISO** once parse
   is clean.

## References

- [Migration notes for 6.0 (wrynose)](https://docs.yoctoproject.org/6.0/migration-guides/migration-6.0.html)
- Intermediate guides: 5.1 styhead, 5.2 walnascar, 5.3 whinlatter (and earlier
  kirkstone override syntax) still apply when coming from Dunfell.
- Layer layout: `LAYERS.md`, split plan: `BUILD_PLAN.md`
