# OpenXT Layer Split Plan

**Document:** `BUILD_PLAN.md`  
**Scope:** Break the monolithic `xenclient-oe` meta-layer into composable layers  
**Date:** 2026-07-19  
**Status:** Phases 0–5 implemented as multi-PR commit stack on branch layer-split/pr-stack

---

## 1. Executive summary

The current `xenclient-oe` layer is a single OpenEmbedded collection (`BBFILE_COLLECTIONS = "xenclient-oe"`, priority 9, Dunfell-compatible) that builds **every** OpenXT image: dom0, installer, initramfs, stubdomain, NDVM, USBVM, SyncVM, and UIVM.

That forces any build—including a headless dom0—to declare hard dependencies on GUI-oriented layers (`gnome-layer`, `xfce-layer`, `vglass`) plus Java/Dojo tooling used only by UI data packages.

**Recommended target structure (three layers, one monorepo):**

| Layer | Purpose | Primary images |
|-------|---------|----------------|
| **meta-openxt-base** | Minimum platform: hypervisor, kernel, toolstack, security, headless dom0 | `xenclient-dom0-image` (no GUI), initramfs, stubdomain, installer |
| **meta-openxt-domains** | Core service domain images | NDVM, USBVM, SyncVM |
| **meta-openxt-ui** | UIVM + dom0 display/input/UI integration | UIVM; dom0 packagegroup extensions |

**Dependency direction (acyclic):**

```
meta-openxt-base
       ↑
meta-openxt-domains
       ↑
meta-openxt-ui
```

A headless product build enables only **base** (and optionally **domains**). A full OpenXT product enables all three.

---

## 2. Current layer analysis

### 2.1 Inventory

| Metric | Count / notes |
|--------|----------------|
| Recipe (`.bb`) files | ~146 |
| Bbappends | ~57 |
| Top-level recipe groups | `recipes-{bsp,connectivity,core,devtools,extended,graphics,kernel,openxt,qubes,sato,security,support}` |
| OpenXT-specific recipes | ~82 under `recipes-openxt/` |
| Images | 8 (dom0, initramfs, installer, stubdomain, ndvm, usbvm, syncvm, uivm) |
| Machines | 9 (`xenclient-{dom0,ndvm,uivm,stubdomain,syncvm,syncui}`, `usbvm`, `openxt-installer`, common include) |
| Packagegroups | common, dom0, extra, installer, xfce-minimal, openxt-test |
| Classes | image types, SELinux image, EFI/syslinux disk, VM common, xc-rpcgen, module signing, licenses |
| Distro | `openxt-main.conf` + `xc-rpcgen.inc` |

### 2.2 Images and what they pull

| Image | Machine | Key content | SELinux |
|-------|---------|-------------|---------|
| `xenclient-dom0-image` | `xenclient-dom0` | `packagegroup-xenclient-{common,dom0}`, argo, stubdom rootfs, firmware | Yes (`openxt-selinux-image`) |
| `xenclient-initramfs-image` | `xenclient-dom0` | busybox + LVM/TPM/SELinux initramfs modules | No (minimal) |
| `xenclient-stubdomain-initramfs-image` | `xenclient-stubdomain` | busybox, qemu-dm-stubdom, argo, xenstore | No |
| `xenclient-installer-image` | `openxt-installer` | installer packagegroup + Xen/tboot/TPM stack | Soft (refpolicy in packagegroup) |
| `xenclient-ndvm-image` | `xenclient-ndvm` | common + NM stack via `xenclient-nws`, wifi firmware, vif scripts | Yes |
| `usbvm-image` | `usbvm` | boot + kernel modules + `vusb-daemon-stub` + `argo-input-sender` | Yes |
| `xenclient-syncvm-image` | `xenclient-syncvm` | common + `sync-client`, blktap3 | No (`openxt-image`) |
| `xenclient-uivm-image` | `xenclient-uivm` | Xorg + XFCE minimal + surf + NM applet + IME + openxtfb | No (`openxt-image`) |

### 2.3 Dom0 packagegroup: core vs UI-coupled

`packagegroup-xenclient-dom0` currently mixes **control-plane** and **display/UI** packages. A practical split of its ~104 RDEPENDS:

**UI / display / input (should move to meta-openxt-ui):**

- `vglass`, `disman` (external `vglass` layer; compositor + display manager)
- `uid` (User Interface Daemon; OCaml)
- `xenmgr-data` (Dojo/Java UI assets under `/usr/lib/xui`)
- `argo-input-receiver`, `linux-input`
- `xenclient-splash-images`, `xenclient-boot-sound`, alsa utils used for boot UX
- `read-edid`, `audio-helper` (guest/display-adjacent helpers)
- `xenclient-language-sync` (UI language coordination)

**Core control-plane (stay in meta-openxt-base):**

