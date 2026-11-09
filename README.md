[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23950821.svg)](https://doi.org/10.5281/zenodo.23950821)
[![License: CC BY 4.0](https://img.shields.io/badge/license-CC%20BY%204.0-lightgrey)](LICENSE)
![Quarto](https://img.shields.io/badge/docs-Quarto-informational)

# Protocol Library

This repository contains **standardised experimental protocols**, **buffer recipes**, and related **analysis SOPs**, written in [Quarto](https://quarto.org/).

All documents follow a common naming and identifier scheme defined in `naming_guide.qmd`:

- Stable `protocol_id` (e.g. `MUS-LCMV-PROD-001`)
- Versioned via YAML `version: "vX.Y"`

Protocols and buffers are intended to be:

- **Version-controlled** (git + GitHub)
- **Human-readable** (Markdown/Quarto)
- **Rendered** to PDF/HTML for internal use and GitHub Pages publication

---

## Repository Structure

- `protocols_src/`
  - `mouse/`, `human/`, `general/` – protocols (`prot_<scope>_<name>.qmd`) and a listing `index.qmd` for each
  - `buffers/` – buffer recipes (`buf_<name>.qmd`)
  - `templates/` – `naming_guide.qmd`, protocol/buffer templates, Excel panel templates, and `blocks/` (copy-paste R blocks for experimental plans)
  - `resources/` – links and reference pages
  - `Archived_protocols/` – retired documents (rendered, but hidden from search)
  - `cross_reference.qmd` – generated buffer-to-protocol and protocol-to-buffer tables
  - `_dependencies.csv`, `_buffer_registry.csv` – which protocol uses which buffer (edited by hand)
  - `_registry.tsv` – generated from each file's YAML at render time (do not edit)
  - `_R/`, `_filters/` – render-time helpers (buffer summaries, auto-links, PDF symbol fixes)
- `scripts/` – `build.sh` (full render + checks), `check_site.py` (link and output checks)
- `docs/` – local build output (git-ignored; deployed by GitHub Actions)

---

## Publishing

The site is built and deployed by GitHub Actions (`.github/workflows/publish.yml`); `docs/` is build output and is **not** committed.

- Push to `main` -> the workflow renders every document to HTML and PDF, runs `scripts/check_site.py`, and deploys to GitHub Pages.
- Pull requests are built and checked but not deployed.
- One-time setting: **Settings -> Pages -> Source = GitHub Actions**.
- Live site: <https://dilloncorvino.com/lab-protocols/>

To preview locally, run `./scripts/build.sh` and open `docs/index.html`.

---

## How to Use the Protocols

1. **Edit or create** a `.qmd` file.  
2. Add YAML metadata:

```yaml
title: "Descriptive title"
subtitle: "Dillon Corvino"
protocol_id: "MUS-PTPRC-GENO-001"
version: "v1.0"
date: "2025-12-01"
description: "More detailed description"
```

3. Write protocol content using Quarto (Markdown + callouts + code blocks).  
4. Render to HTML/PDF.  
5. Commit and push.

---

## Quarto Formatting Cheat Sheet

### Headings

```markdown
# Main section
## Subsection
### Sub-subsection
```

### Lists

```markdown
- Bullet item
- Another item

1. Step one
2. Step two
```

### Callout Blocks

```markdown
::: callout-warning
This is a warning block.
:::

::: callout-tip
This is a tip block.
:::

::: callout-note
This is a note block.
:::
```

### Tables

```markdown
| Component | Amount |
|----------|--------|
| DMEM     | 500 mL |
| FBS      | 50 mL  |
```

### Code Blocks

```bash
# Bash example
quarto render
```

```r
# R example
library(dplyr)
```

---

## Rendering Quarto Documents (Local)

Render a **single file**:

```bash
quarto render prot_mus_lcmv_multi_strain_production.qmd
```

Render everything (use this, not `--to <format>`):

```bash
quarto render
```

Output goes to `docs/` (set by `output-dir` in `_quarto.yml`). It is git-ignored; GitHub Actions rebuilds and deploys it.

## Typical Git Workflow

```bash
git pull
./scripts/build.sh      # optional local preview + link check
git add -A
git commit -m "Update LCMV production and plaque assay protocols"
git push                # Actions builds and deploys
```

---

## Adding a New Protocol or Buffer

1. Copy an existing `.qmd` as template.  
2. Update:
   - `title`
   - `protocol_id` (follow naming guide)
   - `version` (start at v1.0)
3. Write content.  
4. Render output.  
5. Commit and push.

See `naming_guide.qmd` for all identifier rules.

## Linked buffers and protocols

Buffers and protocols reference each other automatically:

- Write IDs as inline code (`` `BUF-ACK-LYSIS` ``, `` `MUS-LIV-DIG` ``) and they render as links, in HTML and PDF.
- A buffer page lists the protocols that use it; a protocol's "Buffers Required" section links to each buffer.
- `cross_reference.qmd` gives the full buffer-to-protocol and protocol-to-buffer tables.
- To declare that a protocol uses a buffer, add a row to `protocols_src/_dependencies.csv`.
- `protocols_src/_registry.tsv` is generated at render time from each file's YAML; do not edit it.

## Licence

Content is released under [CC BY 4.0](LICENSE). Please credit Dillon Corvino (<https://dilloncorvino.com>) when you reuse or adapt a protocol.
