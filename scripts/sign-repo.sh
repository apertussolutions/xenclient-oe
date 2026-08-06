#!/bin/bash
# Sign an OpenXT packages.main repository (XC-REPOSITORY -> XC-SIGNATURE).
# Port of OpenXT/openxt sign_repo.sh for the kas/scripts tree.
set -euo pipefail

usage() {
	cat <<EOF
Usage: $(basename "$0") CERTIFICATE PRIVATE_KEY REPOSITORY_DIR

Signs XC-REPOSITORY with the given certificate/key and writes XC-SIGNATURE.
EOF
}

if [ $# -ne 3 ]; then
	usage
	exit 1
fi

CERTIFICATE="$1"
PRIVATE_KEY="$2"
REPOSITORY_DIR="$3"
REPOSITORY_FILE="${REPOSITORY_DIR}/XC-REPOSITORY"
SIGNATURE_FILE="${REPOSITORY_DIR}/XC-SIGNATURE"

[ -f "${CERTIFICATE}" ] || { echo "missing certificate: ${CERTIFICATE}" >&2; exit 1; }
[ -f "${PRIVATE_KEY}" ] || { echo "missing private key: ${PRIVATE_KEY}" >&2; exit 1; }
[ -f "${REPOSITORY_FILE}" ] || { echo "missing ${REPOSITORY_FILE}" >&2; exit 1; }

PASSPHRASE_ARG=()
if [ -n "${PASSPHRASE:-}" ]; then
	PASSPHRASE_ARG=(-passin env:PASSPHRASE)
fi

openssl smime -sign \
	-aes256 \
	-binary \
	-in "${REPOSITORY_FILE}" \
	-out "${SIGNATURE_FILE}" \
	-outform PEM \
	-signer "${CERTIFICATE}" \
	-inkey "${PRIVATE_KEY}" \
	"${PASSPHRASE_ARG[@]+"${PASSPHRASE_ARG[@]}"}"