- Xen hypervisor + tools, XSM policy, grub/shim/tboot, TPM 1.2/2.0 stack
- Storage: LVM, cryptsetup, blktap3, vhd-scripts, cryptdisks, root-ro, config-access
- Device model: `qemu-dm`, seabios, ovmf, stubdomain packaging (`devicemodel-stubdom`)
- Toolstack: `xenmgr`, `dbd`, `updatemgr`, `rpc-proxy`, `xec`, `upgrade-db`, xclibs/Haskell stack
- Network **daemon** side in dom0: `xenclient-nwd` (coordinates NDVM; NDVM itself is a separate image)
- USB **daemon** in dom0: `vusb-daemon` (host-side; USBVM uses `-stub` package from same recipe)
- SELinux load, sec scripts, measured launch helpers, firmware, logging, udev extraconf

**Important comment already in-tree:** dom0 image explicitly rejects `xserver-xorg` (“should not live in dom0, but UIVM”), yet still pulls vglass/disman/uid via the packagegroup. The layer split codifies that historical intent.

### 2.4 Cross-domain runtime architecture (why layers must stay coordinated)

```
                    ┌─────────────────────────────────────┐
                    │              dom0                    │
                    │  xenmgr, dbd, nwd, vusb-daemon,     │
                    │  rpc-proxy, [uid,vglass,disman]*    │
                    └───────┬───────────┬───────────┬─────┘
                            │ Argo/DBUS │           │
              ┌─────────────┼───────────┼───────────┼─────────────┐
              ▼             ▼           ▼           ▼             │
         ┌────────┐   ┌────────┐  ┌────────┐  ┌────────┐          │
         │  NDVM  │   │ USBVM  │  │  UIVM  │  │ SyncVM │          │
         │  nws   │   │ vusb-  │  │ XFCE + │  │ sync-  │          │
         │  NM    │   │ stub + │  │ surf + │  │ client │          │
         │        │   │ input  │  │ NM app │  │        │          │
         └────────┘   │ sender │  └────────┘  └────────┘          │
                      └────────┘                                   │
         stubdomain rootfs packaged into dom0 for HVM DM ──────────┘
```

\* UI components optional when meta-openxt-ui is included.

Xenmgr ships VM templates (`service-ndvm-*`, `service-usbvm`, `service-uivm`, `new-vm-ndvm-*`, etc.). Templates remain with the toolstack in **base**; domains/UI layers supply the images those templates boot.

### 2.5 Current external `LAYERDEPENDS`

From `conf/layer.conf`:

```
virtualization-layer, meta-openxt-haskell-platform, meta-openxt-ocaml-platform,
selinux, meta-java, intel, gnome-layer, xfce-layer, networking-layer,
meta-python, openembedded-layer, core, vglass
```

**Problem:** GUI and Java dependencies are global even when building only headless dom0 or NDVM.

### 2.6 Shared infrastructure that must not be duplicated

These are used by multiple machines and belong in **base**:

| Area | Examples |
|------|----------|
| Classes | `openxt-image`, `openxt-selinux-image`, `openxt_image_types`, disk/EFI/syslinux, `xc-rpcgen*`, module signing |
| Distro | `openxt-main.conf`, preferred providers (kernel, xenstored, networkmanager versions) |
| Kernel | `linux-openxt`, defconfigs, OpenXT patches |
| Xen | `xen_*` bbappends, blktap3, XSM policy, ocaml xen libs |
| IPC | argo module/lib, libxcdbus, xclibs, idl + rpcgen |
| Security | tboot, trousers/tpm-tools/tpm2-*, refpolicy OpenXT modules, svirt-interpose, acms |
| Common image bits | `packagegroup-xenclient-common`, `xenclient-version.inc`, busybox OpenXT config, base-files, openssh argo hooks |

### 2.7 SELinux policy coupling

`refpolicy-mcs` bbappend embeds **all** OpenXT modules (dom0 services, ndvm-related, glass/disman/uid, installer, stubdom helpers) in one place. Options:

1. **Keep full policy in base** (simplest; headless builds carry unused module sources; modules can remain unloadable if packages absent).
2. **Split policy sources by layer** with bbappends that add modules only when that layer is present (cleaner dependency story; more migration work; risk of interface drift).
3. **Hybrid:** base policy + optional `refpolicy` bbappends in domains/ui that only add domain/UI modules.

**Recommendation:** start with (1) for phase-1 mechanical split; migrate to (3) once images build green.

### 2.8 Machine / bbappend coupling hotspots

Machine-specific logic that must move carefully:

| Location | Coupling |
|----------|----------|
| `base-files` bbappend | `dirs755_append_xenclient-dom0` and `_xenclient-uivm` |
| `monit` bbappend | dom0 runlevel 5 for vglass/disman |
| `refpolicy` postinst | `pkg_postinst_..._xenclient-dom0` |
| `openxtfb` bbappend | autoload on `xenclient-uivm` |
| `qemu-dm.inc` | `require qemu-dm-vglass.inc` (ties DM to glass) |
| NetworkManager recipes/bbappends | primarily NDVM + UIVM applet stack |
| `create-ndvm` in dom0-tweaks | runtime helper; stays base (uses xenmgr) |

