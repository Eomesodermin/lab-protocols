# Abdullah Lab — Document System Specification
# For Claude Code: read this file before creating or editing any .qmd document

---

## 1. Document types and file locations

Three document types exist. Each has its own template and lives in a specific location on disk.
Always write new files to the correct location — never guess or use a relative path.

| Type | Filename prefix | Location on disk |
|---|---|---|
| Experimental plan | `DC{YY}_{NN}_experimental_plan.qmd` | `/Users/dilloncorvino/sciebo/02_Experiments/01_NLC_project/` |
| Protocol | `prot_{scope}_{name}.qmd` | `/Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/protocols_src/` |
| Buffer | `buf_{name}.qmd` | `/Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/protocols_src/` |
| Block | `block_{descriptor}.qmd` | `/Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/templates/module_blocks/` |

Template files live alongside their respective document types in the locations above.
When creating a new document, read the relevant template from disk at that path — do not reconstruct from memory.

This file (CLAUDE.md) lives at:
`/Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/CLAUDE.md`

---

## 2. Universal rules (apply to all document types)

### YAML
- Never add or remove YAML fields from the template — only change values
- `date:` field is always present and always populated (format `YYYY-MM-DD`)
- `author:` is always `"Dillon Corvino"`
- `format:` block is always present in every document (protocols, buffers, and experimental plans)
- `subtitle:` in protocols and buffers is always `"Abdullah Lab, IMMEI, University Hospital Bonn"`

### R code
- Always use `library(tidyverse)` — never base R alternatives
- Always render tables with `knitr::kable(..., align = "l")`
- Use `scales::scientific()` for large numbers (doses, cell counts, PFU)
- Use `scales::comma()` for counts displayed as integers
- Use `scales::percent()` for fractions
- Use `NA_character_` or `NA_integer_` for unfilled placeholder values — never `"[placeholder]"` or `"TBD"` strings inside tibbles

### Prose style
- Lab conversational, precise, not padded
- Callout blocks used for warnings, notes, important flags, tips — never bury critical info in prose
- Callout types: `callout-warning` (safety/loss risk), `callout-important` (protocol-critical), `callout-note` (clarification), `callout-tip` (optimisation advice)
- Bold used for numbers, temperatures, speeds, times, key reagents — not for decoration
- `[TBD]` acceptable as a prose placeholder for supplier/catalogue info not yet confirmed

### Symbol and character conventions (cross-render: HTML + PDF)

Quarto renders HTML via browser and PDF via LaTeX. Many Unicode characters and HTML tags
that display correctly in HTML will silently drop, error, or render as garbage in PDF.
The rules below ensure consistent output in both formats.

**Hard rules — never use these in prose markdown:**

| Do not use | Use instead | Notes |
|---|---|---|
| `µL`, `µg`, `µM`, `µm` (Unicode mu) | `uL`, `ug`, `uM`, `um` | Unicode µ unreliable in PDF |
| `×10⁶` (Unicode superscript digits) | `x10^6` | Unicode superscripts drop in PDF |
| `<sup>6</sup>` HTML tags | `x10^6` | HTML tags ignored by LaTeX |
| `±` Unicode | `+/-` | Drops in some PDF contexts |
| `≥`, `≤` Unicode | `>=`, `<=` | Risky in PDF prose and tables |
| `≈` Unicode | `~` | Tilde works everywhere |
| `CO₂`, `H₂O` Unicode subscripts | `CO2`, `H2O` | Unicode subscripts unreliable in PDF |
| `α`, `β`, `γ` Unicode Greek in prose | spell out: `alpha`, `beta`, `gamma` | For gene/protein names use italics (*Cd8a*) not Greek |
| `&times;`, `&mu;` HTML entities | `x`, `u` prefix | HTML entities are literal strings in LaTeX |

**Acceptable Unicode in prose:**
- `°C` — degree Celsius survives both renderers reliably
- `→` — rightward arrow is generally safe; avoid in PDF table cells if possible

**Inside R code chunks:**
- Unicode in tibble string literals is generally safe — knitr handles encoding before Pandoc
- `scales::scientific()` outputs `1e+06` notation — safe in both renderers
- These rules apply to prose markdown only, not to R chunk output

