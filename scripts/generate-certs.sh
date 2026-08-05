#!/bin/bash
# Generate development signing certificates for OpenXT image builds.
# Writes into OPENXT_CERTS_DIR (default: workspace certs after kas-init-build-env,
# or ${KAS_BUILD_DIR}/certs / build/certs).
set -euo pipefail

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

CERTS="${OPENXT_CERTS_DIR}"
mkdir -p "${CERTS}"
require_cmd openssl

gen_ca() {
	local name="$1"
	local cn="$2"
	local key="${CERTS}/${name}-cakey.pem"
	local cert="${CERTS}/${name}-cacert.pem"
	if [ -f "${cert}" ] && [ -f "${key}" ]; then
		log "reuse existing ${name} CA"
		return 0
	fi
	log "generate ${name} CA (${cn})"
	openssl req -new -x509 -newkey rsa:2048 -nodes -days 3650 \
		-subj "/CN=${cn}/O=OpenXT/C=US" \
		-keyout "${key}" -out "${cert}"
}

gen_ca prod "OpenXT Development Product CA"
gen_ca dev "OpenXT Development Signing CA"

# Kernel module signing key/cert (self-signed)
if [ ! -f "${CERTS}/kernel_cert.pem" ] || [ ! -f "${CERTS}/kernel_key.pem" ]; then
	log "generate kernel module signing key"
	openssl req -new -x509 -newkey rsa:2048 -nodes -days 3650 \
		-subj "/CN=OpenXT Kernel Module Signing/O=OpenXT/C=US" \
		-keyout "${CERTS}/kernel_key.pem" -out "${CERTS}/kernel_cert.pem"
else
	log "reuse existing kernel module signing key"
fi

chmod 600 "${CERTS}"/*key*.pem 2>/dev/null || true
log "certificates ready under ${CERTS}"
ls -la "${CERTS}"