---

## 3. Evaluation of split alternatives

### 3.1 Option A — Three layers by product surface (recommended)

**base / domains / ui** as requested.

| Pros | Cons |
|------|------|
| Matches product composition (headless vs service VMs vs GUI) | Dom0 recipes split across packagegroups |
| Removes gnome/xfce/vglass from headless `bblayers` | SELinux policy remains a temporary monolith |
| Aligns with existing image/machine boundaries | xenmgr templates still “know about” UIVM/NDVM |
| Clear layer dependency DAG | Requires packagegroup refactor before file moves |

### 3.2 Option B — One layer per image machine

`meta-openxt-dom0`, `meta-openxt-ndvm`, `meta-openxt-usbvm`, `meta-openxt-uivm`, …

| Pros | Cons |
|------|------|
| Maximum isolation | Heavy duplication of common classes/distro/kernel |
| | Explosion of `LAYERDEPENDS` and CI matrix |
| | Shared libs (argo, xclibs, idl) need a fifth “core” layer anyway |

**Verdict:** Reject as primary structure. Optionally map **packagegroups/images** 1:1 to machines *inside* the three layers.

### 3.3 Option C — Functional layers (core / toolstack / service-vms / ui)

| Pros | Cons |
|------|------|
| Cleaner software architecture | Headless dom0 still needs core+toolstack (two layers for one image) |
| Toolstack could be reused outside OpenXT images | More than three layers; weaker match to “min dom0” goal |

**Verdict:** Good internal *directory* organization under base; not a better top-level layer count for the stated goals.

### 3.4 Option D — Stay monolithic; use `IMAGE_FEATURES` / packagegroups only

| Pros | Cons |
|------|------|
| Minimal churn | GUI layers still in `LAYERDEPENDS` / parse graph |
| | No independent domain-only product builds |
| | Does not reduce dependency blast radius |

**Verdict:** Necessary *technique* inside the split (packagegroups), insufficient *as* the split.

### 3.5 Option E — Dynamic layers for UI

Keep one layer collection but use Yocto `dynamic-layers/` for gnome/xfce/vglass bbappends.

| Pros | Cons |
|------|------|
| OE-idiomatic for optional UI | Does not isolate NDVM/USBVM recipes |
| | Dom0 GUI packages still live in same layer tree |

**Verdict:** Use as a **secondary** pattern inside meta-openxt-ui if desired; not a substitute for domains layer.

### 3.6 Option F — Four layers (base + domains + ui + installer)

Installer reuses nearly all of base’s security/boot stack (`packagegroup-xenclient-installer` ∩ dom0 is large: tboot, TPM, Xen, blktap, measured launch).

| Pros | Cons |
|------|------|
| Installer can evolve independently | Extra layer for little dependency win |
| | Most installer RDEPENDS still require base |

**Verdict:** Keep installer **in base** for now; revisit only if installer becomes a separate product line.

### 3.7 Option G — Repo strategy

| Approach | Recommendation |
|----------|----------------|
| **Monorepo** with three layer directories | **Preferred** — shared versioning, atomic refactors of IDL/xclibs/policy |
| Separate git repos per layer | Only if independent release trains are required later |
| Rename `xenclient-oe` → multi-layer tree | Preserve history via `git mv`; keep collection names stable during transition |

### 3.8 Decision

**Adopt Option A** (three product layers), with:

- Installer + stubdomain + headless dom0 in **base**
- NDVM, USBVM, SyncVM in **domains**
- UIVM + dom0 display/UI integration in **ui**
- Monorepo layout
- Packagegroup-first refactor before bulk file moves
- Hybrid SELinux approach (full policy in base initially)

This is better than per-image layers (B) or pure IMAGE_FEATURES (D) because it simultaneously:

1. Minimizes recipes/deps for headless dom0  
2. Groups service domain images that share PV patterns  
3. Isolates the heavy GUI stack and vglass  

---

## 4. Target layer design

### 4.1 Repository layout

```
openxt-oe/                          # renamed monorepo root (or keep xenclient-oe name)
├── BUILD_PLAN.md
├── README
├── COPYING.*
├── meta-openxt-base/
│   ├── conf/
│   │   ├── layer.conf
│   │   ├── distro/openxt-main.conf
│   │   ├── distro/xc-rpcgen.inc
│   │   └── machine/
│   │       ├── xenclient-common.conf
│   │       ├── xenclient-dom0.conf
│   │       ├── xenclient-stubdomain.conf
│   │       └── openxt-installer.conf
│   ├── classes/                    # all OpenXT bbclasses
│   ├── files/
│   └── recipes-*/                  # see §5.1
├── meta-openxt-domains/
│   ├── conf/
│   │   ├── layer.conf
│   │   └── machine/
│   │       ├── xenclient-ndvm.conf
│   │       ├── usbvm.conf
│   │       └── xenclient-syncvm.conf
│   └── recipes-*/                  # see §5.2
└── meta-openxt-ui/
    ├── conf/
    │   ├── layer.conf
    │   └── machine/
    │       ├── xenclient-uivm.conf
    │       └── xenclient-syncui.conf   # if still used
    └── recipes-*/                  # see §5.3
```

