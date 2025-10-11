# KiCad Settings Configuration

This Docker image includes a flexible system for configuring KiCad settings during the build process.

## Overview

KiCad settings are stored in `~/.config/kicad/9.0/kicad_common.json`. The Docker build process applies custom settings from `kicad-settings-overrides.json` using the `configure-kicad-settings.sh` script.

## Current Settings

The following settings are currently configured:

- **Auto-backup disabled**: `auto_backup.enabled = false`
  - This prevents KiCad from creating automatic backup files, which is ideal for CI/CD environments where backups are unnecessary.

## Adding or Modifying Settings

To add or modify KiCad settings, edit the `kicad-settings-overrides.json` file. The settings use a JSON merge strategy, so you only need to specify the values you want to override.

### Example: Adding Multiple Settings

```json
{
  "auto_backup": {
    "enabled": false,
    "min_interval": 600
  },
  "environment": {
    "show_warning_dialog": false
  }
}
```

### How It Works

1. The `configure-kicad-settings.sh` script reads the existing `kicad_common.json` file (or creates an empty one if it doesn't exist)
2. It uses `jq` to deep-merge the settings from `kicad-settings-overrides.json`
3. Only the specified settings are overridden; all other settings retain their default values
4. The merge preserves the structure of nested objects

### Example Merge Behavior

**Original config:**
```json
{
  "auto_backup": {
    "backup_on_autosave": true,
    "enabled": true,
    "limit_daily_files": 5,
    "limit_total_files": 25
  }
}
```

**Override file:**
```json
{
  "auto_backup": {
    "enabled": false
  }
}
```

**Result:**
```json
{
  "auto_backup": {
    "backup_on_autosave": true,
    "enabled": false,
    "limit_daily_files": 5,
    "limit_total_files": 25
  }
}
```

Notice that only `enabled` was changed; all other settings in `auto_backup` remained intact.

## Available Settings

KiCad's `kicad_common.json` file contains many configurable options. To see all available settings:

1. Run KiCad with the GUI
2. Configure your desired settings through the UI
3. Check `~/.config/kicad/9.0/kicad_common.json` to see what changed
4. Add those settings to `kicad-settings-overrides.json`

## Building with Custom Settings

After modifying `kicad-settings-overrides.json`, rebuild the Docker image:

```bash
docker build -f DOCKERFILE-9.0-stable -t my-kicad:latest .
```

The settings will be applied during the build process, right after KiCad and the plugins are installed.
