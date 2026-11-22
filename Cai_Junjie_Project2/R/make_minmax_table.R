# =============================================================================
# style_report_table()
# -----------------------------------------------------------------------------
# Purpose:
#   Apply one consistent, professional look to every table in the report
#   (navy header with white bold text, light striped rows, outer border).
#
# Arguments:
#   ft              : a flextable object.
#   caption         : character. Caption shown with the table (e.g. "Table 1. ...").
#   first_col_width : numeric. Width in inches of the first (label) column; the
#                     other columns share the rest of the 6.5-inch text width.
#
# Returns:
#   The styled flextable, exactly as wide as the text area.
# =============================================================================
style_report_table <- function(ft, caption, first_col_width = 2.75) {
  navy <- "#1F3864"
  ft |>
    flextable::theme_zebra(odd_header = navy, even_header = navy,
                           odd_body = "#EEF2F8", even_body = "#FFFFFF") |>
    flextable::color(part = "header", color = "white") |>
    flextable::bold(part = "header") |>
    flextable::border_outer(border = officer::fp_border(color = navy, width = 1)) |>
    flextable::font(fontname = "Times New Roman", part = "all") |>
    flextable::fontsize(size = 10.5, part = "all") |>
    flextable::line_spacing(space = 1, part = "all") |>
    flextable::padding(padding.top = 2, padding.bottom = 2, part = "all") |>
    flextable::set_caption(caption = caption) |>
    set_column_widths(first_col_width) |>
    keep_table_together()
}

# =============================================================================
# set_column_widths()
# -----------------------------------------------------------------------------
# Purpose:
#   Give the first (label) column a fixed width so labels do not wrap, and split
#   the remaining text width evenly across the other columns.
#
# Arguments:
#   ft              : a flextable object.
#   first_col_width : numeric. Width of the first column in inches.
#   total_width     : numeric. Total table width in inches (default 6.5, the
#                     text width of a letter page with 1-inch margins).
#
# Returns:
#   The flextable with a fixed layout and the new column widths.
# =============================================================================
set_column_widths <- function(ft, first_col_width, total_width = 6.5) {
  n_col <- length(ft$col_keys)   # number of displayed columns
  ft |>
    flextable::width(j = 1, width = first_col_width) |>
    flextable::width(j = 2:n_col, width = (total_width - first_col_width) / (n_col - 1)) |>
    flextable::set_table_properties(layout = "fixed")
}

# =============================================================================
# keep_table_together()
# -----------------------------------------------------------------------------
# Purpose:
#   Stop Word from splitting a short table across two pages (uses
#   flextable::paginate(), available in flextable >= 0.9.0; older versions are
#   returned unchanged). The last row is released so the table is not also
#   glued to the heading or figure that follows it.
#
# Arguments:
#   ft : a flextable object.
#
# Returns:
#   The flextable, set to stay on one page together with its caption.
# =============================================================================
keep_table_together <- function(ft) {
  if (utils::packageVersion("flextable") >= "0.9.0") {
    ft <- flextable::paginate(ft, init = TRUE, hdr_ftr = TRUE)
    # release the last body row (keep_with_next = FALSE); skipped silently if
    # the internal structure differs in a future flextable version
    ft <- tryCatch({
      n_row <- flextable::nrow_part(ft, part = "body")
      ft$body$styles$pars$keep_with_next$data[n_row, ] <- FALSE
      ft
    }, error = function(e) ft)
  }
  ft
}

# =============================================================================
# make_minmax_table()
# -----------------------------------------------------------------------------
# Purpose:
#   Build a formatted Word-ready table (flextable) of the minimum and maximum
#   daily concentration of each pollutant for a single year.
#
# Arguments:
#   data      : tibble. Combined processed data from process_aq(), with columns
#               date, year, co_ppm, pm25_ugm3, and o3_ppm or o3_ppb.
#   yr        : numeric. The year to summarize (e.g. 2018).
#   table_num : integer. Table number shown in the caption (default 1).
#   digits    : integer. Number of decimal places to display (default 3).
#
# Returns:
#   A flextable with one row per pollutant (name and units in the row label)
#   and columns for the minimum and maximum daily concentration and the number
#   of days with a measurement.
# =============================================================================
make_minmax_table <- function(data, yr, table_num = 1, digits = 3) {

  # Lookup table: column name -> readable label with units
  labels <- c(co_ppm    = "Carbon monoxide, CO (ppm)",
              pm25_ugm3 = "Fine particulate matter, PM₂.₅ (µg/m³)",
              o3_ppm    = "Ozone, O₃ (ppm)",
              o3_ppb    = "Ozone, O₃ (ppb)")

  year_data <- dplyr::filter(data, year == yr)
  if (nrow(year_data) == 0) stop("No data for year ", yr)

  # Pollutant columns present in the data, in a fixed display order
  pollutant_cols <- intersect(names(labels), names(year_data))

  # Date range covered (used in the caption, since 2020 is partial)
  first_day <- format(min(year_data$date), "%b %d")
  last_day  <- format(max(year_data$date), "%b %d")

  summary_tbl <- year_data |>
    tidyr::pivot_longer(dplyr::all_of(pollutant_cols),
                        names_to = "pollutant", values_to = "conc") |>
    dplyr::group_by(pollutant) |>
    dplyr::summarise(
      Minimum = min(conc, na.rm = TRUE),
      Maximum = max(conc, na.rm = TRUE),
      Days    = sum(!is.na(conc)),
      .groups = "drop"
    ) |>
    dplyr::mutate(pollutant = factor(pollutant, levels = pollutant_cols)) |>
    dplyr::arrange(pollutant) |>
    dplyr::mutate(Pollutant = unname(labels[as.character(pollutant)])) |>
    dplyr::select(Pollutant, Minimum, Maximum, Days)

  flextable::flextable(summary_tbl) |>
    flextable::set_header_labels(Pollutant = "Pollutant (units)",
                                 Minimum   = "Minimum daily concentration",
                                 Maximum   = "Maximum daily concentration",
                                 Days      = "Days measured") |>
    flextable::colformat_double(j = c("Minimum", "Maximum"), digits = digits) |>
    flextable::colformat_int(j = "Days") |>
    style_report_table(
      caption = paste0("Table ", table_num, ". Minimum and maximum daily pollutant ",
                       "concentrations, RDU airport monitor, ", yr,
                       " (", first_day, " – ", last_day, ", ", yr, ")")
    ) |>
    # alignment is set after the theme so the theme cannot override it
    flextable::align(j = c("Minimum", "Maximum", "Days"), align = "center", part = "all")
}
