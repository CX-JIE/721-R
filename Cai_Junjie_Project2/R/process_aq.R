# =============================================================================
# process_aq()
# -----------------------------------------------------------------------------
# Purpose:
#   Read and clean ONE year of raw EPA air quality data from the RDU airport
#   monitor so that the result contains exactly one row per day.
#
# Arguments:
#   file_path : character. Path to a single-year .csv file (e.g. "data/AQ_2018.csv").
#               The file must contain the columns Date, the daily max 8-hour CO
#               concentration, the daily mean PM2.5 concentration, the daily max
#               8-hour ozone concentration, and their unit columns.
#   o3_units  : character, either "ppm" (default) or "ppb". Units in which O3 is
#               returned (1 ppm = 1,000 ppb). The raw data are recorded in ppm.
#
# Returns:
#   A tibble with one row per day (sorted by date) and the columns
#     date      : Date (class Date)
#     co_ppm    : daily max 8-hour CO concentration (ppm)
#     pm25_ugm3 : daily mean PM2.5 concentration (ug/m3)
#     o3_ppm or o3_ppb : daily max 8-hour O3 concentration in the chosen units
#   Days on which a pollutant was never measured have NA for that pollutant.
#
# Processing order (the order matters):
#   1. Remove exact duplicate rows FIRST, so a duplicated record is not counted
#      twice (double-weighted) when daily averages are computed.
#   2. Set negative concentrations to zero BEFORE averaging, so an impossible
#      negative reading cannot pull a daily average down (and cannot hide inside
#      an average that happens to be positive).
#   3. Average multiple measurements of a pollutant within the same day.
#   4. Convert O3 units last (a linear rescaling, so it does not change results).
# =============================================================================
process_aq <- function(file_path, o3_units = c("ppm", "ppb")) {

  # ---- Check arguments -------------------------------------------------------
  o3_units <- match.arg(o3_units)  # errors on anything other than "ppm"/"ppb"
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # ---- Read the raw data -----------------------------------------------------
  # Read every column as character first, so that we control the parsing of
  # dates and numbers explicitly instead of relying on readr's guesses.
  raw <- readr::read_csv(file_path,
                         col_types = readr::cols(.default = readr::col_character()),
                         show_col_types = FALSE)

  # Expected raw column names (as delivered by the EPA download)
  expected_cols <- c("Date",
                     "Daily Max 8-hour CO Concentration", "units_CO",
                     "Daily Mean PM2.5 Concentration", "units_PM",
                     "Daily Max 8-hour Ozone Concentration", "units_O3")
  missing_cols <- setdiff(expected_cols, names(raw))
  if (length(missing_cols) > 0) {
    stop("Missing expected column(s): ", paste(missing_cols, collapse = ", "))
  }

  # ---- Step 1: remove exact duplicate rows -----------------------------------
  raw <- dplyr::distinct(raw)

  # ---- Sanity check on units -------------------------------------------------
  # The cleaned column names hard-code the units, so make sure the raw file
  # really uses ppm for CO and O3 and ug/m3 for PM2.5 (ignoring missing units).
  check_units <- function(x, expected, pollutant) {
    found <- unique(stats::na.omit(x))
    if (!all(found %in% expected)) {
      warning(pollutant, " units in ", basename(file_path), " are not all '",
              expected[1], "': ", paste(found, collapse = ", "))
    }
  }
  check_units(raw$units_CO, "ppm",                   "CO")
  check_units(raw$units_PM, c("ug/m3 LC", "ug/m3"),  "PM2.5")
  check_units(raw$units_O3, "ppm",                   "O3")

  # ---- Rename, format dates, and keep the pollutant columns ------------------
  clean <- raw |>
    dplyr::transmute(
      date      = lubridate::mdy(Date),  # handles "01/01/2018" and "1/1/2020"
      co_ppm    = as.numeric(`Daily Max 8-hour CO Concentration`),
      pm25_ugm3 = as.numeric(`Daily Mean PM2.5 Concentration`),
      o3_ppm    = as.numeric(`Daily Max 8-hour Ozone Concentration`)
    )

  if (any(is.na(clean$date))) {
    stop("Some dates in ", basename(file_path), " could not be parsed.")
  }

  # ---- Step 2: set negative concentrations to zero ---------------------------
  # Loop through each pollutant column and replace negative values with 0.
  # (NA values are left as NA.)
  pollutants <- c("co_ppm", "pm25_ugm3", "o3_ppm")
  for (p in pollutants) {
    is_negative <- !is.na(clean[[p]]) & clean[[p]] < 0
    clean[[p]][is_negative] <- 0
  }

  # ---- Step 3: one row per day (average repeated measurements) ---------------
  # mean(na.rm = TRUE) returns NaN when a day has no non-missing value for a
  # pollutant, so convert NaN back to NA afterwards.
  daily <- clean |>
    dplyr::group_by(date) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(pollutants), ~ mean(.x, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    dplyr::mutate(dplyr::across(dplyr::all_of(pollutants),
                                ~ dplyr::if_else(is.nan(.x), NA_real_, .x))) |>
    dplyr::distinct() |>          # safeguard: no duplicate rows remain
    dplyr::arrange(date)

  # ---- Step 4: O3 units ------------------------------------------------------
  if (o3_units == "ppb") {
    daily <- daily |>
      dplyr::mutate(o3_ppm = o3_ppm * 1000) |>
      dplyr::rename(o3_ppb = o3_ppm)
  }

  daily
}
