# KiCad Settings Configuration

This Docker image includes a flexible system for configuring KiCad settings during the build process.

## Overview

KiCad settings are stored in `~/.config/kicad/9.0/kicad_common.json`. The Docker build process applies custom settings from `kicad-settings-overrides.json` using the `configure-kicad-settings.sh` script.

## Adding or Modifying Settings

To add or modify KiCad settings, edit the `kicad-settings-overrides.json` file. The settings use a JSON merge strategy, so you only need to specify the values you want to override.

### How It Works

1. The `configure-kicad-settings.sh` script reads the existing `kicad_common.json` file (or creates an empty one if it doesn't exist)
2. It uses `jq` to deep-merge the settings from `kicad-settings-overrides.json`
3. Only the specified settings are overridden; all other settings retain their default values
4. The merge preserves the structure of nested objects
