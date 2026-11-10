# Generated listing pages (mouse / human / general protocols, buffers) and the
# cross-reference matrix. Everything is built from:
#   _registry.tsv      id, title, version, date, description, path (from each document's YAML)
#   _dependencies.csv  which protocol uses which buffer
#   _groups.csv        which heading each document sits under (edit this to regroup)
# A document missing from _groups.csv still appears, under "Other".
#
# Used from a ```{r} results: asis chunk:
#   source(here::here("protocols_src/_R/listing_helpers.R")); render_listing("protocol", "mouse")

source(here::here("protocols_src/_R/buffer_helpers.R"))

.esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
.attr <- function(x) gsub("\"", "&quot;", .esc(x), fixed = TRUE)
# Titles are Pandoc markdown (Ptprc^a^ -> superscript); support just ^sup^ and ~sub~.
.inline <- function(x) {
  x <- .esc(x)
  x <- gsub("\\^([^^ ]+)\\^", "<sup>\\1</sup>", x)
  gsub("~([^~ ]+)~", "<sub>\\1</sub>", x)
}
.month_year <- function(d) {
  out <- tryCatch(format(as.Date(d), "%b %Y"), error = function(e) NA_character_)
  ifelse(is.na(out), "", out)
}
.read_groups <- function() readr::read_csv(here::here("protocols_src/_groups.csv"), show_col_types = FALSE)
.page <- function(path) .page_url(path)
.pdf <- function(path) sub("\\.html$", ".pdf", .page_url(path))

# Non-ASCII characters become numeric entities, so the output is correct in any locale.
.to_entities <- function(x) {
  vapply(x, function(s) {
    cp <- utf8ToInt(enc2utf8(s))
    if (all(cp < 128L)) return(s)
    paste0(ifelse(cp > 127L, sprintf("&#%d;", cp), intToUtf8(cp, multiple = TRUE)), collapse = "")
  }, character(1), USE.NAMES = FALSE)
}

.emit_html <- function(html) {
  cat("```{=html}\n", paste(.to_entities(html), collapse = "\n"), "\n```\n", sep = "")
}

.filter_script <- "<script>
(function () {
  var box = document.querySelector('.plist-filter');
  if (!box) return;
  var cards = [].slice.call(document.querySelectorAll('.pcard'));
  var groups = [].slice.call(document.querySelectorAll('.pgroup'));
  var count = document.querySelector('.plist-count');
  var noun = count ? count.getAttribute('data-noun') : '';
  function apply() {
    var q = box.value.trim().toLowerCase(), shown = 0;
    cards.forEach(function (c) {
      var hit = !q || c.getAttribute('data-search').indexOf(q) !== -1;
      c.classList.toggle('is-hidden', !hit);
      if (hit) shown++;
    });
    groups.forEach(function (g) {
      g.classList.toggle('is-hidden', !g.querySelector('.pcard:not(.is-hidden)'));
    });
    if (count) count.textContent = shown + ' of ' + cards.length + ' ' + noun;
    var empty = document.querySelector('.pempty');
    if (empty) empty.style.display = shown ? 'none' : 'block';
  }
  box.addEventListener('input', apply);
})();
</script>"

.chip <- function(href, label, title) {
  sprintf('<a class="chip" href="%s" title="%s">%s</a>', href, .attr(title), .esc(label))
}

# type = "protocol" or "buffer"; folder = "mouse" / "human" / "general" / "buffers"
render_listing <- function(type = "protocol", folder) {
  reg <- .read_registry()
  deps <- .read_dependencies()
  groups <- .read_groups()

  items <- reg |>
    dplyr::filter(type == !!type, grepl(paste0("/", folder, "/"), path, fixed = TRUE)) |>
    dplyr::left_join(groups, by = "id") |>
    dplyr::mutate(group = dplyr::coalesce(group, "Other"))
  group_order <- unique(c(groups$group[groups$id %in% items$id], "Other"))
  group_order <- group_order[group_order %in% items$group]

  card <- function(r) {
    if (type == "protocol") {
      bufs <- sort(unique(deps$buffer_id[deps$protocol_id == r$id]))
      chips <- vapply(bufs, function(b) {
        e <- reg[reg$id == b, ]
        .chip(.page(e$path[1]), sub("^BUF-", "", b), e$title[1])
      }, character(1))
      foot_label <- if (length(bufs)) "" else '<span class="pnone">No buffers</span>'
      search_extra <- paste(bufs, collapse = " ")
    } else {
      prots <- sort(unique(deps$protocol_id[deps$buffer_id == r$id]))
      chips <- vapply(prots, function(p) {
        e <- reg[reg$id == p, ]
        .chip(.page(e$path[1]), p, e$title[1])
      }, character(1))
      foot_label <- if (length(prots)) "" else '<span class="pnone">Not used in any protocol</span>'
      search_extra <- paste(prots, collapse = " ")
    }
    meta <- paste(c(r$version, .month_year(r$date)), collapse = " - ")
    meta <- sub("^ - | - $", "", meta)
    used <- if (type == "buffer") sprintf('<div class="pused">Used in %d protocol%s</div>', length(chips), if (length(chips) == 1) "" else "s") else ""
    search <- tolower(paste(r$id, r$title, r$description, search_extra))
    paste0(
      sprintf('<div class="pcard" data-search="%s">', .attr(search)),
      sprintf('<div class="pcard-top"><span class="pid">%s</span><span class="pver">%s</span></div>', .esc(r$id), .esc(meta)),
      sprintf('<h3 class="ptitle"><a href="%s">%s</a></h3>', .page(r$path), .inline(r$title)),
      if (nzchar(r$description)) sprintf('<p class="pdesc">%s</p>', .inline(r$description)) else "",
      used,
      sprintf('<div class="pfoot"><div class="pchips">%s%s</div><a class="plink" href="%s">PDF</a></div>',
              paste(chips, collapse = ""), foot_label, .pdf(r$path)),
      "</div>"
    )
  }

  noun <- if (type == "protocol") "protocols" else "buffers"
  html <- c(
    sprintf('<div class="plist-bar"><input class="plist-filter" type="search" placeholder="Filter %s by name, ID, buffer..." aria-label="Filter %s"><span class="plist-count" data-noun="%s">%d %s</span></div>',
            noun, noun, noun, nrow(items), noun)
  )
  for (g in group_order) {
    rows <- items |> dplyr::filter(group == g) |> dplyr::arrange(title)
    cards <- vapply(seq_len(nrow(rows)), function(i) card(rows[i, ]), character(1))
    html <- c(html,
      sprintf('<section class="pgroup"><h2 class="pgroup-title">%s<span class="n">%d</span></h2><div class="pgrid">', .esc(g), nrow(rows)),
      cards, "</div></section>")
  }
  html <- c(html, sprintf('<p class="pempty" style="display:none">No %s match that filter.</p>', noun), .filter_script)
  .emit_html(html)
  invisible(NULL)
}
