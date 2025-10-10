#!/bin/bash
set -e

# Define paths
REPO_API_URL="https://api.github.com/repos/bennymeg/Fabrication-Toolkit/releases/latest"
TMP_DIR="/tmp/fabrication_toolkit"
INSTALL_BASE="/root/.local/share/kicad/9.0/3rdparty"
TARGET_SUBFOLDER="com_github_bennymeg_JLC-Plugin-for-KiCad"

# Create temp directory
mkdir -p "$TMP_DIR"

# Get latest release info from GitHub API
echo "Fetching latest release info from GitHub API..."
RELEASE_RESPONSE=$(curl -s "$REPO_API_URL")
if [ $? -ne 0 ] || [ -z "$RELEASE_RESPONSE" ]; then
    echo "❌ Failed to fetch release information from GitHub API"
    exit 1
fi

# Extract version and download URL for the zip file
VERSION=$(echo "$RELEASE_RESPONSE" | grep '"tag_name":' | head -n 1 | cut -d'"' -f4)
DOWNLOAD_URL=$(echo "$RELEASE_RESPONSE" | grep '"browser_download_url":' | grep '\.zip' | head -n 1 | cut -d'"' -f4)

if [ -z "$VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ Could not find version or download URL in release information"
    echo "Response excerpt:"
    echo "$RELEASE_RESPONSE" | head -20
    exit 1
fi

echo "📦 Found latest version: $VERSION"
echo "📦 Download URL: $DOWNLOAD_URL"

# Download and unzip
echo "⬇️  Downloading ZIP file..."
if ! curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/fabrication-toolkit.zip"; then
    echo "❌ Failed to download ZIP file"
    exit 1
fi

echo "📁 Extracting ZIP file..."
if ! unzip -q "$TMP_DIR/fabrication-toolkit.zip" -d "$TMP_DIR"; then
    echo "❌ Failed to extract ZIP file"
    exit 1
fi

# Check if files were extracted directly or in a subfolder
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "Fabrication-Toolkit-*" | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    # Files were extracted directly to TMP_DIR
    EXTRACTED_DIR="$TMP_DIR"
    echo "✅ Files extracted directly to: $EXTRACTED_DIR"
else
    echo "✅ Found extracted folder: $EXTRACTED_DIR"
fi

# Install plugins from the plugins folder
PLUGINS_SRC="$EXTRACTED_DIR/plugins"
PLUGINS_DEST="$INSTALL_BASE/plugins/$TARGET_SUBFOLDER"

if [ -d "$PLUGINS_SRC" ]; then
    mkdir -p "$PLUGINS_DEST"
    cp -r "$PLUGINS_SRC/"* "$PLUGINS_DEST/"
    echo "✅ Installed plugins to $PLUGINS_DEST"
else
    echo "❌ Warning: plugins folder not found in extracted files"
    echo "Available directories:"
    find "$EXTRACTED_DIR" -type d -maxdepth 2
    exit 1
fi

# Cleanup
rm -rf "$TMP_DIR"
echo "🎉 Fabrication Toolkit installed successfully."
