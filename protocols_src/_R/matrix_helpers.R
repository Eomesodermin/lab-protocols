# Cross-reference page: a protocol x buffer grid and two compact lists.
# Built from _registry.tsv, _dependencies.csv and _groups.csv (see listing_helpers.R).

source(here::here("protocols_src/_R/listing_helpers.R"))

.matrix_script <- "<script>
(function () {
  var t = document.querySelector('.xmatrix');
  if (!t) return;
  function mark(col, on) {
    t.querySelectorAll('[data-col=\"' + col + '\"]').forEach(function (c) { c.classList.toggle('col-hl', on); });
  }
  t.addEventListener('mouseover', function (e) {
    var c = e.target.closest('[data-col]'); if (c) mark(c.getAttribute('data-col'), true);
  });
  t.addEventListener('mouseout', function (e) {
    var c = e.target.closest('[data-col]'); if (c) mark(c.getAttribute('data-col'), false);
  });
})();
</script>"

render_matrix <- function() {
  reg <- .read_registry()
  deps <- .read_dependencies()
  groups <- .read_groups()

  prots <- reg |> dplyr::filter(type == "protocol") |> dplyr::left_join(groups, by = "id") |>
    dplyr::mutate(group = dplyr::coalesce(group, "Other"))
  bufs <- reg |> dplyr::filter(type == "buffer") |> dplyr::left_join(groups, by = "id") |>
    dplyr::mutate(group = dplyr::coalesce(group, "Other"))

  order_groups <- function(df) {
    go <- unique(c(groups$group[groups$id %in% df$id], "Other"))
    go[go %in% df$group]
  }
  # Columns: buffers ordered by group, then title. Rows: protocols likewise.
  bufs <- bufs |> dplyr::mutate(g = match(group, order_groups(bufs))) |> dplyr::arrange(g, title)
  pgroups <- order_groups(prots)

  col_head <- vapply(seq_len(nrow(bufs)), function(j) {
    b <- bufs[j, ]
    new_group <- j == 1 || bufs$group[j] != bufs$group[j - 1]
    sprintf('<th class="xcol%s" data-col="%d"><a href="%s" title="%s">%s</a></th>',
            if (new_group) " xsep" else "", j, .page(b$path), .attr(paste0(b$id, " - ", b$title)), .esc(sub("^BUF-", "", b$id)))
  }, character(1))

  rows <- character()
  for (g in pgroups) {
    rows <- c(rows, sprintf('<tr class="xgroup"><td colspan="%d">%s</td></tr>', nrow(bufs) + 1, .esc(g)))
    gp <- prots |> dplyr::filter(group == g) |> dplyr::arrange(title)
    for (i in seq_len(nrow(gp))) {
      p <- gp[i, ]
      used <- deps$buffer_id[deps$protocol_id == p$id]
      cells <- vapply(seq_len(nrow(bufs)), function(j) {
        new_group <- j == 1 || bufs$group[j] != bufs$group[j - 1]
        on <- bufs$id[j] %in% used
        sprintf('<td class="x%s%s" data-col="%d"%s></td>', if (on) " on" else "", if (new_group) " xsep" else "", j,
                if (on) sprintf(' title="%s uses %s"', .attr(p$id), .attr(bufs$id[j])) else "")
      }, character(1))
      rows <- c(rows, sprintf('<tr><th class="xrowh" scope="row"><a href="%s" title="%s">%s</a></th>%s</tr>',
                              .page(p$path), .attr(p$id), .inline(p$title), paste(cells, collapse = "")))
    }
  }
  html <- c(
    '<p class="xhint">Each dot means the protocol (row) uses the buffer (column). Click a name to open it.</p>',
    '<div class="xwrap"><table class="xmatrix"><thead><tr><th class="xcorner"></th>',
    col_head, "</tr></thead><tbody>", rows, "</tbody></table></div>", .matrix_script
  )
  .emit_html(html)
  invisible(NULL)
}

# kind = "buffer": every buffer with the protocols that use it; "protocol": the reverse.
render_xlist <- function(kind = "buffer") {
  reg <- .read_registry()
  deps <- .read_dependencies()
  items <- reg |> dplyr::filter(type == kind) |> dplyr::arrange(title)
  rows <- vapply(seq_len(nrow(items)), function(i) {
    r <- items[i, ]
    other <- if (kind == "buffer") sort(unique(deps$protocol_id[deps$buffer_id == r$id])) else sort(unique(deps$buffer_id[deps$protocol_id == r$id]))
    chips <- vapply(other, function(o) {
      e <- reg[reg$id == o, ]
      .chip(.page(e$path[1]), if (kind == "buffer") o else sub("^BUF-", "", o), e$title[1])
    }, character(1))
    none <- if (length(chips) == 0) '<span class="pnone">None</span>' else ""
    sprintf('<div class="xrow"><div class="xmain"><a href="%s">%s</a><span class="pid">%s</span></div><div class="pchips">%s%s</div></div>',
            .page(r$path), .inline(r$title), .esc(r$id), paste(chips, collapse = ""), none)
  }, character(1))
  .emit_html(c('<div class="xlist">', rows, "</div>"))
  invisible(NULL)
}
