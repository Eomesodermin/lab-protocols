suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))
# The "package X was built under R version Y" notices are emitted as
# warnings (not messages), so suppressPackageStartupMessages() alone does
# not silence them — suppressWarnings() is required too. This is the one
# place in the repo this call happens; every doc sources this file instead
# of calling library(tidyverse) itself for buffer/protocol cross-referencing.

# Quarto often runs R in the plain "C" locale, where cat() prints a non-ASCII character
# such as an en dash as the literal text "<U+2013>" (which the browser then swallows as
# an HTML tag). Switch to a UTF-8 locale so titles and descriptions come out intact.
local({
  if (!isTRUE(l10n_info()[["UTF-8"]])) {
    for (loc in c("en_US.UTF-8", "C.UTF-8", "UTF-8")) {
      if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", loc)))) break
    }
  }
})

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

# ---- Links ---------------------------------------------------------------
# IDs, titles and paths come from protocols_src/_registry.tsv, generated from
# every document's YAML by _R/build_registry.R (a Quarto pre-render step).

.site_url <- "https://dilloncorvino.com/lab-protocols"

.read_registry <- function() {
  path <- here::here("protocols_src/_registry.tsv")
  if (!file.exists(path)) {
    source(here::here("protocols_src/_R/build_registry.R"))
    build_registry(quiet = TRUE)
  }
  readr::read_tsv(path, show_col_types = FALSE)
}

# URL of a document's rendered page. HTML output gets a path relative to the
# document being rendered; PDF (and anything else) gets the published site URL,
# because relative links do not survive in a PDF.
.page_url <- function(qmd_path) {
  html_path <- sub("\\.qmd$", ".html", qmd_path)
  if (isTRUE(knitr::is_html_output())) {
    as.character(fs::path_rel(here::here(html_path), start = getwd()))
  } else {
    paste0(.site_url, "/", html_path)
  }
}

# Markdown link to a protocol or buffer by ID. `label` defaults to the title;
# unknown IDs fall back to plain code so a typo never breaks the render.
link_to <- function(id, label = NULL) {
  entry <- .read_registry() |> dplyr::filter(id == !!id)
  if (nrow(entry) == 0) return(glue::glue("`{id}`"))
  label <- label %||% entry$title[1]
  glue::glue("[{label}]({.page_url(entry$path[1])})")
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
    dplyr::mutate(line = glue::glue(
      "- {purrr::map_chr(protocol_id, ~ as.character(link_to(.x)))} (`{protocol_id}`)"
    )) |>
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

  .cat_line(glue::glue("## {link_to(buffer_id, buffer_name)}"))
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
    "*Full composition, preparation steps, storage, and safety information: {link_to(buffer_id, paste0(buffer_id, ' - full buffer document'))}.*"
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

# ---- Cross-reference tables ------------------------------------------------

# Buffer -> protocols that use it (every registered buffer, including unused).
render_buffer_to_protocols <- function() {
  deps <- .read_dependencies()
  reg <- .read_registry()
  buffers <- reg |> dplyr::filter(type == "buffer") |> dplyr::arrange(title)

  rows <- purrr::map_dfr(buffers$id, function(bid) {
    prots <- deps |> dplyr::filter(buffer_id == bid) |> dplyr::pull(protocol_id) |> unique() |> sort()
    tibble::tibble(
      Buffer = as.character(link_to(bid)),
      `Buffer ID` = paste0("`", bid, "`"),
      `Used in` = length(prots),
      Protocols = if (length(prots) == 0) "-" else paste(purrr::map_chr(prots, ~ as.character(link_to(.x))), collapse = "; ")
    )
  })
  print(knitr::kable(rows, align = "l"))
  invisible(NULL)
}

# Protocol -> buffers it uses (every registered protocol, including those with none).
render_protocol_to_buffers <- function() {
  deps <- .read_dependencies()
  reg <- .read_registry()
  protocols <- reg |> dplyr::filter(type == "protocol") |> dplyr::arrange(title)

  rows <- purrr::map_dfr(protocols$id, function(pid) {
    bufs <- deps |> dplyr::filter(protocol_id == pid) |> dplyr::pull(buffer_id) |> unique() |> sort()
    tibble::tibble(
      Protocol = as.character(link_to(pid)),
      `Protocol ID` = paste0("`", pid, "`"),
      Buffers = if (length(bufs) == 0) "-" else paste(purrr::map_chr(bufs, ~ as.character(link_to(.x))), collapse = "; ")
    )
  })
  print(knitr::kable(rows, align = "l"))
  invisible(NULL)
}
