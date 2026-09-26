#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="${FREETSA_CERT_DIR:-$HOME/.config/freetsa}"

BASE_URL="https://freetsa.org/files"

CA_CERT="cacert.pem"
TSA_CERT="tsa.crt"
CHECKSUMS="$SCRIPT_DIR/freetsa-certificates.sha256"

mkdir -p "$CERT_DIR"

CA_TMP="$CERT_DIR/.${CA_CERT}.tmp"
TSA_TMP="$CERT_DIR/.${TSA_CERT}.tmp"

cleanup() {
    rm -f "$CA_TMP" "$TSA_TMP"
}

trap cleanup EXIT

echo "Downloading FreeTSA CA certificate..."
curl --fail --silent --show-error \
    "$BASE_URL/$CA_CERT" \
    -o "$CA_TMP"

echo "Downloading FreeTSA TSA certificate..."
curl --fail --silent --show-error \
    "$BASE_URL/$TSA_CERT" \
    -o "$TSA_TMP"

echo "Verifying certificate fingerprints..."

# Verify the downloaded certificates against the fingerprints published
# separately by FreeTSA and stored in freetsa-certificates.sha256.

(
    cd "$CERT_DIR"

    sha256sum --check --strict "$CHECKSUMS" \
        --ignore-missing
)

# Make the verified certificates available only after successful verification.
mv "$CA_TMP" "$CERT_DIR/$CA_CERT"
mv "$TSA_TMP" "$CERT_DIR/$TSA_CERT"

echo
echo "FreeTSA certificates installed successfully:"
echo "  CA:  $CERT_DIR/$CA_CERT"
echo "  TSA: $CERT_DIR/$TSA_CERT"
echo
echo "Certificate fingerprint verification: OK"
