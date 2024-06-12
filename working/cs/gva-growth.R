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
  dplyr::filter(grepl("^[A-Z]{1} |Total", industry.code)) |>
  dplyr::filter(dates.date == "2019-01-01" | dates.date == "2022-01-01") |>
  dplyr::collect() |>
  dplyr::group_by(dates.date, geography.code) |>
  dplyr::mutate(share = value / value[industry.code == "Total"]) |>
  dplyr::filter(industry.code != "Total") |>
  tidyr::pivot_wider(names_from = dates.date, values_from = c(share, value)) |>
  dplyr::mutate(growth_2019_2022 = (`value_2022-01-01` - `value_2019-01-01`) / `value_2019-01-01` * 100) |>
  dplyr::group_by(geography.code, geography.name) |>
  dplyr::filter(growth_2019_2022 == max(growth_2019_2022)) |>
  readr::write_csv("working/cs/fasting-growing-sector-by-itl2.csv")

rgva |>
  dplyr::filter(geography.type == "ITL3") |>
  dplyr::filter(grepl("^TL[CDE]", geography.code)) |>
  dplyr::filter(variable.name == "Constant prices") |>
  dplyr::filter(grepl("^[A-Z]{1} ", industry.code)) |>
  dplyr::filter(dates.date == "2019-01-01" | dates.date == "2022-01-01") |>
  dplyr::collect() |>
  tidyr::pivot_wider(names_from = dates.date, values_from = value) |>
  dplyr::mutate(growth_2019_2022 = (`2022-01-01` - `2019-01-01`) / `2019-01-01` * 100) |>
  dplyr::group_by(geography.code, geography.name) |>
  dplyr::filter(growth_2019_2022 == max(growth_2019_2022)) |>
  readr::write_csv("working/cs/fasting-growing-sector-by-itl3.csv")

# LAD
rgva_lad <- arrow::read_parquet(
  "https://github.com/economic-analytics/edd/raw/main/data/parquet/RGVA_LAD.parquet",
  as_data_frame = FALSE
)

rgva_lad |>
  dplyr::filter(variable.name == "GVA Constant Prices £m") |>
  dplyr::filter(dates.date == "2019-01-01" | dates.date == "2022-01-01") |>
  dplyr::inner_join(
    readr::read_csv(
      "working/cs/Local_Authority_District_to_Region_(December_2023)_Lookup_in_England.csv",
      col_select = c("LAD23CD", "RGN23CD")
    ) |>
      dplyr::filter(RGN23CD %in% paste0("E1200000", 1:3)) |>
      dplyr::select(-RGN23CD),
    by = c("geography.code" = "LAD23CD")
  ) |>
  dplyr::filter(grepl("^[A-Z]{1} |ABDE|Total", industry.code)) |>
  dplyr::collect() |>
  dplyr::group_by(dates.date, geography.code) |>
  dplyr::mutate(share = value / value[industry.code == "Total"]) |>
  dplyr::filter(industry.code != "Total") |>
  tidyr::pivot_wider(names_from = dates.date, values_from = c(share, value)) |> 
  dplyr::mutate(growth_2019_2022 = (`value_2022-01-01` - `value_2019-01-01`) / `value_2019-01-01` * 100) |>
  dplyr::group_by(geography.code, geography.name) |>
  dplyr::filter(growth_2019_2022 == max(growth_2019_2022)) |>
  readr::write_csv("working/cs/fasting-growing-sector-by-lad23.csv")
