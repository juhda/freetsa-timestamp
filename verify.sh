#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 FILE" >&2
    exit 2
fi

FILE=$1
TSR="${FILE}.tsr"

# Location of the FreeTSA trust material.
CERT_DIR="${FREETSA_CERT_DIR:-$HOME/.config/freetsa}"
CA_CERT="$CERT_DIR/cacert.pem"
TSA_CERT="$CERT_DIR/tsa.crt"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE" >&2
    exit 1
fi

if [[ ! -f "$TSR" ]]; then
    echo "Error: timestamp response not found: $TSR" >&2
    exit 1
fi

if [[ ! -f "$CA_CERT" ]]; then
    echo "Error: FreeTSA CA certificate not found: $CA_CERT" >&2
    echo "Set FREETSA_CERT_DIR or install the FreeTSA certificates." >&2
    exit 1
fi

if [[ ! -f "$TSA_CERT" ]]; then
    echo "Error: FreeTSA TSA certificate not found: $TSA_CERT" >&2
    echo "Set FREETSA_CERT_DIR or install the FreeTSA certificates." >&2
    exit 1
fi

echo "Verifying timestamp..."
echo "  Data:     $FILE"
echo "  Response: $TSR"
echo

if openssl ts \
    -verify \
    -data "$FILE" \
    -in "$TSR" \
    -CAfile "$CA_CERT" \
    -untrusted "$TSA_CERT"
then
    echo
    echo "Timestamp: VALID"
else
    echo
    echo "Timestamp: INVALID"
    exit 1
fi

echo
echo "Certified time:"

openssl ts \
    -reply \
    -in "$TSR" \
    -text |
    sed -n 's/^[[:space:]]*Time stamp:[[:space:]]*//p'
