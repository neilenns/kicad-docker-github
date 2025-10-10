# KiCad Docker images for GitHub workflows

This repo publishes ubuntu-based Docker images to use the KiCad cli tool in GitHub workflows and as a VSCode devcontainer. The following packages are included:

- `gh`: command line GitHub tools for use in workflows to automerge pull requests
- `kicad`: for `kicad-cli`
- `openssh-client`: for GitHub access via SSH
- `sudo`: for VSCode devcontainers
- `zip`: for zipping output to attach to workflow runs or releases

The kicad installation excludes documentation and 3D models to save space. The great [JLCPCB library](https://github.com/CDFER/JLCPCB-Kicad-Library) and [fabrication toolkit plugin](https://github.com/bennymeg/Fabrication-Toolkit) is pre-installed.

Use it like this in a GitHub workflow:

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
