#!/usr/bin/env bash
set -euo pipefail

# Creates a reusable self-signed code-signing certificate in the login keychain
# so local YrMenuBar dev builds get a *stable* signing identity. With a stable
# identity, macOS keeps location (and other TCC) permissions across rebuilds —
# unlike ad-hoc signing, whose cdhash changes every build and resets grants.
#
# Run once:
#   ./scripts/make-signing-cert.sh
# Then build signed:
#   CODESIGN_IDENTITY="YrMenuBar Self-Signed" ./scripts/build-app.sh

CERT_NAME="${1:-YrMenuBar Self-Signed}"

if security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
    echo "Certificate '$CERT_NAME' already exists. Nothing to do."
    echo "Build with: CODESIGN_IDENTITY=\"$CERT_NAME\" ./scripts/build-app.sh"
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A code-signing certificate needs the Code Signing EKU (1.3.6.1.5.5.7.3.3).
cat > "$TMP/cert.conf" <<EOF
[ req ]
distinguished_name = dn
x509_extensions = v3
prompt = no
[ dn ]
CN = $CERT_NAME
[ v3 ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

echo "==> Generating self-signed code-signing certificate '$CERT_NAME'"
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -days 3650 -config "$TMP/cert.conf" >/dev/null 2>&1

# Apple's Security framework cannot import PKCS#12 files that use OpenSSL 3's
# default AES-256 PBE. Force the legacy SHA1/3DES algorithms (and add -legacy
# when the installed OpenSSL supports it) and use a non-empty password.
P12_PASS="yrmenubar"
LEGACY_FLAG=""
if openssl pkcs12 -help 2>&1 | grep -q -- "-legacy"; then
    LEGACY_FLAG="-legacy"
fi
openssl pkcs12 -export $LEGACY_FLAG \
    -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/cert.p12" -passout "pass:$P12_PASS" -name "$CERT_NAME" \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 >/dev/null 2>&1

KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
# Import and allow codesign to use the key without an interactive prompt.
security import "$TMP/cert.p12" -k "$KEYCHAIN" -P "$P12_PASS" \
    -T /usr/bin/codesign -A >/dev/null

# Authorize codesign to use the private key non-interactively. Without this,
# macOS prompts for the keychain password the first time codesign touches the
# key. This requires the login keychain password; if it is not the default
# empty string the user is asked once here instead of on every build.
security set-key-partition-list -S apple-tool:,apple: -s \
    -k "" "$KEYCHAIN" >/dev/null 2>&1 || \
    security set-key-partition-list -S apple-tool:,apple: -s "$KEYCHAIN" >/dev/null 2>&1 || \
    echo "note: could not preset key ACL; click 'Always Allow' if codesign prompts once."

# Trust the cert for code signing so the signature is valid locally.
echo "==> Adding to trust settings (you may be asked for your login password)"
security add-trusted-cert -d -r trustRoot \
    -p codeSign -k "$KEYCHAIN" "$TMP/cert.pem" 2>/dev/null || \
    echo "warning: could not set trust automatically; codesign will still work for local runs"

echo
echo "Done. Build signed with a stable identity using:"
echo "  CODESIGN_IDENTITY=\"$CERT_NAME\" ./scripts/build-app.sh"