### 4.2 Layer metadata

#### meta-openxt-base

```bitbake
BBFILE_COLLECTIONS += "openxt-base"
BBFILE_PATTERN_openxt-base := "^${LAYERDIR}/"
BBFILE_PRIORITY_openxt-base = "9"
LAYERSERIES_COMPAT_openxt-base = "dunfell"   # or current series when upgraded
LAYERDEPENDS_openxt-base = " \
    core \
    openembedded-layer \
    meta-python \
    virtualization-layer \
    selinux \
    intel \
    meta-openxt-haskell-platform \
    meta-openxt-ocaml-platform \
"
# Optional: meta-java only if something in base still needs it after xenmgr-data moves
```

**Removed from base vs today:** `gnome-layer`, `xfce-layer`, `vglass`, (preferably) `meta-java`, (preferably) `networking-layer`.

> Note: if `xenclient-nwd` or other base packages still need NetworkManager **build** IDL only, prefer a thin native/IDL extract over full `networking-layer` in base. Runtime NM stays in domains/UI.

#### meta-openxt-domains

```bitbake
BBFILE_COLLECTIONS += "openxt-domains"
BBFILE_PRIORITY_openxt-domains = "10"
LAYERDEPENDS_openxt-domains = " \
    openxt-base \
    networking-layer \
"
```

#### meta-openxt-ui

```bitbake
BBFILE_COLLECTIONS += "openxt-ui"
BBFILE_PRIORITY_openxt-ui = "11"
LAYERDEPENDS_openxt-ui = " \
    openxt-base \
    openxt-domains \
    gnome-layer \
    xfce-layer \
    vglass \
    meta-java \
"
```

`openxt-domains` is a soft product dependency for full systems (NM applet talks to NDVM path); if a UI-only experimental image is needed later, domains can be downgraded to `LAYERRECOMMENDS`.

### 4.3 Distro and MACHINE composition

| Config | Layer |
|--------|-------|
| `DISTRO = "openxt-main"` (or renamed `openxt`) | base |
| `MACHINE = "xenclient-dom0"` | base |
| `MACHINE = "xenclient-ndvm"` / `usbvm` / `xenclient-syncvm` | domains |
| `MACHINE = "xenclient-uivm"` | ui |

**Distro feature hygiene:**

- Keep `selinux multiarch virtualization polkit pam` in base distro.
- Move or gate `opengl` so headless dom0 does not force GL stacks; enable via ui distro include or `DISTROOVERRIDES` when ui layer present.
- Prefer `require conf/distro/include/openxt-ui.inc` from ui layer rather than hard-coding UI prefs in base (`dojosdk` version pins for syncui/uivm).

### 4.4 Packagegroup model (critical refactor)

Replace the overloaded packagegroups with composable ones:

| Packagegroup | Layer | Role |
|--------------|-------|------|
| `packagegroup-openxt-common` | base | Shared userland utilities (today’s common) |
| `packagegroup-openxt-dom0-core` | base | Headless dom0 (today’s dom0 **minus** UI list) |
| `packagegroup-openxt-dom0-display` | ui | vglass, disman, uid, xenmgr-data, input, splash, boot-sound, … |
| `packagegroup-openxt-installer` | base | Unchanged role |
| `packagegroup-openxt-ndvm` | domains | NDVM image contents beyond common |
| `packagegroup-openxt-usbvm` | domains | USBVM image contents |
| `packagegroup-openxt-syncvm` | domains | SyncVM image contents |
| `packagegroup-openxt-uivm` | ui | XFCE minimal + UIVM stack |
| `packagegroup-openxt-test` / `extra` | base (or optional) | Dev extras |

**Image recipes after refactor:**

```bitbake
# meta-openxt-base: xenclient-dom0-image.bb
IMAGE_INSTALL += " \
    packagegroup-openxt-common \
    packagegroup-openxt-dom0-core \
    ...
"
# Full product dom0 (local.conf or ui bbappend):
IMAGE_INSTALL_append = " packagegroup-openxt-dom0-display"
```

Alternatively, ui layer ships:

```bitbake
# meta-openxt-ui/recipes-core/packagegroups/packagegroup-openxt-dom0-display.bb
# and a bbappend:
# xenclient-dom0-image.bbappend
IMAGE_INSTALL_append = " packagegroup-openxt-dom0-display"
```

Prefer **bbappend on the image** so base image stays headless by default when ui is not in `BBLAYERS`.

---

## 5. Recipe placement map

### 5.1 meta-openxt-base (minimum headless dom0 + platform)

#### Conf / classes / files

