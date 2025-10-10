#!/bin/bash
set -e

# Define paths
PACKAGES_URL="https://raw.githubusercontent.com/CDFER/cd_fer-kicad-repository/main/packages.json"
TMP_DIR="/tmp/jlcpcb_lib"
INSTALL_BASE="/root/.local/share/kicad/9.0/3rdparty"
TARGET_SUBFOLDER="com_github_CDFER_JLCPCB-Kicad-Library"

# Create temp directory
mkdir -p "$TMP_DIR"

# Get stable version info from packages.json
echo "Fetching stable version info from packages.json..."
PACKAGES_RESPONSE=$(curl -s "$PACKAGES_URL")
if [ $? -ne 0 ] || [ -z "$PACKAGES_RESPONSE" ]; then
    echo "❌ Failed to fetch packages.json"
    exit 1
fi

# Extract the most recent stable version download URL and version (first stable version in the list)
STABLE_VERSION=$(echo "$PACKAGES_RESPONSE" | grep -A 10 -B 2 '"status": "stable"' | grep '"version":' | head -n 1 | cut -d'"' -f4)
FULL_URL=$(echo "$PACKAGES_RESPONSE" | grep -A 10 -B 2 '"status": "stable"' | grep '"download_url":' | head -n 1 | cut -d'"' -f4)
if [ -z "$FULL_URL" ] || [ -z "$STABLE_VERSION" ]; then
    echo "❌ Could not find stable version download URL in packages.json"
    echo "Response excerpt:"
    echo "$PACKAGES_RESPONSE" | head -20
    exit 1
fi

echo "📦 Found stable version: $STABLE_VERSION"
echo "📦 Download URL: $FULL_URL"

# Download and unzip
echo "⬇️  Downloading ZIP file..."
if ! curl -L "$FULL_URL" -o "$TMP_DIR/lib.zip"; then
    echo "❌ Failed to download ZIP file"
    exit 1
fi

echo "📁 Extracting ZIP file..."
if ! unzip -q "$TMP_DIR/lib.zip" -d "$TMP_DIR"; then
    echo "❌ Failed to extract ZIP file"
    exit 1
fi

# Check if files were extracted directly or in a subfolder
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "JLCPCB-KiCad-Library-*" | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    # Files were extracted directly to TMP_DIR
    EXTRACTED_DIR="$TMP_DIR"
    echo "✅ Files extracted directly to: $EXTRACTED_DIR"
else
    echo "✅ Found extracted folder: $EXTRACTED_DIR"
fi

# Install assets
for TYPE in 3dmodels footprints resources symbols; do
  SRC="$EXTRACTED_DIR/$TYPE"
  DEST="$INSTALL_BASE/$TYPE/$TARGET_SUBFOLDER"
  if [ -d "$SRC" ]; then
    mkdir -p "$DEST"
    cp -r "$SRC/"* "$DEST/"
    echo "Installed $TYPE to $DEST"
  else
    echo "Warning: $TYPE folder not found"
  fi
done

# Cleanup
rm -rf "$TMP_DIR"
echo "🎉 JLCPCB KiCad library installed and registered."