**If true typographic superscripts are required** (e.g. formal tables):
- Use inline LaTeX math: `$1 \times 10^{6}$` renders correctly in both HTML (via MathJax) and PDF
- Use `$\mu$L` for µL if the `u` prefix is unacceptable in context
- Quarto loads MathJax by default for HTML output — this is safe to use sparingly

---

## 3. Visual structure and navigation

This is intentional and should not be deviated from. The heading hierarchy is the primary navigation aid in long documents — do not flatten or skip levels.

### Heading hierarchy (protocols)

```
# Section name          ← H1: major sections (Purpose, Procedure, Materials, etc.)
                            visually anchored with bottom border — reader knows which section they're in
## STEP N – Title       ← H2: procedure steps only; always use "STEP N –" prefix
                            clearly subordinate to H1; left-aligned
### Sub-heading         ← H3: sub-divisions within a step (Option A / Option B, sub-methods)
                            visually recessed (secondary text colour) — clearly subordinate
```

### Heading hierarchy (experimental plans)

```
## Section name         ← H2: all top-level sections; centred with bottom border
                            the visual anchor — reader knows where each section starts
### Sub-section         ← H3: subsections within a section (P14 abundance, P14 phenotype, etc.)
                            left-aligned, normal text colour
#### Fine detail        ← H4: stat/method annotations; secondary text colour
                            reads as annotation, not a competing heading level
```

### Horizontal rules
- `---` separator after every top-level section block in experimental plans
- `{{< pagebreak >}}` before and after `\tableofcontents` in protocols
- `{{< pagebreak >}}` before Materials, Troubleshooting sections in protocols
- Do not use `---` within prose or within a section — only between top-level blocks

### CSS style block — experimental plans

Always include this block immediately after the YAML, before any content.
This replaces the old CSS block. Do not revert to the old version.

```
```{=html}
<style>
h2 { text-align: center; margin-top: 2.2rem; border-bottom: 1px solid currentColor; padding-bottom: 0.4rem; opacity: 1; }
h3 { margin-top: 1.6rem; }
h4 { font-size: 0.9em; margin-top: 1.0rem; opacity: 0.6; }
hr { margin-top: 1.8rem; margin-bottom: 1.8rem; }
</style>
```
```

Note: `opacity: 0.6` on h4 and `border-bottom: 1px solid currentColor` on h2 use relative values
so they adapt correctly to both light and dark mode without hardcoded hex colours.

### CSS style block — protocols

Protocols render as PDF (via the `format: pdf` block in YAML) so CSS injection does not apply.
Heading visual hierarchy in protocols is achieved purely through Quarto/Pandoc heading sizes.
The heading level conventions in §3 above are sufficient — do not add a CSS block to protocols.

For HTML preview of protocols (if ever rendered to HTML), the Quarto defaults are acceptable.
Do not add a `{=html}` CSS block to protocol files.