- All of current `classes/`
- `conf/distro/*`, `conf/machine/xenclient-{common,dom0,stubdomain}.conf`, `openxt-installer.conf`
- `files/openxt-fs-perms.txt`, additional licenses

#### Images

- `xenclient-dom0-image.bb` (headless package set)
- `xenclient-initramfs-image.bb`
- `xenclient-stubdomain-initramfs-image.bb`
- `xenclient-installer-image.bb`
- `xenclient-version.inc`

#### Packagegroups

- common, dom0-core, installer, extra, test
- `packagegroup-base.bbappend` (console keymaps)

#### Kernel / BSP / Xen

- `recipes-kernel/linux*`, linux-firmware bbappend, ivc module bbappend (if required by base features)
- `recipes-bsp/grub*`, `shim`
- `recipes-extended/xen/*`, `qemu-dm` (**see UI note on vglass.inc**), seabios, vgabios, ipxe bbappend
- `recipes-core/varstored`, microcode, ovmf bbappend

#### OpenXT core services / libs

- argo (+ headers), argo-exec **core binary** (input packages split — see UI)
- idl, xenclient-rpcgen, xclibs, libxcdbus, libxenbackend, libicbinn*
- manager/* (xenmgr, dbd, rpc-proxy, updatemgr, xec, upgrade-db, libxenmgr-core)
- network: **xenclient-nwd only** (daemon in dom0)
- vusb-daemon recipe (dom0 package; stub package may be pulled by domains image)
- xctools (xcpmd, helpers needed by DM/toolstack)
- stubdomains packaging recipes
- openxt-keymanagement, openxt-measuredlaunch, openxt-ocaml-libs (if needed by non-UI)
- xenclient-{dom0-tweaks,config-access,cryptdisks,root-ro,sec-scripts,tpm-*,get-config-key,pcrdiff,repo-certs,feed-configs,caps,eula,preload-hs-libs,console-keymaps}
- secure-vm, vhd-scripts, dd-buffered, trousers (recipe in-tree)
- essential-target-builddepends (dev)

#### Security

- Entire `recipes-security/` (phase 1)
- initramfs modules for TPM/SELinux/LVM

#### Core OS customizations

- busybox, base-files (dom0 dirs only; UIVM dirs via ui bbappend), base-passwd, dbus, initscripts, init-ifupdown, udev-extraconf-dom0, sysvinit-inittab, glib, openssh bbappend, rsyslog (+ conf-dom0), logrotate, lvm2, pam, polkit, monit (**split vglass-oriented dom0 pieces to ui**), rng-tools, etc. as required by core images

#### QEMU / glass coupling action item

Today `qemu-dm.inc` unconditionally `require`s `qemu-dm-vglass.inc`. For headless base:

1. Make glass patches/PACKAGECONFIG conditional on `DISTRO_FEATURES` or packageconfig `vglass`
2. Or move vglass-specific qemu patches to ui bbappend  

This is a **hard prerequisite** for a meaningful headless split.

### 5.2 meta-openxt-domains (NDVM, USBVM, SyncVM)

#### Machines

- `xenclient-ndvm.conf`, `usbvm.conf`, `xenclient-syncvm.conf`

#### Images

- `xenclient-ndvm-image.bb`
- `usbvm-image.bb`
- `xenclient-syncvm-image.bb`

#### Domain-specific recipes

| Recipe / tree | Domain |
|---------------|--------|
| `xenclient-nws` + network.inc shared bits as needed | NDVM |
| `xenclient-ndvm-tweaks` | NDVM |
| `xen-vif-scripts-ndvm` | NDVM |
| NetworkManager recipes + bbappends + certs | NDVM (and UI applet build may need versions aligned) |
| modemmanager/ppp pulls via image | NDVM |
| `vusb` stub usage / usbvm image deps | USBVM |
| `argo-input-sender` package (from argo-exec) | USBVM |
| `qubes-input-proxy` sender half | USBVM (recipe may stay base if shared; packages selected by image) |
| `xenclient-syncvm-tweaks`, `sync-client` | SyncVM |
| `dbd-tools-vm` if VM-only | NDVM |
| `xenclient-dbusbouncer` | Primarily UIVM path → **prefer ui**; if NDVM ever uses it, keep base |

#### Packagegroups

- `packagegroup-openxt-ndvm`
- `packagegroup-openxt-usbvm`
- `packagegroup-openxt-syncvm`

#### Optional SELinux

- Later: bbappend adding only NDVM/USB-specific policy modules if split from base.

### 5.3 meta-openxt-ui (UIVM + dom0 integration)

#### Machines

- `xenclient-uivm.conf`, `xenclient-syncui.conf` if retained

#### Images

- `xenclient-uivm-image.bb`

#### UIVM stack

- `packagegroup-openxt-xfce-minimal` (rename from xenclient-xfce-minimal)
- `xenclient-uivm-xsessionconfig`
- `surf` (recipes-sato)
- `network-manager-applet` (+ locales)
- graphics: xorg bbappends, openxtfb kernel module bbappends
- IME: uim, anthy (+ native)
- fonts, matchbox-keyboard, xterm bbappend
- `sync-wui` if still a UI surface
- dojosdk-native version selection for UI data builds

#### Dom0 integration (packages + image bbappend)

- `uid`
- `xenmgr-data`
- `vglass` / `disman` consumption (recipes may live in external vglass layer; only RDEPENDS/policy/monit hooks here)
- `argo-input-receiver` (+ qubes-input-proxy receiver)
- splash images, boot sound
- language-sync
- read-edid, linux-input (if only UI path needs them)
- monit dom0 runlevel/config for glass
- base-files UIVM directory appends
- SELinux modules: `glass`, `disman`, `uid`, `argo-input` (when policy is modularized)
- `qemu-dm` glass enablement bbappend

#### Dom0 image integration pattern

```bitbake
# meta-openxt-ui/recipes-core/images/xenclient-dom0-image.bbappend
IMAGE_INSTALL_append = " packagegroup-openxt-dom0-display"
```

When ui is not in `BBLAYERS`, dom0 builds without display stack.

### 5.4 Ambiguous placements (decisions)

| Item | Decision | Rationale |
|------|----------|-----------|
| Installer | **base** | Shares security/boot with dom0; not a service VM |
| Stubdomain | **base** | Required to package DM into headless dom0 |
| SyncVM | **domains** | Service domain image pattern |
| `xenclient-nwd` | **base** | Runs in dom0 even without building NDVM image in same session |
| `xenclient-nws` + NM | **domains** | NDVM runtime |
| `vusb-daemon` recipe | **base** | Dom0 needs full daemon; USBVM image RDEPENDS `-stub` |
| `argo-exec` multi-package | **base recipe**; UI/domains select packages | Avoid duplicating recipe |
| `qubes-input-proxy` | **base** or **ui** | Shared sender/receiver; recommend base recipe, package selection by image |
| `dbusbouncer` | **ui** | Described as dom0–UIVM DBUS bridge |
| `heimdallr` / eula / caps | **base** | xenmgr RDEPENDS |
| `surfman` leftover | Audit; likely obsolete vs vglass → **ui** or delete |
| `meta-java` / dojo | **ui** | Only xenmgr-data / toolstack-data |
| Haskell platform | **base** | xenmgr, nwd, updatemgr |
| OCaml platform | **base** initially | uid is UI but openxt-ocaml-libs may be shared; re-evaluate after uid moves |
| Intel layer | **base** | microcode / platform |

---

## 6. Build configurations after split

### 6.1 Headless dom0 (minimum)

`bblayers.conf` includes: oe-core, meta-oe, meta-python, meta-selinux, meta-virtualization, meta-intel (as needed), haskell/ocaml platforms, **meta-openxt-base**.

```bash
MACHINE=xenclient-dom0 DISTRO=openxt-main bitbake xenclient-dom0-image
# also: xenclient-initramfs-image, stubdomain machine builds as required by packaging
```

### 6.2 Dom0 + service domains (no GUI)

Add **meta-openxt-domains** + networking-layer.

```bash
MACHINE=xenclient-ndvm  bitbake xenclient-ndvm-image
MACHINE=usbvm           bitbake usbvm-image
MACHINE=xenclient-syncvm bitbake xenclient-syncvm-image
```

Multi-machine builds continue to use the existing OpenXT multi-machine workflow (separate build dirs or `BBMULTICONFIG` if/when adopted).

### 6.3 Full product

Add **meta-openxt-ui** + gnome + xfce + vglass + java.

```bash
MACHINE=xenclient-uivm bitbake xenclient-uivm-image
MACHINE=xenclient-dom0 bitbake xenclient-dom0-image   # now includes display packagegroup via bbappend
```

### 6.4 Installer

Still from base (with or without domains/ui layers present):

```bash
MACHINE=openxt-installer bitbake xenclient-installer-image
```

---

## 7. Implementation plan (phased)

### Phase 0 — Preconditions and inventory freeze

1. Tag current `xenclient-oe` (`pre-layer-split`).
2. Export a machine×image dependency matrix from bitbake (`bitbake -g` per image) to validate the placement map against real RDEPENDS (this document’s map is static analysis).
3. Document multi-machine build entrypoints used by the product (wiki/scripts) so they can be updated.

**Exit criteria:** Dependency graphs archived for dom0, ndvm, usbvm, uivm, installer, stubdomain.

### Phase 1 — Packagegroup and image refactor (still one layer)

Do **not** move files yet. Inside current tree:

1. Create `packagegroup-openxt-dom0-core` and `packagegroup-openxt-dom0-display`.
2. Point `xenclient-dom0-image` at **core only**.
3. Add optional `IMAGE_FEATURES` or a second image recipe `xenclient-dom0-gui-image` that adds display packagegroup (temporary validation vehicle).
4. Split NDVM/USBVM/SyncVM image contents into dedicated packagegroups (even if they live in the same layer).
5. Make `qemu-dm` glass integration conditional; prove headless dom0 rootfs lacks vglass/disman/uid/xenmgr-data.
6. Gate `DISTRO_FEATURES` opengl for headless.

**Exit criteria:** Headless dom0 image builds and boots to toolstack without UI packages installed; full image still buildable via display packagegroup.

### Phase 2 — Introduce layer directories (mechanical)

1. Create `meta-openxt-{base,domains,ui}` directories in-repo.
2. `git mv` files per §5; preserve history.
3. Write three `layer.conf` files with narrowed `LAYERDEPENDS`.
4. Temporary compatibility: if needed, keep a thin top-level `conf/layer.conf` that errors with a message pointing to the three layers (avoid dual-collection surprises).
5. Update product `bblayers.conf` templates / setup scripts.

**Exit criteria:** `bitbake-layers show-layers` lists three OpenXT layers; same images parse.

### Phase 3 — Domains layer extraction

1. Move NDVM/USBVM/SyncVM machines, images, tweaks, nws, NM stack, vif scripts.
2. Confirm `LAYERDEPENDS` pulls networking only here.
3. CI job: domains images with base+domains only (no ui layers).

**Exit criteria:** NDVM and USBVM build without gnome/xfce/vglass/java in bblayers.

### Phase 4 — UI layer extraction

1. Move UIVM machine/image/xsessionconfig/xfce packagegroup/surf/graphics/IME.
2. Move dom0 display packagegroup + `xenclient-dom0-image.bbappend`.
3. Move uid, xenmgr-data, splash, boot-sound, language-sync, input receiver hooks, monit glass config.
4. Move Java/Dojo preferred versions into ui distro include.
5. CI job: full product stack.

**Exit criteria:** UIVM builds; dom0 with ui layer contains display stack; dom0 without ui layer does not.

### Phase 5 — Policy, docs, and cleanup

1. Modularize SELinux modules across layers (optional hybrid).
2. Remove dead recipes (`surfman` if unused).
3. Update README, wiki build instructions, license aggregation scripts (`xenclient-licences`).
4. Align naming: prefer `openxt-*` over legacy `xenclient-*` for **new** packagegroups; keep image basenames stable for deploy tooling unless a coordinated rename is planned.
5. Revisit ocaml/java layer deps once graphs re-measured.

**Exit criteria:** Docs match reality; no recipes left in limbo; headless and full CI both green.

---

## 8. Risk register and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Circular deps (domains needs xenmgr templates; base create-ndvm expects NDVM image at runtime) | High | Runtime-only coupling is OK; do not make base `DEPENDS` on domain **images** |
| `devicemodel-stubdom` multi-machine packaging | High | Keep stubdomain machine + packaging recipes in base; document build order |
| SELinux denials when UI packages absent | Medium | Policy modules present but unused; test enforcing headless early |
| NetworkManager version pins in distro | Medium | Move NM `PREFERRED_VERSION` to domains (and ui applet pin) via distro includes |
| Haskell/OCaml platforms always heavy for base | Medium | Accepted cost for toolstack; not part of GUI problem |
| `qemu-dm` glass require | High | Phase 1 conditionalization (hard gate) |
| Bbappend override conflicts across layers | Medium | Strict priority: base 9, domains 10, ui 11; one owner per bbappend path |
| External consumers of layer name `xenclient-oe` | Medium | Compatibility shim release notes; keep image names stable |
| Fidelis/other downstream forks | Medium | This plan is compatible with a slim platform base + optional openxt layers (see existing empty `meta-openxt-ndvm` placeholder in related builds) |

---

## 9. Validation strategy

### 9.1 Parse / dependency checks

```bash
bitbake-layers show-appends
bitbake -g xenclient-dom0-image    # without ui layer: assert no vglass/uid/xui
bitbake -g xenclient-ndvm-image    # without ui: assert no xfce/surf
bitbake -g xenclient-uivm-image    # with ui
```

### 9.2 Image content checks

- Headless dom0 rootfs: reject paths/packages `vglass`, `disman`, `uid`, `/usr/lib/xui`, `xserver-xorg`.
- NDVM: contains `network-slave` / NM; no XFCE.
- USBVM: `vusb-daemon-stub`, `argo-input-sender`; minimal footprint.
- UIVM: Xorg + XFCE + surf + openxtfb.
- Dom0+ui: display packagegroup present; monit runlevel 5 config present.

### 9.3 Runtime smoke (hardware or nested)

1. Headless: Xen boots, xenstored, xenmgr, create VM via CLI (`xec`), NDVM attach if domains image installed manually.
2. With domains: NDVM networking, USBVM device assignment.
3. With UI: UIVM start, input path, glass composition.

### 9.4 CI matrix (minimum)

| Job | Layers | Images |
|-----|--------|--------|
| base-headless | base | dom0, initramfs, stubdomain, installer |
| base+domains | base, domains | ndvm, usbvm, syncvm |
| full | base, domains, ui | all + dom0 with display |

---

## 10. Migration notes for developers

1. **Do not** add new GUI RDEPENDS to `packagegroup-openxt-dom0-core`.
2. Service domain features land in **domains**; if dom0 needs a control-plane companion (like nwd), put the companion in **base** and document the pair.
3. Prefer packagegroups over ad-hoc `IMAGE_INSTALL` lists in images.
4. When adding SELinux policy, place modules with the layer that owns the daemon recipe (after Phase 5 modularization).
5. Multi-machine deploy scripts should treat domain/UI images as optional artifacts.

---

## 11. Naming recommendations

| Current | Proposed |
|---------|----------|
| Layer collection `xenclient-oe` | `openxt-base`, `openxt-domains`, `openxt-ui` |
| Repo directory `xenclient-oe` | `openxt-oe` (optional rename) |
| `packagegroup-xenclient-*` | `packagegroup-openxt-*` (compat provides optional) |
| Image basenames `xenclient-*-image` | **Keep** (deploy/install scripts) |
| Distro `openxt-main` | Keep or rename to `openxt` with alias |

---

## 12. Success criteria (definition of done)

1. **Headless dom0** builds with meta-openxt-base only (no gnome/xfce/vglass/java in `BBLAYERS`).
2. **NDVM and USBVM** build with base+domains only.
3. **UIVM** builds with all three layers; dom0 gains UI integration only when ui layer is present.
4. Layer dependencies are acyclic and documented.
5. CI covers the three compositions in §9.4.
6. README/build wiki describe the three-layer model; this plan is updated or superseded by a short `LAYERS.md`.

---

## 13. Suggested first PR sequence (implementation)

| PR | Title | Scope |
|----|-------|-------|
| 1 | Split dom0 packagegroup into core + display | Phase 1 packagegroups; image uses core |
| 2 | Conditionalize qemu-dm glass | Phase 1 hard gate |
| 3 | Introduce packagegroups for ndvm/usbvm/syncvm | Phase 1 |
| 4 | Create meta-openxt-base directory and move platform | Phase 2 partial |
| 5 | Create meta-openxt-domains and move service VMs | Phase 3 |
| 6 | Create meta-openxt-ui and move UIVM + dom0 display | Phase 4 |
| 7 | Distro feature / LAYERDEPENDS cleanup + docs | Phase 5 |

Each PR should be buildable on its own to avoid a flag-day.

---

## 14. Appendix A — Image → layer quick reference

| Image | Layer owner |
|-------|-------------|
| `xenclient-dom0-image` | base (+ ui bbappend for display) |
| `xenclient-initramfs-image` | base |
| `xenclient-stubdomain-initramfs-image` | base |
| `xenclient-installer-image` | base |
| `xenclient-ndvm-image` | domains |
| `usbvm-image` | domains |
| `xenclient-syncvm-image` | domains |
| `xenclient-uivm-image` | ui |

## 15. Appendix B — Current LAYERDEPENDS reassignment

| Dependency | base | domains | ui |
|------------|:----:|:-------:|:--:|
| core / openembedded / meta-python | ✓ | via base | via base |
| virtualization-layer | ✓ | | |
| selinux | ✓ | | |
| intel | ✓ | | |
| meta-openxt-haskell-platform | ✓ | | |
| meta-openxt-ocaml-platform | ✓* | | ✓* (if only uid) |
| networking-layer | | ✓ | ✓ (applet stack) |
| gnome-layer | | | ✓ |
| xfce-layer | | | ✓ |
| vglass | | | ✓ |
| meta-java | | | ✓ |

\* Re-measure after uid relocation; base may drop ocaml if nothing else needs it.

## 16. Appendix C — Out of scope (explicit)

- Upgrading Dunfell → newer Yocto (orthogonal; do before or after split, not in the same PR train if avoidable).
- Rewriting xenmgr/UIVM architecture (e.g. eliminating UIVM).
- Merging with unrelated Fidelis platform base recipes (can *consume* openxt layers later).
- Binary reproducibility / offline mirror setup.

---

## 17. Conclusion

The monolithic `xenclient-oe` layer already encodes three natural product surfaces—**control plane (dom0)**, **device service domains**, and **UI**—but packages them as one BitBake collection with global GUI dependencies.

After evaluating per-image layers, functional four-layer splits, IMAGE_FEATURES-only approaches, and installer separation, the **best fit** remains the requested three-layer model with two refinements:

1. **Installer + stubdomain stay in base** (not a fourth layer; not domains).  
2. **Packagegroup and qemu-dm decoupling first**, then mechanical `git mv` into `meta-openxt-{base,domains,ui}` in a monorepo.

Executing the phased plan yields a headless dom0 build with minimum recipes and layers, a domains layer for NDVM/USBVM/SyncVM, and a UI layer that both builds UIVM and optionally integrates display/input into dom0—without breaking the Argo/toolstack architecture that ties the system together at runtime.
