rgva <- arrow::read_parquet(
  "https://github.com/economic-analytics/edd/raw/main/data/parquet/RGVA.parquet",
  as_data_frame = FALSE
)

rgva_north <- rgva |>
  dplyr::filter(geography.code %in% c("TLC", "TLD", "TLE")) |>
  dplyr::filter(dates.date == "2019-01-01" | dates.date == "2022-01-01") |>
  dplyr::filter(industry.code != "Total") |>
  dplyr::filter(grepl("^[A-Z]{1} ", industry.code)) |>
  dplyr::filter(variable.name == "Constant prices") |>
  dplyr::group_by(dates.date, dates.freq, industry.code, industry.name) |>
  dplyr::summarise(value = sum(value)) |>
  dplyr::collect() |>
  tidyr::pivot_wider(names_from = dates.date, values_from = value) |>
  dplyr::mutate(growth_2019_2022 = (`2022-01-01` - `2019-01-01`) / `2019-01-01` * 100) |>
  dplyr::arrange(dplyr::desc(growth_2019_2022)) |>
  readr::write_csv("working/cs/fasting-growing-sectors-north.csv")

rgva |>
  dplyr::filter(geography.type == "ITL2") |>
  dplyr::filter(grepl("^TL[CDE]", geography.code)) |>
  dplyr::filter(variable.name == "Constant prices") |>
  dplyr::filter(grepl("^[A-Z]{1} ", industry.code)) |>
  dplyr::filter(dates.date == "2019-01-01" | dates.date == "2022-01-01") |>
  dplyr::collect() |>
  tidyr::pivot_wider(names_from = dates.date, values_from = value) |>
  dplyr::mutate(growth_2019_2022 = (`2022-01-01` - `2019-01-01`) / `2019-01-01` * 100) |>
  dplyr::group_by(geography.code, geography.name) |>
  dplyr::filter(growth_2019_2022 == max(growth_2019_2022)) |>
  readr::write_csv("working/cs/fasting-growing-sector-by-itl2.csv")
