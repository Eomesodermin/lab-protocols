#!/usr/bin/env Rscript
# Validation script for protocol-buffer cross-references
# Run from protocols_src/ directory: Rscript _validate_dependencies.R

library(tidyverse)

cat("=== Protocol-Buffer Dependency Validation ===\n\n")

# Read registries
deps <- read_csv("_dependencies.csv", show_col_types = FALSE)
buffers <- read_csv("_buffer_registry.csv", show_col_types = FALSE)

# Check 1: All buffer_ids in deps exist in registry
cat("CHECK 1: Buffer IDs in dependencies exist in registry\n")
missing_buffers <- deps |>
  filter(!buffer_id %in% buffers$buffer_id) |>
  distinct(buffer_id)

if (nrow(missing_buffers) > 0) {
  cat("  ERROR: Buffer IDs in _dependencies.csv not found in _buffer_registry.csv:\n")
  print(missing_buffers)
} else {
  cat("  PASS: All buffer IDs in dependencies are registered\n")
}

# Check 2: All buffer files actually exist
cat("\nCHECK 2: Buffer files exist on disk\n")
buffers |>
  mutate(path = file.path("buffers", filename)) |>
  filter(!file.exists(path)) |>
  select(buffer_id, filename) -> missing_files

if (nrow(missing_files) > 0) {
  cat("  ERROR: Buffer files referenced in registry do not exist:\n")
  print(missing_files)
} else {
  cat("  PASS: All buffer files exist\n")
}

# Check 3: Orphaned buffers (in registry but never used)
cat("\nCHECK 3: Orphaned buffers (registered but not used by any protocol)\n")
orphaned <- buffers |>
  filter(!buffer_id %in% deps$buffer_id)

if (nrow(orphaned) > 0) {
  cat("  WARNING: Buffers in registry but not used by any protocol:\n")
  orphaned |> select(buffer_id, buffer_name) |> print()
} else {
  cat("  PASS: All registered buffers are used\n")
}

# Check 4: Summary stats
cat("\n=== DEPENDENCY SUMMARY ===\n")
cat(glue::glue("Total relationships: {nrow(deps)}\n"))
cat(glue::glue("Unique protocols with buffer deps: {n_distinct(deps$protocol_id)}\n"))
cat(glue::glue("Unique buffers used: {n_distinct(deps$buffer_id)}\n"))
cat(glue::glue("Buffers in registry: {nrow(buffers)}\n"))

# Check 5: Protocols per buffer (usage frequency)
cat("\n=== BUFFER USAGE FREQUENCY ===\n")
deps |>
  left_join(buffers, by = "buffer_id") |>
  group_by(buffer_id, buffer_name) |>
  summarise(n_protocols = n(), .groups = "drop") |>
  arrange(desc(n_protocols)) |>
  print(n = Inf)

# Check 6: Buffers per protocol
cat("\n=== BUFFERS PER PROTOCOL ===\n")
deps |>
  group_by(protocol_id) |>
  summarise(
    n_buffers = n(),
    buffers = paste(buffer_id, collapse = ", "),
    .groups = "drop"
  ) |>
  arrange(desc(n_buffers)) |>
  print(n = Inf)

cat("\n=== VALIDATION COMPLETE ===\n")
