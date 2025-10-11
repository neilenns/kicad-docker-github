# KiCad Docker images for GitHub workflows

This repo publishes ubuntu-based Docker images to use the KiCad cli tool in GitHub workflows and as a VSCode devcontainer. The following packages are included:

- `gh`: command line GitHub tools for use in workflows to automerge pull requests
- `kicad`: for `kicad-cli`
- `openssh-client`: for GitHub access via SSH
- `sudo`: for VSCode devcontainers
- `zip`: for zipping output to attach to workflow runs or releases

The kicad installation excludes documentation and 3D models to save space. The great [JLCPCB library](https://github.com/CDFER/JLCPCB-Kicad-Library), [fabrication toolkit plugin](https://github.com/bennymeg/Fabrication-Toolkit), and [Interactive HTML BOM plugin](https://github.com/openscopeproject/InteractiveHtmlBom) are pre-installed.

## KiCad Configuration

The Docker image includes custom KiCad settings configured during the build process. By default, the following settings are applied:

- **Auto-backup disabled**: The automatic backup feature is disabled to avoid unnecessary file generation in CI/CD environments.

These settings are stored in `~/.config/kicad/9.0/kicad_common.json` and are configured via the `kicad-settings-overrides.json` file. To modify or add additional settings, edit the `kicad-settings-overrides.json` file before building the Docker image. The settings use JSON merge, so only the specified values are overridden while all other settings retain their defaults.

## Using from a template

This image is used as the base for my KiCad 9.0 project template that has full release automation for submitting designs to JLCPCB. See the [project template repo](https://github.com/neilenns/KiCad9-CICD-template) for information on how to use it.

## Using directly in a GitHub workflow

```yaml
name: CI

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    container: ghcr.io/neilenns/kicad:latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Run kicad-cli ERC
        run: |
          kicad-cli sch erc dm13a-breakout-board.kicad_sch

      - name: Run kicad-cli DRC
        run: |
          kicad-cli pcb drc dm13a-breakout-board.kicad_pcb

      - name: Attach reports
        uses: actions/upload-artifact@v4
        with:
          name: report
          path: "*.rpt"
```

## Updating the JLCPCB library

To update the JLCPCB library run:

```bash
install-jlcpcb.sh
```
