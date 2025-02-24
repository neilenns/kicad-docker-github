# KiCad Docker images for GitHub workflows

This repo publishes ubuntu-based Docker images to use the KiCad cli tool in GitHub workflows.

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
