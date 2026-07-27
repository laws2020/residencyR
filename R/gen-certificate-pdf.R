## PDF certificate export, built entirely on grDevices::pdf() and
## base graphics primitives (rect/text/segments/pie/barplot). No
## rmarkdown, no pandoc, no LaTeX -- grDevices and graphics ship with
## every R install, so this adds zero new dependencies.
##
## Layout is hand-drawn in a [0,1] x [0,1] coordinate space per page,
## with automatic pagination once a page's row budget is used up.
## Charts are embedded via par(fig = ...) sub-regions, then the
## full-page coordinate system is restored to continue text overlay.
##
## This report is explicitly labeled as an independent, third-party
## audit -- never as a CBN-issued or CBN-endorsed document. That
## disclaimer is drawn on every page, not just mentioned in docs,
## because a report that visually resembles official output is a
## real problem regardless of the label in the source code.

#' Generate a data residency certificate as a PDF
#'
#' @param audit A data.frame as returned by [scan_data_residency()].
#' @param flagged A data.frame as returned by [flag_offshore_calls()].
#' @param bank_name Character. Name to appear on the certificate.
#' @param output_file Character. Path to write the PDF to.
#' @param rows_per_page Integer. Max audit rows drawn per page on
#'   continuation pages (page 1 fits fewer, since it also carries the
#'   stats, charts, and executive summary). Default 20.
#' @param regulation A list with `citation` and `deadline_text`, as
#'   used by [build_executive_summary()]. Defaults to the CBN 2027
#'   data localization circular.
#' @return Invisibly, `output_file`.
#' @export
gen_residency_certificate_pdf <- function(audit, flagged, bank_name,
                                           output_file,
                                           rows_per_page = 20L,
                                           regulation = .cbn_2027_regulation) {
  .require_license()
  stopifnot(is.data.frame(audit), is.data.frame(flagged))
  stopifnot(is.character(bank_name), length(bank_name) == 1L)
  stopifnot(is.character(output_file), length(output_file) == 1L)

  green    <- "#1F3D2B"
  green_lt <- "#2C5540"
  ink      <- "#1A2238"
  ink_soft <- "#4A5068"
  local_c  <- "#3F7A4F"
  flag_c   <- "#B3261E"
  flag_bg  <- "#FBE7E5"
  rule     <- "#D9D3C4"
  rule_soft<- "#E9E5D8"
  unk_c    <- "#A9A38C"

  total <- nrow(audit)
  n_flagged <- nrow(flagged)
  n_local <- sum(audit$jurisdiction == "local")
  pct_local <- if (total > 0) round(100 * n_local / total, 1) else 0

  summary_text <- build_executive_summary(audit, flagged, regulation)
  summary_lines <- strwrap(summary_text, width = 108)
  scan_errors <- attr(audit, "scan_errors")
  regulator_label <- if (!is.null(regulation$regulator_name)) regulation$regulator_name else "the relevant regulator"

  col_x <- c(0.04, 0.30, 0.46, 0.80)
  row_h <- 0.032
  footer_margin <- 0.06

  grDevices::pdf(output_file, width = 8.27, height = 11.69, title = "Data Residency Audit Report")
  on.exit(grDevices::dev.off())

  draw_row <- function(i, y) {
    status <- audit$status[i]
    is_flagged <- identical(status, "flagged")
    status_label <- toupper(audit$jurisdiction[i])
    graphics::text(col_x[1], y, audit$item[i], adj = c(0, 0.5), cex = 0.72, col = ink)
    graphics::text(col_x[2], y, sprintf("[%s]", audit$source[i]), adj = c(0, 0.5), cex = 0.68, col = ink_soft)
    graphics::text(col_x[3], y, sprintf("%s - %s", audit$provider[i], audit$location[i]),
                    adj = c(0, 0.5), cex = 0.68, col = ink_soft)
    if (is_flagged) {
      lbl_w <- graphics::strwidth(status_label, cex = 0.7, font = 2)
      graphics::rect(col_x[4] - 0.008, y - 0.011, col_x[4] + lbl_w + 0.008, y + 0.011, col = flag_bg, border = NA)
      graphics::text(col_x[4], y, status_label, adj = c(0, 0.5), cex = 0.7, col = flag_c, font = 2)
    } else {
      graphics::text(col_x[4], y, status_label, adj = c(0, 0.5), cex = 0.68, col = local_c, font = 2)
    }
    graphics::segments(0.04, y - row_h / 2, 0.96, y - row_h / 2, col = rule_soft, lty = 1, lwd = 0.7)
  }

  draw_page_header <- function(page_no, page_count) {
    graphics::par(mar = c(0, 0, 0, 0), fig = c(0, 1, 0, 1))
    graphics::plot.new()
    graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1))

    # header band -- taller than before to fit the disclaimer line
    graphics::rect(0, 0.92, 1, 1, col = green, border = NA)
    graphics::text(0.04, 0.978, "Data Residency Audit Report", adj = c(0, 0.5), col = "white", cex = 1.3, font = 2)
    graphics::text(0.04, 0.957, bank_name, adj = c(0, 0.5), col = "white", cex = 0.92)
    graphics::text(0.04, 0.936, sprintf("Independent third-party audit -- not issued by, endorsed by, or affiliated with %s", regulator_label),
                    adj = c(0, 0.5), col = "#CFE0D4", cex = 0.6, font = 3)
    graphics::text(0.96, 0.978, sprintf("Page %d / %d", page_no, page_count), adj = c(1, 0.5), col = "white", cex = 0.75)
    graphics::text(0.96, 0.957, "residencyR", adj = c(1, 0.5), col = "#CFE0D4", cex = 0.72, font = 2)

    cursor <- 0.895
    graphics::text(0.04, cursor, sprintf("Generated: %s", format(Sys.Date(), "%Y-%m-%d")),
                    adj = c(0, 0.5), col = ink_soft, cex = 0.8)
    graphics::text(0.96, cursor, sprintf("Compliance deadline: %s", regulation$deadline_text),
                    adj = c(1, 0.5), col = flag_c, cex = 0.8, font = 2)
    cursor <- cursor - 0.025

    if (page_no == 1 && !is.null(scan_errors)) {
      box_top <- cursor
      box_bottom <- cursor - 0.026
      graphics::rect(0.04, box_bottom, 0.96, box_top, col = flag_bg, border = flag_c)
      graphics::text(0.055, (box_top + box_bottom) / 2,
        sprintf("WARNING: %d source(s) failed to scan and are NOT reflected below (%s)",
                length(scan_errors), paste(scan_errors, collapse = "; ")),
        adj = c(0, 0.5), cex = 0.6, col = flag_c, font = 2)
      cursor <- box_bottom - 0.015
    }

    if (page_no != 1) {
      graphics::text(col_x, 0.87, c("Item", "Source", "Provider / Region", "Status"),
                      adj = c(0, 0.5), font = 2, cex = 0.78, col = ink)
      graphics::segments(0.04, 0.852, 0.96, 0.852, col = ink, lwd = 1.2)
      return(0.852 - 0.038)
    }

    # ---- page 1 only: stats, charts, executive summary ----
    stat_y <- cursor - 0.02
    stat_x <- c(0.04, 0.30, 0.56, 0.82)
    stat_labels <- c("Audited", "Local (NG)", "Flagged", "% Local")
    stat_values <- c(as.character(total), as.character(n_local), as.character(n_flagged), sprintf("%s%%", pct_local))
    for (i in seq_along(stat_x)) {
      graphics::text(stat_x[i], stat_y, stat_values[i], adj = c(0, 0.5), col = green, cex = 1.4, font = 2)
      graphics::text(stat_x[i], stat_y - 0.02, stat_labels[i], adj = c(0, 0.5), col = ink_soft, cex = 0.7)
    }
    cursor <- stat_y - 0.045
    graphics::segments(0.04, cursor, 0.96, cursor, col = rule)
    cursor <- cursor - 0.02

    if (total > 0) {
      chart_top <- cursor
      chart_bottom <- chart_top - 0.155

      graphics::text(0.06, chart_top + 0.005, "JURISDICTION DISTRIBUTION", adj = c(0, 0), cex = 0.62, font = 2, col = ink_soft)
      graphics::text(0.50, chart_top + 0.005, "ITEMS BY SOURCE", adj = c(0, 0), cex = 0.62, font = 2, col = ink_soft)

      jur_counts <- table(factor(audit$jurisdiction, levels = c("local", "offshore", "unknown")))
      graphics::par(fig = c(0.05, 0.34, chart_bottom, chart_top - 0.01), new = TRUE, mar = c(0, 0, 0, 0))
      graphics::pie(as.numeric(jur_counts) + 0.0001, labels = NA, col = c(local_c, flag_c, unk_c),
                    border = "white", clockwise = TRUE, radius = 1)
      graphics::par(new = TRUE)
      graphics::plot(0, 0, type = "n", xlim = c(-1, 1), ylim = c(-1, 1), axes = FALSE, xlab = "", ylab = "")
      graphics::symbols(0, 0, circles = 0.55, add = TRUE, inches = FALSE, bg = "white", fg = "white")
      graphics::text(0, 0, sprintf("%s%%\nLocal", pct_local), cex = 0.85, col = green, font = 2)

      src_counts <- table(audit$source)
      graphics::par(fig = c(0.50, 0.94, chart_bottom, chart_top - 0.01), new = TRUE, mar = c(2, 6.5, 0.5, 1))
      graphics::barplot(src_counts, horiz = TRUE, col = green, border = NA, las = 1,
                          cex.names = 0.62, cex.axis = 0.6, space = 0.6)

      graphics::par(fig = c(0, 1, 0, 1), mar = c(0, 0, 0, 0), new = TRUE)
      graphics::plot.new()
      graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1))

      legend_labels <- c("Local", "Offshore", "Unknown")
      legend_cols <- c(local_c, flag_c, unk_c)
      lx <- 0.06
      for (i in seq_along(legend_labels)) {
        graphics::rect(lx, chart_bottom - 0.028, lx + 0.012, chart_bottom - 0.016, col = legend_cols[i], border = NA)
        graphics::text(lx + 0.018, chart_bottom - 0.022, legend_labels[i], adj = c(0, 0.5), cex = 0.62, col = ink_soft)
        lx <- lx + 0.09
      }

      cursor <- chart_bottom - 0.045
    }

    summary_top <- cursor
    n_sl <- length(summary_lines)
    line_h <- 0.0155
    box_bottom <- summary_top - (n_sl * line_h) - 0.014
    graphics::rect(0.04, box_bottom, 0.96, summary_top + 0.01, col = "#F3EFE6", border = rule)
    for (i in seq_len(n_sl)) {
      graphics::text(0.055, summary_top - (i - 1) * line_h, summary_lines[i], adj = c(0, 0.5), cex = 0.65, col = ink)
    }
    cursor <- box_bottom - 0.03

    headers <- c("Item", "Source", "Provider / Region", "Status")
    graphics::text(col_x, cursor, headers, adj = c(0, 0.5), font = 2, cex = 0.76, col = ink)
    graphics::segments(0.04, cursor - 0.016, 0.96, cursor - 0.016, col = ink, lwd = 1.2)
    cursor - 0.038
  }

  # plan pagination: page 1 has less room (stats+charts+summary), later pages have more
  page1_capacity <- max(1L, floor(0.42 / row_h))            # empirically fits after charts/summary
  cont_capacity  <- max(1L, floor((0.852 - footer_margin) / row_h))
  cont_capacity  <- min(cont_capacity, rows_per_page)

  if (total <= page1_capacity) {
    page_count <- 1L
  } else {
    page_count <- 1L + ceiling((total - page1_capacity) / cont_capacity)
  }

  row_i <- 1L
  for (page_no in seq_len(page_count)) {
    y <- draw_page_header(page_no, page_count)
    capacity <- if (page_no == 1) page1_capacity else cont_capacity
    end_i <- min(row_i + capacity - 1L, total)
    if (row_i <= total) {
      for (i in row_i:end_i) {
        draw_row(i, y)
        y <- y - row_h
      }
      row_i <- end_i + 1L
    }
    if (page_no == page_count) {
      graphics::text(0.04, 0.035, "Generated by residencyR -- independent audit, not issued by or affiliated with any regulator",
                      adj = c(0, 0.5), cex = 0.58, col = ink_soft)
    }
  }

  invisible(output_file)
}
