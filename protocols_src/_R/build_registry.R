#!/usr/bin/env Rscript
# Builds protocols_src/_registry.tsv: one row per active protocol and buffer,
# read straight from each document's YAML front matter. This is the single
# source of truth for IDs, titles and file paths used by
#   - buffer_helpers.R   (clickable links in "Buffers Required" / "Linked protocols")
#   - _filters/autolink.lua (turns `BUF-...` / `MUS-...` code spans into links)
#   - the cross-reference page and the generated listing pages
# Run automatically as a Quarto pre-render step; safe to run by hand from anywhere:
#   Rscript protocols_src/_R/build_registry.R

suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

build_registry <- function(quiet = FALSE) {
  root <- here::here()
  files <- list.files(
    here::here("protocols_src"),
    pattern = "^(prot|buf)_.*\\.qmd$", recursive = TRUE, full.names = TRUE
  )
  # Archived documents and templates are not part of the live library.
  files <- files[!str_detect(files, "/Archived_protocols/|/templates/")]

  registry <- map_dfr(files, function(f) {
    meta <- rmarkdown::yaml_front_matter(f)
    tibble(
      id = meta$protocol_id %||% NA_character_,
      type = if_else(str_starts(basename(f), "buf_"), "buffer", "protocol"),
      title = str_replace_all(meta$title %||% NA_character_, "[\t\n]", " "),
      version = meta$version %||% NA_character_,
      path = str_remove(f, fixed(paste0(root, "/"))),
      description = str_squish(str_replace_all(meta$description %||% "", "[\t\n]", " ")),
      date = as.character(meta$date %||% NA_character_)
    )
  }) |>
    arrange(type, id)

  problems <- character()
  if (anyNA(registry$id)) {
    problems <- c(problems, paste("Missing protocol_id in:", paste(registry$path[is.na(registry$id)], collapse = ", ")))
  }
  dups <- registry |> filter(!is.na(id)) |> count(id) |> filter(n > 1)
  if (nrow(dups) > 0) {
    problems <- c(problems, paste("Duplicate IDs:", paste(dups$id, collapse = ", ")))
  }
  if (length(problems) > 0) stop(paste(problems, collapse = "\n"), call. = FALSE)

  write_tsv(registry, here::here("protocols_src/_registry.tsv"), quote = "none")
  if (!quiet) {
    cat(glue::glue("Wrote protocols_src/_registry.tsv: {sum(registry$type == 'protocol')} protocols, {sum(registry$type == 'buffer')} buffers\n"))
  }
  invisible(registry)
}

if (sys.nframe() == 0) build_registry()
