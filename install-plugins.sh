#!/bin/bash
set -e

# Define common paths
INSTALL_BASE="/root/.local/share/kicad/9.0/3rdparty"

# Plugin configurations
# Format: "REPO_OWNER|REPO_NAME|TARGET_SUBFOLDER|EXTRACT_PATTERN|INSTALL_TYPE"
# INSTALL_TYPE: plugins (copy from plugins/ folder) or root (copy from root)
PLUGINS=(
    "bennymeg|Fabrication-Toolkit|com_github_bennymeg_JLC-Plugin-for-KiCad|Fabrication-Toolkit-*|plugins"
    "openscopeproject|InteractiveHtmlBom|com_github_openscopeproject_InteractiveHtmlBom|InteractiveHtmlBom*|root"
)

install_plugin() {
    local REPO_OWNER="$1"
    local REPO_NAME="$2"
    local TARGET_SUBFOLDER="$3"
    local EXTRACT_PATTERN="$4"
    local INSTALL_TYPE="$5"
    
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
    
    # Install plugin based on type
    if [ "$INSTALL_TYPE" = "plugins" ]; then
        # Install plugins from the plugins folder (Fabrication Toolkit style)
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
            return 1
        fi
    elif [ "$INSTALL_TYPE" = "root" ]; then
        # Install from root directory (InteractiveHtmlBom style)
        PLUGINS_DEST="$INSTALL_BASE/plugins/$TARGET_SUBFOLDER"
        mkdir -p "$PLUGINS_DEST"
        
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
        
        echo "✅ Installed plugin to $PLUGINS_DEST"
    fi
    
    # Cleanup
    rm -rf "$TMP_DIR"
    echo "✅ ${REPO_NAME} installed successfully."
    
    return 0
}

# Main execution
echo "🚀 Installing KiCad plugins..."

FAILED_PLUGINS=()

for plugin_config in "${PLUGINS[@]}"; do
    IFS='|' read -r REPO_OWNER REPO_NAME TARGET_SUBFOLDER EXTRACT_PATTERN INSTALL_TYPE <<< "$plugin_config"
    
    if ! install_plugin "$REPO_OWNER" "$REPO_NAME" "$TARGET_SUBFOLDER" "$EXTRACT_PATTERN" "$INSTALL_TYPE"; then
        FAILED_PLUGINS+=("$REPO_NAME")
    fi
done

echo ""
echo "=================================================="
echo "Installation Summary"
echo "=================================================="

if [ ${#FAILED_PLUGINS[@]} -eq 0 ]; then
    echo "🎉 All plugins installed successfully!"
    exit 0
else
    echo "⚠️  Some plugins failed to install:"
    for plugin in "${FAILED_PLUGINS[@]}"; do
        echo "  - $plugin"
    done
    exit 1
fi
