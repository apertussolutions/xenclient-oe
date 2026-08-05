# Kas Hierarchical Configuration — Implementation Plan

**Branch:** `layer-split-v2-kas` (from `layer-split-v2`)  
**Source:** `OpenXT-Build-Architecture-Kas-Hierarchical.md` (project root)  
**Date:** 2026-08-05

This plan turns the architecture proposal into incremental, reviewable commits
on the layer-split monorepo.

---

## 1. Objectives

1. Introduce a **hierarchical kas** tree under `kas/` matching the three product
   variants: headless (base), domains (base+domains), full (base+domains+ui).
2. Align machine/image ownership with `LAYERS.md` (same tables as the architecture doc).
3. Keep **scripts/** outside kas for pre/post processing (certs, stage, ISO, PXE, update).
4. Prefer **OE-Core + bitbake** (as used by the existing `build-*` validation dirs),
   not full poky — still expressed as kas `repos:`.
5. Share `DL_DIR` / `SSTATE_DIR` / certs via `local_conf_header` fragments.

Non-goals for this first pass:

- Fully working multiconfig `all.yml` BitBake build (scaffold only).
- Production-grade `deploy-iso.sh` parity with bordel (skeleton + hooks).
- kas-container / Dockerfiles.
- Locked release pin files (`*.lock.yml`).

---

## 2. Target Layout

```text
xenclient-oe/
├── kas/
│   ├── common/
│   │   ├── base.yml              # external repos + monorepo base layer + shared local.conf
│   │   ├── distro-openxt-main.yml
│   │   └── conf.yml              # OpenXT mirrors, certs, identity, host workarounds
│   ├── machines/
│   │   ├── xenclient-dom0.yml
│   │   ├── xenclient-ndvm.yml
│   │   ├── usbvm.yml
│   │   ├── xenclient-syncvm.yml
│   │   ├── xenclient-uivm.yml
│   │   ├── openxt-installer.yml
│   │   └── xenclient-stubdomain.yml
│   ├── images/
│   │   ├── dom0.yml
│   │   ├── initramfs.yml
│   │   ├── stubdomain.yml
│   │   ├── installer.yml
│   │   ├── ndvm.yml
│   │   ├── usbvm.yml
│   │   ├── syncvm.yml
│   │   └── uivm.yml
│   ├── compositions/
│   │   ├── headless.yml          # meta-openxt-base (+ residual qt5/vglass)
│   │   ├── domains.yml           # + meta-openxt-domains
│   │   ├── full.yml              # + meta-openxt-ui + gnome/xfce/java/multimedia
│   │   └── all.yml               # sequential documentation / multiconfig scaffold
│   ├── dom0.yml                  # convenience: composition + machine + image
│   ├── initramfs.yml
│   ├── stubdomain.yml
│   ├── installer.yml
│   ├── ndvm.yml
│   ├── usbvm.yml
│   ├── syncvm.yml
│   ├── uivm.yml
│   └── README.md
├── scripts/
│   ├── common.sh
│   ├── setup-host.sh
│   ├── generate-certs.sh
│   ├── stage-repository.sh
│   ├── deploy-iso.sh
│   ├── deploy-pxe.sh
│   └── deploy-update.sh
└── docs/KAS-IMPLEMENTATION-PLAN.md   # this file
```

---

## 3. Layer Mapping (from architecture §3)

| Entry point        | Composition | MACHINE              | Target image                         |
|--------------------|-------------|----------------------|--------------------------------------|
| `kas/dom0.yml`     | headless    | xenclient-dom0       | xenclient-dom0-image                 |
| `kas/initramfs.yml`| headless    | xenclient-dom0       | xenclient-initramfs-image            |
| `kas/stubdomain.yml`| headless   | xenclient-stubdomain | xenclient-stubdomain-initramfs-image |
| `kas/installer.yml`| headless    | openxt-installer     | xenclient-installer-image            |
| `kas/ndvm.yml`     | domains     | xenclient-ndvm       | xenclient-ndvm-image                 |
| `kas/usbvm.yml`    | domains     | usbvm                | usbvm-image                          |
| `kas/syncvm.yml`   | domains     | xenclient-syncvm     | xenclient-syncvm-image               |
| `kas/uivm.yml`     | full        | xenclient-uivm       | xenclient-uivm-image                 |

**Residual base gap (documented, preserved):** headless still includes
`meta-qt5` + `meta-vglass` because stubdomain/IVC (`libivc2`, `kernel-module-ivc`)
still live under vglass — same as the working `build-base` validation setup.

---

## 4. External Repos and Refspecs

| Repo | URL | Refspec | Layers enabled |
|------|-----|---------|----------------|
| bitbake | github.com/openembedded/bitbake | `1.46` | (none; provides bitbake) |
| openembedded-core | github.com/openembedded/openembedded-core | `dunfell` | `meta` |
| meta-openembedded | github.com/openembedded/meta-openembedded | `dunfell` | oe, python, networking, filesystems (+ multimedia/gnome/xfce for full) |
| meta-intel | git.yoctoproject.org/meta-intel | `dunfell` | root |
| meta-selinux | git.yoctoproject.org/meta-selinux | `dunfell` | root |
| meta-virtualization | git.yoctoproject.org/meta-virtualization | `dunfell` | root |
| meta-qt5 | github.com/meta-qt5/meta-qt5 | `dunfell` | root |
| meta-java | github.com/meta-java/meta-java | `dunfell` | root (full only) |
| meta-openxt-ocaml-platform | github.com/apertussolutions/meta-openxt-ocaml-platform | `trixie` | root |
| meta-openxt-haskell-platform | github.com/apertussolutions/meta-openxt-haskell-platform | `trixie` | root |
| meta-vglass | gitlab.com/vglass/meta-vglass | `master` | root |
| xenclient-oe (this tree) | `path: .` | — | base / domains / ui per composition |

---

## 5. local.conf Policy (`kas/common/conf.yml`)

Port from validated `build-base/conf/local.conf` + `openxt.conf`:

- Shared `DL_DIR` / `SSTATE_DIR` under `${TOPDIR}`
- `OPENXT_MIRROR` → ainfosec; PREMIRRORS for dead mirror.openxt.org
- Cert paths under `${TOPDIR}/certs`
- `LICENSE_FLAGS_WHITELIST` / `ACCEPT_INTEL_EULA`
- Host GCC 14 relax flags used on Debian Trixie builders
- `HOSTTOOLS += cmake cpack ctest` (assumes host or hosttools-prefix on PATH)
- OpenXT identity defaults (`OPENXT_BUILD_ID`, `OPENXT_RELEASE`, …) via env overrides

---

## 6. Scripts Scope

| Script | First-pass behavior |
|--------|---------------------|
| `common.sh` | Logging, die/require, path defaults |
| `setup-host.sh` | Document + install apt packages for Ubuntu 22.04 / Debian 12 (and note Trixie) |
| `generate-certs.sh` | OpenSSL self-signed prod/dev/kernel module certs into `$OPENXT_CERTS_DIR` |
| `stage-repository.sh` | Copy deploy images into a `packages.main`-style layout |
| `deploy-iso.sh` | Skeleton: prerequisites check + placeholder xorriso invocation |
| `deploy-pxe.sh` / `deploy-update.sh` | Skeleton with documented outputs |

---

## 7. Commit Sequence (execute in order)

| # | Commit subject (linux style) | Contents |
|---|------------------------------|----------|
| 1 | `docs: add kas hierarchical implementation plan` | This file |
| 2 | `kas: add common foundation for OE-Core OpenXT builds` | `common/{base,distro-openxt-main,conf}.yml` |
| 3 | `kas: add machine and image fragments` | `machines/*`, `images/*` |
| 4 | `kas: add headless, domains, and full compositions` | `compositions/*.yml` |
| 5 | `kas: add convenience entry points for each image` | top-level `kas/*.yml` |
| 6 | `scripts: add host setup and certificate helpers` | `common.sh`, `setup-host.sh`, `generate-certs.sh` |
| 7 | `scripts: add stage and deploy skeletons` | stage/deploy scripts |
| 8 | `kas: document hierarchical usage in README` | `kas/README.md` + short top-level README pointer |

---

## 8. Verification (manual / later CI)

```bash
# After installing kas (pip install kas) and host deps:
./scripts/setup-host.sh          # or ensure packages already present
./scripts/generate-certs.sh

# Headless path (matches build-base)
kas build kas/initramfs.yml
kas build kas/stubdomain.yml
kas build kas/dom0.yml
kas build kas/installer.yml

# Domains
kas build kas/ndvm.yml
kas build kas/usbvm.yml
kas build kas/syncvm.yml

# Full UI
kas build kas/uivm.yml
```

Success criteria: each `kas build` produces conf/ and invokes BitBake with the
expected MACHINE, DISTRO, BBLAYERS set, and shared downloads/sstate paths.

---

## 9. Follow-ups (out of this plan)

- Multiconfig `compositions/all.yml` with real `mc:` targets and per-MC TMPDIR.
- Port bordel ISO generation into `deploy-iso.sh`.
- `kas/*.lock.yml` for release freezes.
- Optional `kas/container/` Docker path.
- Drop residual qt5/vglass from headless once IVC moves into base.
