#!/usr/bin/env bash

# FreeTSA RFC 3161 timestamping utilities
#
# This directory contains three scripts and one certificate reference file
# for creating and verifying trusted timestamps using FreeTSA.org:
#
#   timestamp.sh
#       Creates an RFC 3161 timestamp request (.tsq) for the specified file
#       and submits it to FreeTSA, producing a timestamp response (.tsr).
#
#       For example:
#
#           file.ext
#           file.ext.tsq
#           file.ext.tsr
#
#       SHA-512 is used for the timestamp request.
#
#   timestamp-init.sh
#       Downloads the FreeTSA CA and TSA certificates required for local
#       verification and verifies their SHA-256 fingerprints against the
#       independently maintained reference file:
#
#           freetsa-certificates.sha256
#
#       By default, certificates are stored in:
#
#           ~/.config/freetsa/
#
#       The certificate directory can be overridden with the
#       FREETSA_CERT_DIR environment variable.
#
#       The downloaded certificates are installed only after their
#       fingerprints have been successfully verified.
#
#       timestamp-init.sh must be run before timestamp-verify.sh.
#
#   timestamp-verify.sh
#       Verifies the .tsr response against the actual contents of the
#       specified file and validates the FreeTSA certificate chain. It also
#       displays the certified timestamp contained in the response.
#
#       The certificate directory defaults to ~/.config/freetsa/ and can be
#       overridden with FREETSA_CERT_DIR.
#
#       Verification follows the procedure documented by FreeTSA:
#
#           openssl ts -verify \
#               -data FILE \
#               -in FILE.tsr \
#               -CAfile cacert.pem \
#               -untrusted tsa.crt
#
#       OpenSSL may print a warning that tsa.crt "is not a CA cert".
#       This is expected: tsa.crt is the TSA's signing certificate, not a
#       CA certificate. The warning is not an indication of a failed
#       timestamp verification. A successful verification is indicated by:
#
#           Verification: OK
#
#   freetsa-certificates.sha256
#       Contains the SHA-256 fingerprints of the FreeTSA certificates
#       published by FreeTSA.org. This file is deliberately maintained
#       separately from the downloaded certificates rather than being
#       downloaded by timestamp-init.sh.
#
#       This provides an independent reference against which the downloaded
#       certificates can be checked. When FreeTSA rotates its certificates,
#       this file must be deliberately updated to the newly published
#       fingerprints.
#
# Timestamp evidence
# ------------------
#
# The original file, its .tsq request and its .tsr response should be
# preserved together:
#
#       file.ext
#       file.ext.tsq
#       file.ext.tsr
#
# The .tsr contains the TSA's signed assertion of the file's hash and the
# certified time. The .tsq records the original timestamp request.
#
# For long-term audit archives, the exact FreeTSA certificates used for
# verification may also be retained as reference material. They are not
# part of the timestamp evidence itself.
#
# FreeTSA documentation:
#   https://freetsa.org/index_en.php
#
# FreeTSA currently documents RFC 3161 timestamping with OpenSSL and
# provides the SHA-256 fingerprints of its TSA and CA certificates.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 FILE" >&2
    exit 2
fi

FILE=$1
TSQ="${FILE}.tsq"
TSR="${FILE}.tsr"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE" >&2
    exit 1
fi

if [[ -e "$TSQ" || -e "$TSR" ]]; then
    echo "Error: timestamp files already exist:" >&2
    [[ -e "$TSQ" ]] && echo "  $TSQ" >&2
    [[ -e "$TSR" ]] && echo "  $TSR" >&2
    echo "Refusing to overwrite." >&2
    exit 1
fi

echo "Creating timestamp request..."
openssl ts \
    -query \
    -data "$FILE" \
    -no_nonce \
    -sha512 \
    -cert \
    -out "$TSQ"

echo "Submitting request to FreeTSA..."
curl --fail --silent --show-error \
    -H "Content-Type: application/timestamp-query" \
    --data-binary "@$TSQ" \
    "https://freetsa.org/tsr" \
    > "$TSR"

echo
echo "Timestamp created:"
echo "  Data:     $FILE"
echo "  Request:  $TSQ"
echo "  Response: $TSR"
