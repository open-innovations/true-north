# national vacancies by industry change on previous period

# ONS codes from LMS dataset:
# JP9H to JP9Y

# Use time-series transformation scripts from EDD
source("https://github.com/economic-analytics/edd/raw/main/R/utils-time-series.R")

lms <- arrow::read_parquet(
  "https://github.com/economic-analytics/edd/raw/main/data/parquet/LMS.parquet",
  as_data_frame = FALSE
) |>
  dplyr::filter(
    dates.freq == "m",
    grepl("JP9[H-Y]", variable.code),
    !is.na(value)
  ) |>
  dplyr::collect()

lms_change <- lms |>
  ts_transform_df$percent_change() |>
  dplyr::mutate(variable.name = stringr::str_replace(
    variable.name, "thousands", "% change"
  ))

readr::write_csv(
  lms_change,
  "working/vacancies_by_sector_percentage_change_on_previous.csv"
)
