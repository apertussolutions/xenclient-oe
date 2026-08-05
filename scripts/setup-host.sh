#!/bin/bash
# Install host packages for OpenXT / kas builds (Ubuntu 22.04, Debian 12/13).
# Native host is the primary path; Docker is optional and out of scope here.
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log "OpenXT host setup (repo=${OPENXT_ROOT})"

if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
	SUDO=sudo
else
	SUDO=
fi

if ! command -v apt-get >/dev/null 2>&1; then
	die "this script currently supports apt-based distros only"
fi

# Core OE + kas toolchain (aligned with Yocto Dunfell host requirements).
PKGS=(
	gawk wget git diffstat unzip texinfo gcc build-essential chrpath
	socat cpio python3 python3-pip python3-pexpect xz-utils debianutils
	iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev
	pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool
	file locales ca-certificates curl rsync
	# ISO / deploy helpers
	xorriso syslinux-utils mtools
	# Certs
	openssl
	# cmake (also available via ASSUME_PROVIDED + hosttools-prefix)
	cmake
)

log "Installing packages: ${PKGS[*]}"
$SUDO apt-get update
$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "${PKGS[@]}"

# kas via pip (user install if not root)
if ! command -v kas >/dev/null 2>&1; then
	log "Installing kas via pip"
	python3 -m pip install --user 'kas>=4.0'
	log "Ensure ~/.local/bin is on PATH"
fi

log "Host setup complete. Next:"
log "  ./scripts/generate-certs.sh"
log "  kas build kas/dom0.yml"
