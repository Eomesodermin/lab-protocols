# New experiment wizard
# Trigger with: "Read new_experiment_wizard.md and run the new experiment wizard."

---

## Instructions for Claude Code

Run a two-phase wizard to gather inputs for a new experimental plan.
Present questions in batches — not one at a time.

### Behaviour rules

- Present Phase 1 all at once as a numbered list
- User answers in any order, can skip anything
- Parse answers, then silently determine which Phase 2 follow-up blocks are needed
- Present only the relevant Phase 2 blocks (omit entire blocks made irrelevant by Phase 1 answers)
- After Phase 2 answers, show a compact bullet-point summary and ask "Good to go, or anything to change?"
- Once confirmed: read CLAUDE.md, infer the tier, generate the plan, write it to the experiments folder
- Aim for no more than two rounds of questions total — if you have enough after Phase 1, skip Phase 2 entirely

### Handling missing info

- [INFER]: infer from context, note the assumption as a comment in the doc
- [PLACEHOLDER]: insert NA or [TBD] — never guess
- [REQUIRED]: must be answered — flag it and ask again before proceeding
- "you decide" / "whatever" — infer and note it

### Tone
Direct, no preamble. Lab context.

---

## Phase 1 — present all at once

Present exactly this, as a numbered list:

---

**New experiment — Phase 1**

1. Experiment ID? `DC26_XX`
2. Date? `YYYY-MM-DD`
3. Describe the experiment in 1-2 sentences.
4. Experimental groups? (label + genotype for each; or "single arm" if no comparison)
5. In vivo? If yes: recipient genotype, n per group.
6. Adoptive transfer? If yes: cell type, donor genotype, dose, route.
7. Viral infection? If yes: strain, dose (PFU), route.
8. Surgery or other intervention? (BDL, depletion, drug treatment — or "none")
9. Organs to collect at harvest? Any to weigh?
10. Flow panel(s)? Panel ID or describe the readout.

*Answer what you know — skip or write "TBD" for the rest.*

---

## Phase 2 — follow-up blocks

After Phase 1, present only the blocks below that are still needed.
Skip any block where Phase 1 already gave sufficient information.

### Block: timeline
Show if timeline not clear from Phase 1.
```
Timeline — key days:
- Day 0:
- Day X:
- Harvest day:
```

### Block: donor details
Show if transfer confirmed but yield or donor count not mentioned.
```
Donor details:
- Expected yield per donor (cells per organ)?
- Estimated number of donors needed?
```

### Block: LCMV clone
Show if LCMV mentioned but clone not specified.
```
LCMV clone? (Armstrong / Clone 13 / WE / Docile)
```

### Block: additional readouts
Show if no readouts beyond flow were mentioned and experiment is not tier 1.
```
Readouts beyond flow? (PFU, qPCR, histology, ICS — or "flow only")
```

### Block: analysis
Show if multiple groups exist and stats not mentioned.
```
Primary comparison and stats? (or skip — I will infer from group structure)
```

### Block: notes
Show if not already covered.
```
Anything else to flag? (special reagents, sort details, pilot vs main, expected outcomes)
— or skip
```