### Inline metadata header (protocols and buffers only)
Immediately after YAML:
```
**Protocol ID:** {{< meta protocol_id >}}  
**Version:** {{< meta version >}}  
**Author:** Dillon Corvino  
**Date:** YYYY-MM-DD
```
Use two-space line breaks (not backslash `\`) between lines.

---

## 4. Protocol document structure

Mandatory sections in order:

1. YAML
2. Inline metadata header
3. `# Purpose` — 2–5 sentences, biological motivation and goal
4. `# Critical notes (read before starting)` — bullet list, high-level warnings
5. `# Approximate timing` — bullet list per sub-step + total
6. `{{< pagebreak >}}` + `\tableofcontents` + `{{< pagebreak >}}`
7. `# Procedure` — steps as `## STEP N – TITLE`, with callouts inside steps
8. `{{< pagebreak >}}`
9. `# Protocols used` — mandatory; list any sub-protocols called by this protocol (by protocol_id); write "None" if not applicable
10. `# Buffers used` — mandatory; list buffers by ID only, no compositions; write "None" if not applicable
11. `{{< pagebreak >}}`
12. `# Materials` → `## Reagents` table, `## Disposables` table, `## Equipment` table
13. `{{< pagebreak >}}`
14. `# Troubleshooting` — table: Issue / Possible cause / Suggested solution
15. `{{< pagebreak >}}`
16. `# Safety (brief)` — short bullet list
17. `# Version history` — table: Version / Date / Author / Change summary

### Buffer document structure

Mandatory sections in order:

1. YAML
2. Inline metadata header
3. `# Purpose`
4. `\tableofcontents`
5. `# Linked protocols` — list protocol IDs that use this buffer
6. `# Composition` — table: Component / Stock concentration / Volume for final / Final concentration / Notes
7. `# Preparation` → `## A. Stock preparation (if applicable)` + `## B. Working buffer preparation`
8. `# Storage and stability`
9. `# Reagent details` — table: Component / Supplier / Cat# / Notes
10. `# Safety (brief)`
11. `# Version history`

---

## 5. Experimental plan document structure

### Universal sections (present in every experimental plan, always)

```
YAML
CSS style block
## Goal / Rationale / Research question   ← at minimum one of these; see below
## Deviations during execution            ← ALWAYS present, always last or second-to-last
## Outcome summary                        ← ALWAYS present, always last
```

### Section ordering guide by experiment complexity

**Tier 1 — Minimal/qualitative** (panel eval, single timepoint, no transfer):
Goal → Mice used → Primary readouts → Controls → Deviations → Outcome summary

**Tier 2 — Structured in vivo, no complex calcs** (pilot, simple transfer, depletion optimisation):
Goal → Rationale → Objective → Hypothesis → Experimental overview → Mice used (donor and/or recipient tables) → Experimental groups → Reagents/setup (if relevant) → Protocol steps (if novel method) → Acquisition/gating strategy (if flow) → Primary readouts → Analysis plan → Expected outcomes → Deviations → Outcome summary

**Tier 3 — Full in vivo with computational blocks** (multi-group LCMV, multi-transfer, NLC ACT):
Goal → Rationale → Research question → Hypothesis → Experimental groups (R) → Doses (R) → Timeline → Recipient counts (R) → Viral dose calculation (R, if applicable) → Cell number calculation (R, if applicable) → Tissues and panels (R) → Readouts and analysis plan → Randomisation and blinding → Deviations → Outcome summary

The tier is not a formal tag — it guides which blocks to include. When in doubt, include a section rather than omit it.

### Opening section naming conventions
Use whichever subset is appropriate:
- `## Goal` — one or two sentences, what this experiment is trying to achieve
- `## Rationale` — biological background and motivation (2–5 sentences)
- `## Research question` — single sentence question
- `## Hypothesis` — single sentence prediction
- `## Objective` — specific technical objective (used in pilots/optimisation)
- `## Experimental overview` — bulleted summary of key design parameters (useful for complex experiments)

---

## 6. Block library — copy-paste R sections for experimental plans

Blocks are copy-pasted into experimental plans. They are NOT used with `{{< include >}}`.
After pasting, edit the `# ---- inputs (edit here) ----` section only.
Do not rename the output data frames (groups.df, mice.df, etc.) — downstream blocks depend on them.

### Block status

| Block file | Status | Notes |
|---|---|---|
| `block_mice_table.qmd` | ✅ Keep — REVISED (see spec below) | Split into donor / recipient / single variants |
| `block_randomisation_and_blinding.qmd` | ✅ Keep as-is | Generic, works for all in vivo |
| `block_timeline.qmd` | ✅ Keep — fix placeholders | Remove hardcoded LCMV dates; use generic Day 0/Day N format |
| `block_recipient_counts.qmd` | 🔧 Fix | Hardcodes `receivesNlcTransfer` column name — must be generalised |
| `block_tissues_and_panels.qmd` | 🔧 Fix | Tertiary readout column optional; make two-tier default |
| `block_doses.qmd` | ❌ Retire | Replace with generic `block_doses_generic.qmd` |
| `block_viral_dose_calc_cl13.qmd` | ❌ Retire | Replace with generic `block_viral_dose_calc.qmd` |
| `block_cell_number_calc_nlc_transfer.qmd` | ❌ Retire | Replace with generic `block_cell_number_calc.qmd` |

### New blocks to create

| Block file | Purpose |
|---|---|
| `block_donor_mice_table.qmd` | Donor mouse table for transfer experiments |
| `block_recipient_mice_table.qmd` | Recipient mouse table for transfer experiments |
| `block_gating_strategy.qmd` | Numbered gating hierarchy scaffold |
| `block_sort_strategy.qmd` | Sort instrument, nozzle, mode, collection, gate steps |
| `block_data_record_tables.qmd` | Fill-in harvest/procedure tracking tables (DC26_13 pattern) |

---

## 7. Block specifications (revised and new)

### block_mice_table — three variants

**Variant A: Single mice table (no transfer)**
Heading: `### Mice used` (H3)
Columns: Mouse ID / Sex / Genotype / DOB / Age (weeks) / Treatment
Age in weeks calculated from DOB and experiment date (from YAML `date:` field).

```r
### Mice used

```{r}
library(tidyverse)

experimentDate <- as.Date("YYYY-MM-DD")  # from YAML date field — edit here

mice.df <- tibble::tibble(
  mouseId   = c(NA_character_),
  sex       = c(NA_character_),
  genotype  = c(NA_character_),
  dob       = as.Date(c(NA_character_)),
  treatment = c(NA_character_)
) |>
  dplyr::mutate(
    ageWeeks = as.integer(difftime(experimentDate, dob, units = "weeks"))
  ) |>
  dplyr::select(mouseId, sex, genotype, dob, ageWeeks, treatment)

knitr::kable(
  mice.df,
  align = "l",
  col.names = c("Mouse ID", "Sex", "Genotype", "DOB", "Age (weeks)", "Treatment")
)
```

---
```

**Variant B: Donor mice table (transfer experiment)**
Heading: `### Donor mice`
Columns: Mouse ID / Sex / Genotype / DOB / Age (weeks)

```r
### Donor mice

```{r}
library(tidyverse)

experimentDate <- as.Date("YYYY-MM-DD")  # from YAML date field — edit here

donors.df <- tibble::tibble(
  mouseId  = c(NA_character_),
  sex      = c(NA_character_),
  genotype = c(NA_character_),
  dob      = as.Date(c(NA_character_))
) |>
  dplyr::mutate(
    ageWeeks = as.integer(difftime(experimentDate, dob, units = "weeks"))
  ) |>
  dplyr::select(mouseId, sex, genotype, dob, ageWeeks)

knitr::kable(
  donors.df,
  align = "l",
  col.names = c("Mouse ID", "Sex", "Genotype", "DOB", "Age (weeks)")
)
```

---
```

**Variant C: Recipient mice table (transfer experiment)**
Heading: `### Recipient mice`
Columns: Mouse ID / Genotype / Sex / DOB / Age (weeks) / Ear mark / Treatment

```r
### Recipient mice

```{r}
library(tidyverse)

experimentDate <- as.Date("YYYY-MM-DD")  # from YAML date field — edit here

recipients.df <- tibble::tibble(
  mouseId   = c(NA_character_),
  genotype  = c(NA_character_),
  sex       = c(NA_character_),
  dob       = as.Date(c(NA_character_)),
  earMark   = c(NA_character_),
  treatment = c(NA_character_)
) |>
  dplyr::mutate(
    ageWeeks = as.integer(difftime(experimentDate, dob, units = "weeks"))
  ) |>
  dplyr::select(mouseId, genotype, sex, dob, ageWeeks, earMark, treatment)

knitr::kable(
  recipients.df,
  align = "l",
  col.names = c("Mouse ID", "Genotype", "Sex", "DOB", "Age (weeks)", "Ear mark", "Treatment")
)
```

---
```

### block_timeline — fixed (generic placeholders)

```
### Timeline

- **Day 0:** [event]
- **Day N:** [event]
- **Day N:** Harvest

---
```

### block_recipient_counts — fixed (generalised column name)

The boolean column name for transfer must match the groups.df column in the same experiment.
Edit `receivesTransfer` to match whatever boolean column is used in groups.df.

```r
### Recipient counts

```{r}
# ---- inputs (edit here) ----
# Change "receivesTransfer" to match the boolean column name in groups.df
transferCol <- "receivesTransfer"

totalRecipients    <- as.integer(sum(groups.df$n))
transferRecipients <- as.integer(sum(groups.df$n[groups.df[[transferCol]]]))

recipientCounts.df <- tibble::tibble(
  metric = c(
    "Total recipients (all groups)",
    paste0("Recipients receiving transfer (", transferCol, " == TRUE)")
  ),
  value = c(totalRecipients, transferRecipients),
  notes = c(
    "sum(groups.df$n)",
    paste0("sum(n) where ", transferCol, " == TRUE")
  )
)

knitr::kable(
  recipientCounts.df,
  align = "l",
  col.names = c("Metric", "Value", "Notes")
)
```

---
```

### block_doses_generic — replaces block_doses.qmd

```r
### Doses

```{r}
# ---- inputs (edit here) ----
doses.df <- tibble::tibble(
  item  = c(NA_character_),   # e.g. "P14 transfer", "LCMV Clone 13", "NLC transfer"
  dose  = c(NA_real_),        # numeric value
  units = c(NA_character_),   # e.g. "cells / recipient", "PFU / recipient"
  route = c(NA_character_),   # e.g. "i.v.", "i.p."
  notes = c(NA_character_)
)

knitr::kable(
  doses.df,
  align = "l",
  col.names = c("Item", "Dose", "Units", "Route", "Notes")
)
```

---
```

### block_viral_dose_calc — replaces block_viral_dose_calc_cl13.qmd

Requires: `viralDosePfu` defined in doses block. Requires `receivesVirus` boolean column in groups.df.
Edit `virusCol` if the column name differs.

```r
### Viral dose calculation

```{r}
# ---- inputs (edit here) ----
# viralDosePfu must be defined in the Doses block above
virusCol <- "receivesVirus"  # boolean column in groups.df — edit if different

virusRecipients <- as.integer(sum(groups.df$n[groups.df[[virusCol]]]))

viralAssumptions.df <- tibble::tibble(
  assumption = c("Viral dose per recipient", "Recipients receiving virus"),
  value      = c(scales::scientific(viralDosePfu), virusRecipients),
  notes      = c("from Doses block", paste0("sum(n) where ", virusCol, " == TRUE"))
)

knitr::kable(
  viralAssumptions.df,
  align = "l",
  col.names = c("Assumption", "Value", "Notes")
)
```

```{r}
totalVirusPfu <- viralDosePfu * virusRecipients

viralOutputs.df <- tibble::tibble(
  metric = "Total viral PFU required",
  value  = scales::scientific(totalVirusPfu),
  notes  = "viralDosePfu x recipients"
)

knitr::kable(
  viralOutputs.df,
  align = "l",
  col.names = c("Metric", "Value", "Notes")
)
```

---
```

### block_cell_number_calc — replaces block_cell_number_calc_nlc_transfer.qmd

Requires: `dosePerRecipient` defined in doses block. Requires `receivesTransfer` and `donorGenotype` columns in groups.df.
Edit column names at the top to match groups.df.

```r
### Cell number calculation

```{r}
# ---- inputs (edit here) ----
transferCol  <- "receivesTransfer"  # boolean column in groups.df
donorCol     <- "donorGenotype"     # donor genotype column in groups.df
# dosePerRecipient must be defined in the Doses block above
overheadFrac <- 0.15  # fraction to cover handling/sorting losses; edit as needed

yield.df <- tibble::tibble(
  donorGenotype  = c(NA_character_),  # one row per donor genotype; must match groups.df values
  yieldPerDonor  = c(NA_real_)        # estimated cells per donor organ
)

recipientsByDonor.df <- groups.df |>
  dplyr::filter(.data[[transferCol]]) |>
  dplyr::group_by(dplyr::across(dplyr::all_of(donorCol))) |>
  dplyr::summarise(nRecipients = sum(n), .groups = "drop") |>
  dplyr::rename(donorGenotype = dplyr::all_of(donorCol))

assumptions.df <- tibble::tibble(
  assumption = c(
    "Target dose per recipient",
    "Overhead fraction",
    "Recipients per donor genotype",
    "Expected yield per donor (by genotype)"
  ),
  value = c(
    scales::scientific(dosePerRecipient),
    scales::percent(overheadFrac, accuracy = 1),
    paste0(recipientsByDonor.df$donorGenotype, ": ", recipientsByDonor.df$nRecipients, collapse = " | "),
    paste0(yield.df$donorGenotype, ": ", scales::scientific(yield.df$yieldPerDonor), collapse = " | ")
  ),
  notes = c(
    "from Doses block",
    "accounts for handling/sorting losses",
    "derived from groups table",
    "cells per donor organ"
  )
)

knitr::kable(
  assumptions.df,
  align = "l",
  col.names = c("Assumption", "Value", "Notes")
)
```

```{r}
outputsByDonor.df <- recipientsByDonor.df |>
  dplyr::left_join(yield.df, by = "donorGenotype") |>
  dplyr::mutate(
    totalCellsNeeded = dosePerRecipient * nRecipients * (1 + overheadFrac),
    donorsNeeded     = ceiling(totalCellsNeeded / yieldPerDonor)
  ) |>
  dplyr::transmute(
    `Donor genotype`                     = donorGenotype,
    `Recipients`                         = as.integer(nRecipients),
    `Dose per recipient`                 = scales::scientific(dosePerRecipient),
    `Total cells needed (incl. overhead)` = scales::comma(as.integer(round(totalCellsNeeded))),
    `Yield per donor`                    = scales::scientific(yieldPerDonor),
    `Donors required`                    = as.integer(donorsNeeded)
  )

knitr::kable(outputsByDonor.df, align = "l")
```

---
```

### block_tissues_and_panels — fixed (two-tier default, tertiary optional)

```r
### Tissues and panels

#### Organs to collect

```{r}
library(tidyverse)

organs.df <- tibble::tibble(
  sample          = c(NA_character_),
  primaryReadouts = c(NA_character_),
  secondaryReadout = c(NA_character_),
  weighOrgan      = c(NA),
  notes           = c(NA_character_)
)

knitr::kable(
  organs.df,
  align = "l",
  col.names = c("Sample / organ", "Primary readouts", "Secondary readout", "Weigh organ", "Notes")
)
```

#### Flow panels

```{r}
panels.df <- tibble::tibble(
  panelId   = c(NA_character_),
  panelName = c(NA_character_),
  usedFor   = c(NA_character_),
  notes     = c(NA_character_)
)

knitr::kable(
  panels.df,
  align = "l",
  col.names = c("Panel ID", "Panel name", "Used for", "Notes")
)
```

---
```

### block_gating_strategy (new)

```
### Gating strategy

1. FSC/SSC — lymphocyte gate
2. Singlets
3. Live cells (viability dye negative)
4. [Population gate — e.g. CD45+]
5. [Marker 1 vs Marker 2]
6. [Target population]

---
```

### block_sort_strategy (new)

```
### Sort strategy

- **Instrument:** [sorter name]
- **Nozzle:** [size µm]
- **Sort mode:** [e.g. 2-way, 4-way]
- **Collection vessel:** [tube type and buffer]
- **Collection conditions:** [cooled / RT / FCS-coated]

**Gate hierarchy:**

1. FSC/SSC — lymphocytes
2. Singlets
3. Live cells
4. [Population gate]
5. [Target sort gate]

**Sorted population:** [full phenotype description]

---
```

### block_data_record_tables (new)

For experiments where manual fill-in tracking tables are needed during execution (surgery, infection, harvest).

```
### Data record — [experiment phase, e.g. harvest]

| Mouse ID | [Measure 1] | [Measure 2] | [Measure 3] | Notes |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |

---
```

---

## 8. Known issues to watch for

- `block_doses.qmd` and `block_viral_dose_calc_cl13.qmd` are hardcoded to LCMV Clone 13 and P14/NLC — do not copy these into new experiments; use the generic replacements specified above
- `block_cell_number_calc_nlc_transfer.qmd` hardcodes `receivesNlcTransfer` and `nlcDonorGenotype` column names — do not copy; use generic version
- `block_recipient_counts.qmd` hardcodes `receivesNlcTransfer` — do not copy; use fixed version
- Protocols `prot_mus_liver_digestion.qmd` and `prot_mus_spleen_dissociation.qmd` are missing `format:` block and `date:` in YAML — these should be updated when next edited
- DC26_01 uses a `params:` YAML approach with deeply nested structures — this pattern was abandoned and should not be replicated

---

## 9. Naming conventions (summary)

```
Experimental plans : DC{YY}_{NN}_experimental_plan.qmd
Protocols          : prot_{scope}_{descriptor}.qmd
                     scope = mus / hum / gen / nlc / vir
Buffers            : buf_{descriptor}.qmd
Blocks             : block_{descriptor}.qmd
```

Protocol IDs follow: `{SCOPE}-{ORGAN/SYSTEM}-{DESCRIPTOR}`
Buffer IDs follow: `BUF-{DESCRIPTOR}`

Version tracking is handled by the `version:` field in YAML — IDs are stable identifiers that do not change across versions.

---

## 10. Generation workflow (for Claude Code)

### Path constants — always use these, never guess

```
EXPERIMENTS = /Users/dilloncorvino/sciebo/02_Experiments/01_NLC_project/
PROTOCOLS   = /Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/protocols_src/
CLAUDE_MD   = /Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/CLAUDE.md
```

### When asked to create a new experimental plan:
1. Read this file (CLAUDE.md)
2. Read `Experimental_plan_template.qmd` from `EXPERIMENTS/` path above
3. Ask for: experiment ID, title, date, experiment type (tier 1/2/3), and key parameters
4. Copy the YAML and CSS block from the template exactly — adjust values only
5. Select appropriate sections and blocks for the tier
6. Copy-paste block code verbatim from the relevant block files in `PROTOCOLS/`, then edit only the `# ---- inputs (edit here) ----` sections
7. Leave `NA_character_` / `NA_real_` where values are unknown — never invent values
8. Always include `## Deviations during execution` and `## Outcome summary` as the final two sections
9. Write the completed file to `EXPERIMENTS/`

### When asked to create a new protocol:
1. Read this file (CLAUDE.md)
2. Read `protocol_template.qmd` from `PROTOCOLS/`
3. Copy YAML from template exactly, adjust values only
4. Follow section order in §4 without deviation
5. Include `# Protocols used` and `# Buffers used` — write "None" if not applicable
6. Write the completed file to `PROTOCOLS/`

### When asked to create a new buffer:
1. Read this file (CLAUDE.md)
2. Read `buffer_template.qmd` from `PROTOCOLS/`
3. Copy YAML from template exactly, adjust values only
4. Follow section order in §4
5. Write the completed file to `PROTOCOLS/`

### When asked to update blocks:
All block files live in `BLOCKS/`. Operate on them there.

```
BLOCKS = /Users/dilloncorvino/Documents/Github/Eomesodermin/lab-protocols/templates/module_blocks/
```

- `block_doses.qmd` → retire (rename to `block_doses.qmd.retired`); write `block_doses_generic.qmd` per spec in §7
- `block_viral_dose_calc_cl13.qmd` → retire (rename to `.retired`); write `block_viral_dose_calc.qmd` per spec in §7
- `block_cell_number_calc_nlc_transfer.qmd` → retire (rename to `.retired`); write `block_cell_number_calc.qmd` per spec in §7
- `block_recipient_counts.qmd` → overwrite with fixed version per spec in §7
- `block_timeline.qmd` → overwrite with generic placeholder version per spec in §7
- `block_tissues_and_panels.qmd` → overwrite with two-tier version per spec in §7
- `block_mice_table.qmd` → overwrite with Variant A (single); also create `block_donor_mice_table.qmd` (Variant B) and `block_recipient_mice_table.qmd` (Variant C) per spec in §7
- Create new blocks: `block_gating_strategy.qmd`, `block_sort_strategy.qmd`, `block_data_record_tables.qmd` per spec in §7

Retired blocks are renamed not deleted so existing experimental plans that reference them are not broken.
Do not modify any existing experimental plan or protocol files during block update tasks.
