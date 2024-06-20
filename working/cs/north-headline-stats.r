# The north's share of GVA, population and businesses

# gva

gva <- arrow::read_parquet("https://github.com/economic-analytics/edd/raw/main/data/parquet/RGVA.parquet")

gva_final <- gva |>
  dplyr::filter(geography.code %in% c("UK", "TLC", "TLD", "TLE")) |>
  dplyr::filter(industry.code == "Total") |>
  dplyr::filter(dates.date == max(dates.date)) |>
  dplyr::filter(variable.name == "Current prices") |>
  dplyr::group_by(geography.type) |>
  dplyr::summarise(value = sum(value)) |>
  tidyr::pivot_wider(names_from = geography.type) |>
  dplyr::transmute(north_share_of_uk_gva = ITL1 / ctry)

# business counts

ukbc <- readr::read_csv(paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_142_1.data.csv?geography=2092957697,2013265921...2013265923&date=latest&industry=37748736&employment_sizeband=0&legal_status=0&measures=20100&uid=",
Sys.getenv("NOMIS_KEY")
), name_repair = tolower)

ukbc_final <- ukbc |>
  dplyr::select(geography_type, geography_type, geography_name, value = obs_value) |>
  dplyr::group_by(geography_type) |>
  dplyr::summarise(value = sum(value)) |>
  tidyr::pivot_wider(names_from = geography_type) |>
  dplyr::transmute(north_share_of_uk_businesses = regions / countries)

# population

population <- readr::read_csv(paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_31_1.data.csv?geography=2092957697,2013265921...2013265923&date=2021&sex=7&age=0&measures=20100&uid=",
  Sys.getenv("NOMIS_KEY")
), name_repair = tolower)

population_final <- population |>
  dplyr::select(geography_type, geography_type, geography_name, value = obs_value) |>
  dplyr::group_by(geography_type) |>
  dplyr::summarise(value = sum(value)) |>
  tidyr::pivot_wider(names_from = geography_type) |>
  dplyr::transmute(north_share_of_uk_population = regions / countries)

out <- dplyr::bind_cols(gva_final, ukbc_final, population_final)

readr::write_csv(out, "working/cs/north-headline-stats.csv")
