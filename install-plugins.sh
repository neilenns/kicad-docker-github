#!/bin/bash
set -e

# Define common paths
INSTALL_BASE="/root/.local/share/kicad/9.0/3rdparty"

# Plugin configurations
# Format: "REPO_OWNER|REPO_NAME|TARGET_SUBFOLDER|EXTRACT_PATTERN"
PLUGINS=(
    "bennymeg|Fabrication-Toolkit|com_github_bennymeg_JLC-Plugin-for-KiCad|Fabrication-Toolkit-*"
    "openscopeproject|InteractiveHtmlBom|org_openscopeproject_InteractiveHtmlBom|InteractiveHtmlBom*"
)

# Library configurations for JLCPCB-style installations
# Format: "PACKAGES_URL|TARGET_SUBFOLDER|EXTRACT_PATTERN"
LIBRARIES=(
    "https://raw.githubusercontent.com/CDFER/cd_fer-kicad-repository/main/packages.json|com_github_CDFER_JLCPCB-Kicad-Library|JLCPCB-KiCad-Library-*"
)

install_plugin() {
    local REPO_OWNER="$1"
    local REPO_NAME="$2"
    local TARGET_SUBFOLDER="$3"
    local EXTRACT_PATTERN="$4"
    
    REPO_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    TMP_DIR="/tmp/plugin_${REPO_NAME}"
    
    echo ""
    echo "=================================================="
    echo "Installing ${REPO_NAME}..."
    echo "=================================================="
    
    # Create temp directory
    mkdir -p "$TMP_DIR"
    
    # Get latest release info from GitHub API
    echo "Fetching latest release info from GitHub API..."
    RELEASE_RESPONSE=$(curl -s "$REPO_API_URL")
    if [ $? -ne 0 ] || [ -z "$RELEASE_RESPONSE" ]; then
        echo "❌ Failed to fetch release information from GitHub API"
        return 1
    fi
    
    # Extract version and download URL for the zip file
    VERSION=$(echo "$RELEASE_RESPONSE" | grep '"tag_name":' | head -n 1 | cut -d'"' -f4)
    DOWNLOAD_URL=$(echo "$RELEASE_RESPONSE" | grep '"browser_download_url":' | grep '\.zip' | head -n 1 | cut -d'"' -f4)
    
    if [ -z "$VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
        echo "❌ Could not find version or download URL in release information"
        echo "Response excerpt:"
        echo "$RELEASE_RESPONSE" | head -20
        return 1
    fi
    
    echo "📦 Found latest version: $VERSION"
    echo "📦 Download URL: $DOWNLOAD_URL"
    
    # Download and unzip
    echo "⬇️  Downloading ZIP file..."
    if ! curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/plugin.zip"; then
        echo "❌ Failed to download ZIP file"
        return 1
    fi
    
    echo "📁 Extracting ZIP file..."
    if ! unzip -q "$TMP_DIR/plugin.zip" -d "$TMP_DIR"; then
        echo "❌ Failed to extract ZIP file"
        return 1
    fi
    
    # Check if files were extracted directly or in a subfolder
    EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "$EXTRACT_PATTERN" | head -1)
    if [ -z "$EXTRACTED_DIR" ]; then
        # Files were extracted directly to TMP_DIR
        EXTRACTED_DIR="$TMP_DIR"
        echo "✅ Files extracted directly to: $EXTRACTED_DIR"
    else
        echo "✅ Found extracted folder: $EXTRACTED_DIR"
    fi
    
    # Install plugin - try plugins folder first, then root
    PLUGINS_DEST="$INSTALL_BASE/plugins/$TARGET_SUBFOLDER"
    mkdir -p "$PLUGINS_DEST"
    
    # Check if there's a plugins subdirectory
    PLUGINS_SRC="$EXTRACTED_DIR/plugins"
    if [ -d "$PLUGINS_SRC" ]; then
        # Copy from plugins folder (Fabrication Toolkit style)
        cp -r "$PLUGINS_SRC/"* "$PLUGINS_DEST/"
        echo "✅ Installed plugins from plugins/ folder to $PLUGINS_DEST"
    else
        # Copy from root directory (InteractiveHtmlBom style)
        # Copy all relevant files (skip common metadata files)
        find "$EXTRACTED_DIR" -maxdepth 1 -type f \( -name "*.py" -o -name "*.json" -o -name "*.md" -o -name "*.txt" \) -exec cp {} "$PLUGINS_DEST/" \;
        
        # Copy any subdirectories that might contain plugin code
        for dir in "$EXTRACTED_DIR"/*/ ; do
            if [ -d "$dir" ]; then
                dirname=$(basename "$dir")
                # Skip common metadata directories
                if [ "$dirname" != ".git" ] && [ "$dirname" != ".github" ]; then
                    cp -r "$dir" "$PLUGINS_DEST/"
                fi
            fi
        done
        
        echo "✅ Installed plugin from root directory to $PLUGINS_DEST"
    fi
    
    # Cleanup
    rm -rf "$TMP_DIR"
    echo "✅ ${REPO_NAME} installed successfully."
    
    return 0
}

install_library() {
    local PACKAGES_URL="$1"
    local TARGET_SUBFOLDER="$2"
    local EXTRACT_PATTERN="$3"
    
    local LIB_NAME=$(echo "$TARGET_SUBFOLDER" | cut -d'_' -f4-)
    TMP_DIR="/tmp/library_${LIB_NAME}"
    
    echo ""
    echo "=================================================="
    echo "Installing ${LIB_NAME} library..."
    echo "=================================================="
    
    # Create temp directory
    mkdir -p "$TMP_DIR"
    
    # Get stable version info from packages.json
    echo "Fetching stable version info from packages.json..."
    PACKAGES_RESPONSE=$(curl -s "$PACKAGES_URL")
    if [ $? -ne 0 ] || [ -z "$PACKAGES_RESPONSE" ]; then
        echo "❌ Failed to fetch packages.json"
        return 1
    fi
    
    # Extract the most recent stable version download URL and version
    STABLE_VERSION=$(echo "$PACKAGES_RESPONSE" | grep -A 10 -B 2 '"status": "stable"' | grep '"version":' | head -n 1 | cut -d'"' -f4)
    DOWNLOAD_URL=$(echo "$PACKAGES_RESPONSE" | grep -A 10 -B 2 '"status": "stable"' | grep '"download_url":' | head -n 1 | cut -d'"' -f4)
    
    if [ -z "$DOWNLOAD_URL" ] || [ -z "$STABLE_VERSION" ]; then
        echo "❌ Could not find stable version download URL in packages.json"
        echo "Response excerpt:"
        echo "$PACKAGES_RESPONSE" | head -20
        return 1
    fi
    
    echo "📦 Found stable version: $STABLE_VERSION"
    echo "📦 Download URL: $DOWNLOAD_URL"
    
    # Download and unzip
    echo "⬇️  Downloading ZIP file..."
    if ! curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/lib.zip"; then
        echo "❌ Failed to download ZIP file"
        return 1
    fi
    
    echo "📁 Extracting ZIP file..."
    if ! unzip -q "$TMP_DIR/lib.zip" -d "$TMP_DIR"; then
        echo "❌ Failed to extract ZIP file"
        return 1
    fi
    
    # Check if files were extracted directly or in a subfolder
    EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "$EXTRACT_PATTERN" | head -1)
    if [ -z "$EXTRACTED_DIR" ]; then
        # Files were extracted directly to TMP_DIR
        EXTRACTED_DIR="$TMP_DIR"
        echo "✅ Files extracted directly to: $EXTRACTED_DIR"
    else
        echo "✅ Found extracted folder: $EXTRACTED_DIR"
    fi
    
    # Install library assets (3dmodels, footprints, resources, symbols)
    for TYPE in 3dmodels footprints resources symbols; do
        SRC="$EXTRACTED_DIR/$TYPE"
        DEST="$INSTALL_BASE/$TYPE/$TARGET_SUBFOLDER"
        if [ -d "$SRC" ]; then
            mkdir -p "$DEST"
            cp -r "$SRC/"* "$DEST/"
            echo "✅ Installed $TYPE to $DEST"
        else
            echo "⚠️  Warning: $TYPE folder not found"
        fi
    done
    
    # Cleanup
    rm -rf "$TMP_DIR"
    echo "✅ ${LIB_NAME} library installed successfully."
    
    return 0
}

# Main execution
echo "🚀 Installing KiCad plugins and libraries..."

FAILED_PLUGINS=()
FAILED_LIBRARIES=()

# Install libraries first
for library_config in "${LIBRARIES[@]}"; do
    IFS='|' read -r PACKAGES_URL TARGET_SUBFOLDER EXTRACT_PATTERN <<< "$library_config"
    
    if ! install_library "$PACKAGES_URL" "$TARGET_SUBFOLDER" "$EXTRACT_PATTERN"; then
        FAILED_LIBRARIES+=("$TARGET_SUBFOLDER")
    fi
done

# Install plugins
for plugin_config in "${PLUGINS[@]}"; do
    IFS='|' read -r REPO_OWNER REPO_NAME TARGET_SUBFOLDER EXTRACT_PATTERN <<< "$plugin_config"
    
    if ! install_plugin "$REPO_OWNER" "$REPO_NAME" "$TARGET_SUBFOLDER" "$EXTRACT_PATTERN"; then
        FAILED_PLUGINS+=("$REPO_NAME")
    fi
done

echo ""
echo "=================================================="
echo "Installation Summary"
echo "=================================================="

TOTAL_FAILED=$((${#FAILED_LIBRARIES[@]} + ${#FAILED_PLUGINS[@]}))

if [ $TOTAL_FAILED -eq 0 ]; then
    echo "🎉 All plugins and libraries installed successfully!"
    exit 0
else
    if [ ${#FAILED_LIBRARIES[@]} -gt 0 ]; then
        echo "⚠️  Some libraries failed to install:"
        for library in "${FAILED_LIBRARIES[@]}"; do
            echo "  - $library"
        done
    fi
    if [ ${#FAILED_PLUGINS[@]} -gt 0 ]; then
        echo "⚠️  Some plugins failed to install:"
        for plugin in "${FAILED_PLUGINS[@]}"; do
            echo "  - $plugin"
        done
    fi
    exit 1
fi
