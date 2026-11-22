# =============================================================================
# render_report.R
# Knit the Project 2 report to Word, then zip the project folder for Canvas.
#
# Usage (any of these):
#   * RStudio: open Cai_Junjie_Project2.Rproj, then run  source("render_report.R")
#   * R GUI:   File > Source File... and choose this file
#   * Shell:   Rscript render_report.R   (from the project folder)
# =============================================================================

# ---- 1. Move to the project root (the folder that contains this script) -----
script_path <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NULL)
if (!is.null(script_path)) setwd(dirname(script_path))
if (!file.exists("Cai_Junjie_Project2.Rproj")) {
  stop("Run this script from the project folder (where Cai_Junjie_Project2.Rproj is).")
}
project_dir <- getwd()

# ---- 2. Install any required packages that are missing ----------------------
required_pkgs <- c("rmarkdown", "knitr", "readr", "dplyr", "tidyr", "purrr",
                   "lubridate", "ggplot2", "flextable", "officer", "here")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace,
                                      logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

# ---- 3. Make sure pandoc (needed by rmarkdown) is available -----------------
# RStudio ships with pandoc; plain R does not, so install a private copy if needed.
if (!rmarkdown::pandoc_available()) {
  if (!requireNamespace("pandoc", quietly = TRUE)) {
    install.packages("pandoc", repos = "https://cloud.r-project.org")
  }
  if (is.null(pandoc::pandoc_locate())) pandoc::pandoc_install()
  pandoc::pandoc_activate()
}

# ---- 4. Knit the R Markdown report -> report/Cai_Junjie_Project2.docx -------
rmarkdown::render(file.path(project_dir, "report", "Cai_Junjie_Project2.Rmd"),
                  output_format = "word_document",
                  envir = new.env())

# ---- 5. Zip the whole project folder -> ../Cai_Junjie_Project2.zip ----------
# (created next to the project folder; RStudio's private .Rproj.user folder
#  and the .git folder are left out)
project_name <- basename(project_dir)
zip_path     <- file.path(dirname(project_dir), paste0(project_name, ".zip"))

old_wd <- setwd(dirname(project_dir))
files_to_zip <- list.files(project_name, recursive = TRUE, all.files = TRUE)
files_to_zip <- files_to_zip[!grepl("^(\\.Rproj\\.user|\\.git)/|\\.DS_Store$", files_to_zip)]
if (file.exists(zip_path)) file.remove(zip_path)
utils::zip(zip_path, files = file.path(project_name, files_to_zip))
setwd(old_wd)

message("Done. Report: ", file.path(project_dir, "report", "Cai_Junjie_Project2.docx"),
        "\nZip: ", zip_path)
