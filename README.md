![License](https://img.shields.io/badge/license-MIT-blue)
![Quarto](https://img.shields.io/badge/docs-Quarto-informational)

# Protocol Library

This repository contains the Abdullah Lab’s **standardised experimental protocols**, **buffer recipes**, and related **analysis SOPs**, written in [Quarto](https://quarto.org/).

All documents follow a common naming and identifier scheme defined in `naming_guide.qmd`:

- Stable `protocol_id` (e.g. `MUS-LCMV-PROD-001`)
- Versioned via YAML `version: "vX.Y"`

Protocols and buffers are intended to be:

- **Version-controlled** (git + GitHub)
- **Human-readable** (Markdown/Quarto)
- **Rendered** to PDF/HTML for internal use and GitHub Pages publication

---

## Repository Structure (example)

- protocols_src/
  - _templates/
    - `naming_guide.qmd` – naming and ID conventions  
    - `buffer_template.qmd`
    - `protocol_template.qmd`
  - general/
    - `prot_gen_CTV_stain.qmd`
    - `prot_gen_flow_standard.qmd`
  - human/
    - `prot_hum_blood_PBMC_iso.qmd`
    - `prot_hum_NK92_culture.qmd`
  - mouse/  
    - `prot_mus_lcmv_multi_strain_production.qmd`  
    - `prot_mus_lcmv_plaque_assay_vero.qmd`  
  - buffers/  
    - `buf_bhk_propagation_medium.qmd`  
    - `buf_vero_propagation_medium.qmd`  
- docs/ – rendered HTML/PDF for GitHub Pages  

---

## GitHub Pages

This `README.md` appears on the **GitHub repository front page**, but it is **not automatically the homepage of your GitHub Pages site**.

To enable GitHub Pages:

1. Go to **Settings → Pages**  
2. Select:  
   - Source: `Deploy from a branch`  
   - Branch: `main` (or your default)  
   - Folder: `/docs`  
3. Render Quarto documents into `docs/` using `_quarto.yml`.

Your published site will be accessible at:

```
https://eomesodermin.github.io/lab-protocols/
```

---

## How to Use the Protocols

1. **Edit or create** a `.qmd` file.  
2. Add YAML metadata:

```yaml
title: "Descriptive title"
subtitle: "Abdullah Lab, IMMEI, University Hospital Bonn"
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

Render all documents using `_quarto.yml`:

```bash
quarto render
```

Render directly into `docs/` (recommended for GitHub Pages):

```yaml
# _quarto.yml
project:
  type: website
  output-dir: docs
```

```bash
quarto render
```

---

## Typical Git Workflow (render + commit + push)

```bash
git pull
quarto render
git add .
git commit -m "Update LCMV production and plaque assay protocols"
git push
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
