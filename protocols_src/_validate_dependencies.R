#!/usr/bin/env Rscript
# Validation of protocol <-> buffer cross-references.
# Runs as a Quarto pre-render step (quiet; exits non-zero on ERROR so a broken
# link graph cannot be published). Run by hand for the full report:
#   Rscript protocols_src/_validate_dependencies.R

suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

args <- commandArgs(trailingOnly = TRUE)
quiet <- "--quiet" %in% args

source(here::here("protocols_src/_R/build_registry.R"))
registry <- build_registry(quiet = TRUE)

deps <- read_csv(here::here("protocols_src/_dependencies.csv"), show_col_types = FALSE)
buffers <- read_csv(here::here("protocols_src/_buffer_registry.csv"), show_col_types = FALSE)

errors <- character()
warnings_ <- character()

# 1. Dependency buffer IDs exist in the buffer registry.
bad <- setdiff(deps$buffer_id, buffers$buffer_id)
if (length(bad) > 0) errors <- c(errors, paste("Buffer IDs in _dependencies.csv not in _buffer_registry.csv:", paste(bad, collapse = ", ")))

# 2. Dependency protocol IDs exist as real protocol documents (catches typos).
bad <- setdiff(deps$protocol_id, registry$id[registry$type == "protocol"])
if (length(bad) > 0) errors <- c(errors, paste("Protocol IDs in _dependencies.csv with no matching protocol document:", paste(bad, collapse = ", ")))

# 3. Buffer registry files exist, and the file's own ID matches the registry ID.
for (i in seq_len(nrow(buffers))) {
  path <- here::here("protocols_src/buffers", buffers$filename[i])
  if (!file.exists(path)) {
    errors <- c(errors, paste("Buffer file missing:", buffers$filename[i]))
  } else {
    id_in_file <- rmarkdown::yaml_front_matter(path)$protocol_id
    if (!identical(id_in_file, buffers$buffer_id[i])) {
      errors <- c(errors, paste0(buffers$filename[i], ": registry says ", buffers$buffer_id[i], " but the file says ", id_in_file))
    }
  }
}

# 4. Every live buffer document is in the buffer registry.
unregistered <- setdiff(registry$id[registry$type == "buffer"], buffers$buffer_id)
if (length(unregistered) > 0) errors <- c(errors, paste("Buffer documents not in _buffer_registry.csv:", paste(unregistered, collapse = ", ")))

# 5. Registered buffers that no protocol uses.
orphaned <- setdiff(buffers$buffer_id, deps$buffer_id)
if (length(orphaned) > 0) warnings_ <- c(warnings_, paste("Buffers used by no protocol:", paste(orphaned, collapse = ", ")))

# 6. Buffers named in a protocol's text but missing from _dependencies.csv
#    (the usual way the link graph drifts). Version-history rows are ignored.
protocol_docs <- registry |> filter(type == "protocol")
for (i in seq_len(nrow(protocol_docs))) {
  lines <- read_lines(here::here(protocol_docs$path[i]))
  lines <- lines[!str_detect(lines, "^\\|\\s*v[0-9]")]
  mentioned <- str_extract_all(paste(lines, collapse = "\n"), "BUF-[A-Z0-9]+(?:-[A-Z0-9]+)*") |>
    unlist() |> unique()
  mentioned <- intersect(mentioned, buffers$buffer_id)
  declared <- deps$buffer_id[deps$protocol_id == protocol_docs$id[i]]
  missing <- setdiff(mentioned, declared)
  if (length(missing) > 0) {
    warnings_ <- c(warnings_, paste0(protocol_docs$id[i], " mentions ", paste(missing, collapse = ", "), " but has no row in _dependencies.csv"))
  }
}

# 7. Every live document has a heading in _groups.csv (otherwise it shows under "Other").
groups <- read_csv(here::here("protocols_src/_groups.csv"), show_col_types = FALSE)
ungrouped <- setdiff(registry$id, groups$id)
if (length(ungrouped) > 0) warnings_ <- c(warnings_, paste("Not in _groups.csv (will list under 'Other'):", paste(ungrouped, collapse = ", ")))
stale <- setdiff(groups$id, registry$id)
if (length(stale) > 0) warnings_ <- c(warnings_, paste("_groups.csv lists IDs with no document:", paste(stale, collapse = ", ")))

if (length(errors) > 0) cat("ERROR:", errors, sep = "\n  ", "\n")
if (length(warnings_) > 0 && !quiet) cat("WARNING:", warnings_, sep = "\n  ", "\n")
if (length(errors) == 0 && length(warnings_) == 0 && !quiet) cat("All cross-reference checks passed.\n")

if (!quiet) {
  cat("\n=== SUMMARY ===\n")
  cat(glue::glue("{nrow(registry |> filter(type == 'protocol'))} protocols, {nrow(buffers)} buffers, {nrow(deps)} links; {length(errors)} errors, {length(warnings_)} warnings\n"))
}

if (length(errors) > 0) quit(status = 1)
