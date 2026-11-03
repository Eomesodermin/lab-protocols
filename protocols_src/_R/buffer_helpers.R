suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))
# The "package X was built under R version Y" notices are emitted as
# warnings (not messages), so suppressPackageStartupMessages() alone does
# not silence them — suppressWarnings() is required too. This is the one
# place in the repo this call happens; every doc sources this file instead
# of calling library(tidyverse) itself for buffer/protocol cross-referencing.

# Single source of truth for protocol <-> buffer cross-referencing.
# Sourced (not copy-pasted) from every buffer and protocol .qmd via:
#   source(here::here("protocols_src/_R/buffer_helpers.R"))
# See CLAUDE.md for the `summary:` YAML schema buffer docs must provide.

.read_dependencies <- function() {
  readr::read_csv(here::here("protocols_src/_dependencies.csv"), show_col_types = FALSE)
}

.read_buffer_registry <- function() {
  readr::read_csv(here::here("protocols_src/_buffer_registry.csv"), show_col_types = FALSE)
}

.cat_line <- function(...) {
  # glue::glue() trims trailing newlines from its own output by default, so
  # relying on an embedded "\n" inside a glue template silently drops the
  # line break between successive cat() calls (this caused a real bug: bullet
  # lines and section headings were being glued onto one line and getting
  # swallowed into the preceding list item by Pandoc). Always emit the
  # newline here, outside of glue, instead.
  cat(..., "\n", sep = "")
}

.find_buffer_qmd_path <- function(filename) {
  candidates <- c(
    here::here("protocols_src/buffers", filename),
    here::here("protocols_src/Archived_protocols", filename)
  )
  found <- candidates[file.exists(candidates)]
  if (length(found) == 0) return(NA_character_)
  found[1]
}

# All buffers used by a given protocol_id (joined with registry for name/filename).
get_buffers_for_protocol <- function(protocol_id) {
  deps <- .read_dependencies()
  registry <- .read_buffer_registry()

  deps |>
    dplyr::filter(protocol_id == !!protocol_id) |>
    dplyr::left_join(registry, by = "buffer_id") |>
    dplyr::distinct(buffer_id, .keep_all = TRUE)
}

# All protocol_ids that use a given buffer_id.
get_protocols_for_buffer <- function(buffer_id) {
  deps <- .read_dependencies()
  deps |>
    dplyr::filter(buffer_id == !!buffer_id) |>
    dplyr::distinct(protocol_id)
}

# Renders the "# Linked protocols" section of a buffer doc.
render_linked_protocols <- function(buffer_id) {
  linked <- get_protocols_for_buffer(buffer_id)

  if (nrow(linked) == 0) {
    cat("None\n")
    return(invisible(NULL))
  }

  linked |>
    dplyr::mutate(line = glue::glue("- `{protocol_id}`")) |>
    dplyr::pull(line) |>
    cat(sep = "\n")

  invisible(NULL)
}

# Renders one buffer's concise summary: its own heading + its own small table,
# pulled from that buffer's `summary:` YAML block (single source of truth).
render_buffer_summary <- function(buffer_id) {
  registry <- .read_buffer_registry()
  entry <- registry |> dplyr::filter(buffer_id == !!buffer_id)

  if (nrow(entry) == 0) {
    .cat_line("::: callout-warning")
    .cat_line(glue::glue("**{buffer_id}** is not in the buffer registry — no summary available."))
    .cat_line(":::")
    .cat_line("")
    return(invisible(NULL))
  }

  buffer_name <- entry$buffer_name[1]
  path <- .find_buffer_qmd_path(entry$filename[1])

  if (is.na(path)) {
    .cat_line("::: callout-warning")
    .cat_line(glue::glue("**{buffer_name}** (`{buffer_id}`) — buffer file `{entry$filename[1]}` not found."))
    .cat_line(":::")
    .cat_line("")
    return(invisible(NULL))
  }

  meta <- rmarkdown::yaml_front_matter(path)
  summary <- meta$summary

  .cat_line(glue::glue("## {buffer_name}"))
  .cat_line("")

  if (is.null(summary)) {
    .cat_line("::: callout-note")
    .cat_line(glue::glue(
      "No `summary:` block found for `{buffer_id}` yet. ",
      "See `{buffer_id}` for full composition and preparation details."
    ))
    .cat_line(":::")
    .cat_line("")
    return(invisible(NULL))
  }

  if (!is.null(summary$components) && length(summary$components) > 0) {
    comp.df <- purrr::map_dfr(summary$components, function(x) {
      tibble::tibble(Component = x$name, Amount = x$amount)
    })
    print(knitr::kable(
      comp.df,
      align = "l",
      col.names = c("Component", "Final concentration / amount")
    ))
    .cat_line("")
  }

  fields <- list(
    "Final volume" = summary$final_volume,
    "Preparation note" = summary$prep_note,
    "Sterilisation / filtering" = summary$sterile_filter,
    "Storage" = summary$storage,
    "Caveat" = summary$caveat
  )
  fields <- fields[!vapply(fields, is.null, logical(1))]

  if (length(fields) > 0) {
    for (nm in names(fields)) {
      .cat_line(glue::glue("- **{nm}:** {fields[[nm]]}"))
    }
    .cat_line("")
  }

  .cat_line(glue::glue(
    "*Full composition, preparation steps, storage, and safety information: `{buffer_id}`.*"
  ))
  .cat_line("")

  invisible(NULL)
}

# Renders a protocol's entire "Buffers Required" section: one heading + one
# small table per buffer used, in the order listed in _dependencies.csv.
render_all_buffer_summaries <- function(protocol_id) {
  used <- get_buffers_for_protocol(protocol_id)

  if (nrow(used) == 0) {
    cat("None\n")
    return(invisible(NULL))
  }

  for (bid in used$buffer_id) {
    render_buffer_summary(bid)
  }

  invisible(NULL)
}
