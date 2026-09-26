# FreeTSA Timestamp Utilities

Small Bash utilities for creating and verifying [FreeTSA](https://freetsa.org/) RFC 3161 trusted timestamps using `openssl` and `curl`.

## Files

```text
.
├── create.sh
├── verify.sh
├── init.sh
├── freetsa-certificates.sha256
└── certificates/
    └── YYYY-MM-DD/
        ├── cacert.pem
        └── tsa.crt
```

### `create.sh`

Creates an RFC 3161 timestamp request for a file and submits it to FreeTSA.

Given:

```text
file.ext
```

it creates:

```text
file.ext.tsq
file.ext.tsr
```

The `.tsq` file contains the timestamp request and the `.tsr` file contains the signed timestamp response from FreeTSA.

SHA-512 is used for the timestamp request.

Usage:

```bash
./create.sh file.ext
```

The original file is never modified.

### `verify.sh`

Verifies the timestamp response against the **actual contents of the original file**.

Given:

```text
file.ext
file.ext.tsr
```

it:

1. Verifies that the timestamp response is valid.
2. Verifies that the timestamp corresponds to the current contents of `file.ext`.
3. Validates the FreeTSA certificate chain.
4. Prints the certified timestamp contained in the response.

Usage:

```bash
./verify.sh file.ext
```

A successful verification is reported as:

```text
Verification: OK
Timestamp: VALID
```

The certified time is then displayed separately.

The verification uses the procedure documented by FreeTSA:

```bash
openssl ts -verify \
    -data file.ext \
    -in file.ext.tsr \
    -CAfile cacert.pem \
    -untrusted tsa.crt
```

OpenSSL may print a warning similar to:

```text
Warning: certificate from 'tsa.crt' ... is not a CA cert
```

This is expected. `tsa.crt` is the TSA's signing certificate, not a CA certificate. The warning does **not** indicate a failed timestamp verification. The relevant result is:

```text
Verification: OK
```

### `init.sh`

Downloads the FreeTSA certificates required for verification.

By default, certificates are stored in:

```text
~/.config/freetsa/
```

The location can be overridden with:

```bash
FREETSA_CERT_DIR=/path/to/certificates ./init.sh
```

The script verifies the SHA-256 fingerprints of the downloaded certificates against the values in:

```text
freetsa-certificates.sha256
```

The downloaded certificates are installed only after successful fingerprint verification.

`init.sh` must be run before `verify.sh`.

## Certificate verification

The file:

```text
freetsa-certificates.sha256
```

contains the SHA-256 fingerprints of the FreeTSA certificates published by FreeTSA.

The fingerprints are deliberately maintained separately from the downloaded certificates. `init.sh` does **not** download the fingerprint file from FreeTSA. This avoids obtaining both the certificate and its expected fingerprint from the same source.

When FreeTSA rotates its certificates, the newly published fingerprints should be independently checked and the reference file deliberately updated.

## Certificate verification

The file:

```text
freetsa-certificates.sha256
```

contains the SHA-256 fingerprints of the FreeTSA certificates published by FreeTSA.

The fingerprints are deliberately maintained separately from the downloaded certificates. `init.sh` does **not** download the fingerprint file from FreeTSA. This avoids obtaining both the certificate and its expected fingerprint from the same source.

`init.sh` verifies the downloaded certificates against these reference fingerprints before installing them.

When FreeTSA rotates its certificates, the newly published fingerprints should be independently checked and the reference file deliberately updated.

## Historical certificates

The `certificates/` directory contains historical copies of FreeTSA certificates for long-term reference.

Certificates are organized by their **effective date**, rather than by the date on which they were downloaded:

```text
certificates/
├── 2026-03-16/
│   ├── cacert.pem
│   ├── tsa.crt
│   └── SHA256SUMS
└── YYYY-MM-DD/
    ├── cacert.pem
    ├── tsa.crt
    └── SHA256SUMS
```

Each dated certificate directory contains a `SHA256SUMS` file that records the SHA-256 hashes of the archived certificate files. It can be checked with:

```bash
cd certificates/2026-03-16
sha256sum --check SHA256SUMS
```

The per-directory `SHA256SUMS` file provides an integrity check for the archived certificate files. It is separate from `freetsa-certificates.sha256`, which contains the externally published FreeTSA fingerprints used to authenticate newly downloaded certificates.

Do not replace historical certificate sets with newer versions. When FreeTSA performs a certificate rotation, add a new dated directory.

Keeping the historical certificates makes it possible to independently verify older timestamp responses even after FreeTSA has replaced the certificates currently published on its website.

The historical certificates are **reference material** and are not used automatically by `verify.sh`. The active certificates used by `verify.sh` are those in `FREETSA_CERT_DIR`, or `~/.config/freetsa/` when the variable is not set.

## Timestamp archive

For an audit trail, preserve the original file together with its timestamp request and response:

```text
file.ext
file.ext.tsq
file.ext.tsr
```

The `.tsr` is the important signed timestamp evidence. It contains the TSA's signed assertion of the hash of the original data and the certified time.

The `.tsq` records the original timestamp request and is useful for completeness and inspection.

The original file must remain unchanged. Verification calculates the hash from the current file contents and compares it with the message imprint contained in the `.tsr`.

For long-term audit archives, it is also recommended to retain the exact FreeTSA certificate set used to verify the timestamp response.

## Typical workflow

### 1. Initialize verification certificates

Run once before the first verification:

```bash
./init.sh
```

### 2. Create a timestamp

```bash
./create.sh document.pdf
```

This produces:

```text
document.pdf
document.pdf.tsq
document.pdf.tsr
```

### 3. Verify the timestamp

```bash
./verify.sh document.pdf
```

### 4. Preserve the evidence

Keep the following together:

```text
document.pdf
document.pdf.tsq
document.pdf.tsr
```

For long-term archival, also retain the relevant FreeTSA certificate set under `certificates/YYYY-MM-DD/`.

## Requirements

The scripts require:

* Bash
* OpenSSL with RFC 3161 timestamp support
* `curl`
* `sha256sum`
* Internet access when creating timestamps or initializing the verification certificates

## FreeTSA

FreeTSA provides a public RFC 3161 Time Stamp Authority:

https://freetsa.org/

The FreeTSA documentation describes the OpenSSL timestamping and verification procedures used by these scripts.
