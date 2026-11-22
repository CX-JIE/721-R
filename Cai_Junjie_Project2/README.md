# Air Pollution at the RDU Airport Monitor, 2018–2020 (Project 2)

## Description

A Duke hematologist is studying associations between air pollution and health system
utilization (emergency department visits, hospitalizations, etc.) for sickle cell disease (SCD)
in Durham County, North Carolina. This project prepares the exposure data for that study:
it cleans raw daily air pollution measurements with a reusable R function and performs an
exploratory data analysis (EDA) of carbon monoxide (CO), fine particulate matter (PM2.5),
and ozone (O3) using tables and plots. The final report is written in R Markdown and
rendered to a Word document.

## Repository

This project is stored in the `Cai_Junjie_Project2/` folder of <https://github.com/CX-JIE/721-R>. To get it:

```
git clone https://github.com/CX-JIE/721-R.git
```

## Data source

- **Source:** U.S. Environmental Protection Agency (EPA) outdoor air quality data, raw daily
  measurements from the air pollution monitor at Raleigh-Durham International (RDU) Airport, NC.
- **Years covered:** January 2018 – April 2020 (`AQ_2020.csv` contains January–April only).
- **Variables:** date; daily max 8-hour CO concentration (ppm); daily mean PM2.5 concentration
  (µg/m³, local conditions); daily max 8-hour O3 concentration (ppm); and a units column for each.
- **Known data issues (handled by `process_aq()`):** exact duplicate rows, multiple PM2.5
  measurements on some days, a negative (impossible) PM2.5 value, missing values, and two
  different date formats (`01/01/2018` vs. `1/1/2020`).

## File structure

```
Cai_Junjie_Project2/
├── Cai_Junjie_Project2.Rproj      # RStudio project file (open this first)
├── README.md                      # This file
├── render_report.R                # Knits the report to Word and builds the submission zip
├── .gitignore
├── data/
│   ├── AQ_2018.csv                # Raw EPA data, 2018
│   ├── AQ_2019.csv                # Raw EPA data, 2019
│   ├── AQ_2020.csv                # Raw EPA data, Jan–Apr 2020
│   └── processed/
│       └── aq_clean_2018_2020.csv # Combined clean data (created when the report is knit)
├── R/
│   ├── process_aq.R               # Function that cleans one year of raw data
│   └── make_minmax_table.R        # Table styling helper + function for the yearly min/max table
└── report/
    ├── Cai_Junjie_Project2.Rmd    # R Markdown source of the report
    ├── reference.docx             # Word style template (fonts, colors, headings) used when knitting
    └── Cai_Junjie_Project2.docx   # Rendered Word report (code hidden)
```

### Key functions

- `process_aq(file_path, o3_units = c("ppm", "ppb"))` — reads one year's `.csv` file and returns a
  tibble with one row per day and columns `date`, `co_ppm`, `pm25_ugm3`, and `o3_ppm` (or `o3_ppb`).
  Steps, in order: remove exact duplicate rows → rename columns and parse dates → set negative
  concentrations to zero (looping over pollutants) → average repeated measurements within a day →
  convert O3 units if requested.
- `make_minmax_table(data, yr, table_num = 1, digits = 3)` — returns a formatted `flextable` with the
  minimum and maximum daily concentration of each pollutant for one year.
- `style_report_table(ft, caption)` — applies the report's shared table style (navy header, striped rows).

### Report contents

Introduction; data description with a variable dictionary; data processing (with a data-quality
summary of what the cleaning changed); yearly minimum/maximum tables (2018, 2019, 2020); annual
mean (SD) table; Figure 1 (monthly CO and O3 with 95% CIs); Figure 2 (monthly PM2.5 by year);
interpretation; and an AI use statement.

## How to reproduce

1. Install R (≥ 4.1) and RStudio (or another IDE that can knit R Markdown).
2. Install the required packages (once):

   ```r
   install.packages(c("rmarkdown", "knitr", "readr", "dplyr", "tidyr", "purrr",
                      "lubridate", "ggplot2", "flextable", "officer", "here"))
   ```

3. Open `Cai_Junjie_Project2.Rproj` so that the working directory is the project root
   (the `here` package uses this to find the `data/` and `R/` folders).
4. Knit the report, either by opening `report/Cai_Junjie_Project2.Rmd` and clicking **Knit → Knit to
   Word**, or by running in the R console:

   ```r
   source("render_report.R")
   ```

   or from a terminal in the project folder: `Rscript render_report.R`. The script installs any
   missing packages (and pandoc, if R is used without RStudio), knits
   `report/Cai_Junjie_Project2.docx`, writes `data/processed/aq_clean_2018_2020.csv`, and zips the
   project as `Cai_Junjie_Project2.zip` next to the project folder.

## Author and date

Junjie Cai — November 2026
