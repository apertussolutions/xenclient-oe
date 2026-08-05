# Kas configuration for OpenXT (layer-split)

Hierarchical kas YAML for building OpenXT images from this monorepo
(`meta-openxt-base`, `meta-openxt-domains`, `meta-openxt-ui`).

See also:

- Architecture: project `OpenXT-Build-Architecture-Kas-Hierarchical.md`
- Implementation plan: `docs/KAS-IMPLEMENTATION-PLAN.md`
- Layer ownership: `LAYERS.md`
- Monorepo overview: top-level `README`

## Prerequisites

```bash
./scripts/setup-host.sh      # apt packages + pip install kas
```

Dunfell bitbake needs **Python 3.11** on modern hosts (asyncore). Point
`OPENXT_PYTHON3` at a 3.11 binary if it is not already on `PATH` as
`python3.11`.

## Workspace model (`kas-init-build-env`)

```bash
cd /path/to/xenclient-oe
source ./scripts/kas-init-build-env [WORKSPACE] [INSTANCE]
```

| Argument / variable                  | Meaning                                              | Default                           |
| ------------------------------------ | ---------------------------------------------------- | --------------------------------- |
| `WORKSPACE` / `OPENXT_KAS_WORKSPACE` | Base for layers, shared caches, certs, instances     | `<parent-of-monorepo>/openxt-kas` |
| `INSTANCE` / `OPENXT_KAS_INSTANCE`   | Name of this build configuration                     | `default`                         |
| `KAS_BUILD_DIR`                      | Kas instance dir (`conf/`, `tmp/`, deploy)           | `$WORKSPACE/build-$INSTANCE`      |
| `DL_DIR`                             | Shared downloads                                     | `$WORKSPACE/downloads`            |
| `SSTATE_DIR`                         | Shared sstate                                        | `$WORKSPACE/sstate-cache`         |
| `OPENXT_CERTS_DIR`                   | Signing certs                                        | `$WORKSPACE/certs`                |
| `OPENXT_LAYER_IMPORT`                | **Explicit** pre-cloned layers to symlink (optional) | unset (no auto-detect)            |

### Workspace layout

```text
$OPENXT_KAS_WORKSPACE/          # e.g. ~/projects/openxt/openxt-kas
  layers/                       # OE + platforms (clones or explicit import links)
  downloads/                    # shared DL_DIR  (= ${TOPDIR}/../downloads)
  sstate-cache/                 # shared SSTATE  (= ${TOPDIR}/../sstate-cache)
  certs/                        # shared signing  (= ${TOPDIR}/../certs)
  build-default/                # KAS_BUILD_DIR for instance "default"
  build-dom0/                   # another instance, same caches
  .openxt-kas-workspace         # stamp file

$OPENXT_ROOT/                   # this monorepo
  layers -> $WORKSPACE/layers   # gitignored symlink (created by init)
  kas/dom0.yml                  # ordinary entry points
```

Committed kas YAML uses monorepo-relative `path: layers/<repo>`. Shared caches
use `${TOPDIR}/../…` so that with `KAS_BUILD_DIR=$WORKSPACE/build-<instance>`
the caches resolve to the workspace siblings. **No generated kas fragments and
no config-concatenation helper are required.**

### Build after init

```bash
kas build kas/dom0.yml
kas build kas/ndvm.yml
./scripts/kas-build-all.sh dom0
./scripts/kas-build-all.sh ndvm usbvm syncvm
./scripts/kas-build-all.sh          # all product images
```

First-time layer fetch into the workspace:

```bash
kas checkout kas/dom0.yml
```

To reuse existing layer clones **once**, set an explicit import path (nothing
is auto-detected from development directories):

```bash
OPENXT_LAYER_IMPORT=/path/to/existing/layers \
  source ./scripts/kas-init-build-env /data/openxt-kas default
```

### Switching instances

```bash
source ./scripts/kas-init-build-env /data/openxt-kas dom0
kas build kas/dom0.yml

source ./scripts/kas-init-build-env /data/openxt-kas ndvm
kas build kas/ndvm.yml
# same layers + sstate; separate conf/tmp
```

## Environment summary

| Variable                | Purpose                                       |
| ----------------------- | --------------------------------------------- |
| `OPENXT_KAS_WORKSPACE`  | Workspace root (layers + shared caches)       |
| `OPENXT_KAS_INSTANCE`   | Instance name → `build-$INSTANCE`             |
| `KAS_BUILD_DIR`         | Kas/bitbake build directory for this instance |
| `OPENXT_CERTS_DIR`      | Signing certs (default: `$WORKSPACE/certs`)   |
| `OPENXT_RELEASE`        | Release string for deploy scripts             |
| `DL_DIR` / `SSTATE_DIR` | Shared caches (default under workspace)       |
| `OPENXT_IMAGE_ROOTS`    | Colon-separated deploy/images search path     |
| `OPENXT_PYTHON3`        | CPython 3.11 for bitbake                      |
| `OPENXT_LAYER_IMPORT`   | Explicit pre-cloned layers directory          |

## Layout of this repository

```text
kas/
  common/           # repos, DISTRO, local.conf fragments
  machines/         # MACHINE= fragments
  images/           # target= + distro include
  compositions/     # headless | domains | full | all
  <image>.yml       # convenience entry points
```

Run `kas` from the **xenclient-oe repository root** so includes such as
`kas/compositions/headless.yml` resolve.

## Product compositions

| File                        | Layers                                             |
| --------------------------- | -------------------------------------------------- |
| `compositions/headless.yml` | base (+ residual qt5/vglass for IVC)               |
| `compositions/domains.yml`  | base + domains                                     |
| `compositions/full.yml`     | base + domains + ui (+ gnome/xfce/java/multimedia) |
| `compositions/all.yml`      | full checkout; sequential builds still required    |

## Convenience builds

```bash
source ./scripts/kas-init-build-env

kas build kas/initramfs.yml
kas build kas/stubdomain.yml
kas build kas/dom0.yml
kas build kas/installer.yml
kas build kas/ndvm.yml
kas build kas/usbvm.yml
kas build kas/syncvm.yml
kas build kas/uivm.yml
```

Recommended order: initramfs and stubdomain before dom0 (dom0 packages
stubdomain artefacts).

## Post-processing (installer ISO)

```bash
export OPENXT_CERTS_DIR="${OPENXT_KAS_WORKSPACE}/certs"
./scripts/stage-repository.sh
./scripts/deploy-iso.sh
```

`OPENXT_IMAGE_ROOTS` (colon-separated) can point at additional
`tmp-glibc/deploy/images` trees. Defaults scan the active `KAS_BUILD_DIR`
and other `build-*/` instances under `OPENXT_KAS_WORKSPACE`.

## Residual notes

- **IVC / vglass:** headless still pulls `meta-qt5` and `meta-vglass` because
  stubdomain IVC recipes live there. Tracked as a layer-split follow-up.
- **Multiconfig:** not enabled; use sequential `kas build` for all images.
- **Refspecs:** dunfell for OE stack; `trixie` for OpenXT ocaml/haskell
  platforms (host GCC 14 fixes).
