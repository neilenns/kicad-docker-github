#!/bin/bash
set -e

# Script to configure KiCad settings by merging JSON overrides
# This allows customizing KiCad settings during Docker image build

OVERRIDES_FILE="$1"
CONFIG_FILE="$2"

echo "=================================================="
echo "Configuring settings..."
echo "=================================================="
echo "Config file: ${CONFIG_FILE}"
echo "Overrides file: ${OVERRIDES_FILE}"

# Check if both parameters are provided
if [ -z "$OVERRIDES_FILE" ] || [ -z "$CONFIG_FILE" ]; then
    echo "❌ Error: Both overrides file and config file must be specified"
    echo "Usage: $0 <overrides-file.json> <config-file.json>"
    exit 1
fi

if [ ! -f "$OVERRIDES_FILE" ]; then
    echo "❌ Error: Overrides file not found: $OVERRIDES_FILE"
    exit 1
fi

# Ensure config directory exists
CONFIG_DIR=$(dirname "$CONFIG_FILE")
mkdir -p "$CONFIG_DIR"

# If config file doesn't exist, create it with an empty JSON object
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 Config file doesn't exist, creating initial file..."
    echo '{}' > "$CONFIG_FILE"
fi

# Use jq to deep merge the overrides into the existing config
# The --slurpfile reads the overrides and . + $overrides performs the merge
echo "🔄 Applying settings overrides..."
TEMP_FILE=$(mktemp)
jq --slurpfile overrides "$OVERRIDES_FILE" '. * $overrides[0]' "$CONFIG_FILE" > "$TEMP_FILE"

# Verify the output is valid JSON
if jq empty "$TEMP_FILE" 2>/dev/null; then
    mv "$TEMP_FILE" "$CONFIG_FILE"
    echo "✅ Successfully applied settings overrides"
    
    # Show what was configured
    echo ""
    echo "Applied settings:"
    jq . "$OVERRIDES_FILE"
else
    echo "❌ Error: Generated invalid JSON"
    rm "$TEMP_FILE"
    exit 1
fi

echo "=================================================="
echo "Settings configuration complete!"
echo "=================================================="
