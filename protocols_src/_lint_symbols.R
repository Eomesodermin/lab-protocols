#!/usr/bin/env Rscript
# Flags characters in the .qmd sources that would break the PDF build.
#
# Handled automatically (no action needed): Unicode super/subscripts, Greek, <= >= and
# friends, and box-drawing characters -- _filters/pdf_symbols.lua rewrites them for PDF.
# Known-safe in the PDF font: degree, multiplication, micro, plus-minus, dashes, quotes, etc.
# Anything else is reported here, because nothing will fix it at render time.
# Informational only: never fails the build. Works on code points, so it does not
# depend on the locale R happens to run in.
#   Rscript protocols_src/_lint_symbols.R          # unhandled characters only
#   Rscript protocols_src/_lint_symbols.R --all    # also summarise handled characters per file

suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

handled <- c(
  0xB9, 0xB2, 0xB3, 0x2070, 0x2074:0x207B, 0x207F,         # superscripts
  0x2080:0x208B,                                           # subscripts
  0x3B1:0x3C9, 0x391:0x3A9,                                # Greek (mu is mapped to micro sign)
  0x2265, 0x2264, 0x2248, 0x2260, 0x223C, 0x226A, 0x226B,  # comparison
  0x2190:0x2195,                                           # arrows
  0x2500, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518, 0x251C, 0x2524, 0x252C, 0x2534, 0x253C, 0x25BC, 0x25B2
)
safe <- c(
  0xB0, 0xD7, 0xB5, 0xB1, 0x2212, 0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2122,
  0xAE, 0xA9, 0xB7, 0x2026, 0xBD, 0xBE, 0xBC, 0xE4, 0xF6, 0xFC, 0xDF, 0xEF, 0xE9, 0xE8, 0xE0,
  0xE1, 0xED, 0xF3, 0xFA, 0xF1, 0xE7, 0xC4, 0xD6, 0xDC
)

args <- commandArgs(trailingOnly = TRUE)
files <- list.files(here::here("protocols_src"), pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE)
files <- files[!str_detect(files, "/Archived_protocols/|/templates/|/resources/|/cross_reference\\.qmd$")]

hits <- map_dfr(files, function(f) {
  cps <- utf8ToInt(enc2utf8(readr::read_file(f)))
  cps <- cps[cps > 127]
  if (length(cps) == 0) return(tibble())
  count(tibble(cp = cps), cp) |> mutate(file = str_remove(f, fixed(paste0(here::here(), "/"))))
})

if (nrow(hits) > 0) {
  hits <- hits |> mutate(status = case_when(cp %in% safe ~ "safe", cp %in% handled ~ "handled", TRUE ~ "UNHANDLED"))
  bad <- hits |> filter(status == "UNHANDLED")
  if (nrow(bad) > 0) {
    cat("LINT: characters the PDF build cannot render (replace with ASCII or a LaTeX-safe form):\n")
    bad |>
      mutate(line = sprintf("  %s: U+%04X (%s) x%d", file, cp, intToUtf8(cp, multiple = TRUE), n)) |>
      pull(line) |> cat(sep = "\n")
    cat("\n")
  }
  if ("--all" %in% args) {
    hits |> filter(status == "handled") |> group_by(file) |> summarise(handled_chars = sum(n)) |> print(n = Inf)
  }
}
