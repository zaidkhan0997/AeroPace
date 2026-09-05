#!/usr/bin/env bash
##########################################################################################
# AeroPace Performance Engine - Build & Packaging Script
# Universal Flashable ZIP Generator
##########################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================================"
echo "          AeroPace Build & Packaging System             "
echo "========================================================"

# Extract version from module.prop
if [ ! -f "module.prop" ]; then
    echo "[-] Error: module.prop not found in current directory!"
    exit 1
fi

VERSION=$(grep -E '^version=' module.prop | cut -d'=' -f2 | tr -d '\r\n')
VERSION_CODE=$(grep -E '^versionCode=' module.prop | cut -d'=' -f2 | tr -d '\r\n')

if [ -z "$VERSION" ]; then
    VERSION="v1.0.0"
fi

ZIP_NAME="AeroPace-${VERSION}.zip"
OUT_DIR="$SCRIPT_DIR/out"

echo "[*] Preparing build for AeroPace $VERSION (Code: ${VERSION_CODE:-unknown})"
mkdir -p "$OUT_DIR"

# Enforce proper execution permissions
echo "[*] Normalizing file permissions..."
chmod 755 service.sh customize.sh build.sh 2>/dev/null || true
chmod 755 META-INF/com/google/android/update-binary 2>/dev/null || true
chmod 644 module.prop system.prop update.json changelog.md README.md 2>/dev/null || true
chmod 644 META-INF/com/google/android/updater-script 2>/dev/null || true

# Check and convert CRLF to LF if dos2unix or sed is available
echo "[*] Verifying UNIX line endings (LF)..."
for file in service.sh customize.sh module.prop system.prop update.json META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script; do
    if [ -f "$file" ]; then
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix -q "$file" 2>/dev/null || true
        else
            sed -i 's/\r$//' "$file" 2>/dev/null || true
        fi
    fi
done

# Clean previous build artifacts
rm -f "$OUT_DIR/$ZIP_NAME" "$OUT_DIR/${ZIP_NAME}.sha256"
rm -f "$SCRIPT_DIR/$ZIP_NAME" "$SCRIPT_DIR/${ZIP_NAME}.sha256"

# Package module contents
echo "[*] Compiling flashable module package: $ZIP_NAME ..."
zip -r9 "$OUT_DIR/$ZIP_NAME" \
    module.prop \
    system.prop \
    service.sh \
    customize.sh \
    update.json \
    changelog.md \
    README.md \
    META-INF/ \
    -x "*.git*" \
    -x "*out/*" \
    -x "*.DS_Store*" \
    -x "*Thumbs.db*" \
    -x "*.bak" \
    -x "*.tmp"

# Generate SHA-256 Checksum
echo "[*] Generating SHA-256 checksum..."
if command -v sha256sum >/dev/null 2>&1; then
    (cd "$OUT_DIR" && sha256sum "$ZIP_NAME" > "${ZIP_NAME}.sha256")
    SHA=$(cat "$OUT_DIR/${ZIP_NAME}.sha256" | awk '{print $1}')
    echo "[+] SHA-256: $SHA"
fi

echo "========================================================"
echo "[+] Build complete!"
echo "    Artifact : $OUT_DIR/$ZIP_NAME"
echo "    Checksum : $OUT_DIR/${ZIP_NAME}.sha256"
echo "========================================================"
