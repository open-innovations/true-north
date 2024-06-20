# regional level

inactivity_wants_job_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_181_1.data.csv?geography=2013265921...2013265923&c_sex=0&age=1&einact=0&c_wants=2&measure=1&measures=20100&uid=",
  Sys.getenv("NOMIS_KEY")
)

unemployment_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_17_5.data.csv?geography=2013265921...2013265923&variable=1213&measures=21001&uid=",
  Sys.getenv("NOMIS_KEY")
)

denominators_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_17_5.data.csv?geography=2013265921...2013265923&variable=1201&measures=21002&uid=",
  Sys.getenv("NOMIS_KEY")
)

inactivity <- readr::read_csv(inactivity_wants_job_url, name_repair = tolower)
unemployment <- readr::read_csv(unemployment_url, name_repair = tolower)
denominators <- readr::read_csv(denominators_url, name_repair = tolower)

inact <- dplyr::select(
  inactivity,
  date, geography_code, geography_name, wants_a_job = obs_value
)

unemp <- dplyr::select(
  unemployment,
  date, geography_code, geography_name, unemployed = obs_value
)

population <- dplyr::select(
  denominators,
  date, geography_code, geography_name, population = obs_value
)

joined <- dplyr::left_join(
  inact, unemp, by = c("date", "geography_code", "geography_name")
) |>
  dplyr::left_join(
    population, by = c("date", "geography_code", "geography_name")
  ) |>
  dplyr::mutate(
    unemployed_percent = unemployed / population,
    wants_a_job_percent = wants_a_job / population,
    total_who_want_to_work = (wants_a_job + unemployed) / population
  ) |>
  dplyr::mutate(
    date = as.Date(paste0(date, "-01"))
  )

readr::write_csv(joined, "working/cs/youth-unemployment-adjusted.csv")
arrow::write_parquet(joined, "working/cs/youth-unemployment-adjusted.parquet")

# all the below is for LA-level modelling,
# but there's insufficient data in the current LFS to allow for it

# nomis <- arrow::read_parquet("working/cs/nomis-lad.parquet")

# econ_inactivity_16_24 <- nomis |>
#   dplyr::filter(
#     variable_name %in% c(
#       "% who are economically inactive - aged 16-24"
#     ),
#     measures_name == "Numerator"
#   ) |>
#   dplyr::left_join(
#     readr::read_csv(
#       "working/cs/LAD21_RGN21_EN_LU.csv",
#       col_select = c("LAD21CD", "RGN21CD")
#     ) |>
#       dplyr::filter(RGN21CD %in% paste0("E1200000", 1:3)),
#     by = c("geography_code" = "LAD21CD")
#   )

# # restricted to latest date
# nomis_regional_url <- paste0(
#   "https://www.nomisweb.co.uk/api/v01/dataset/NM_181_1.data.csv?geography=2013265921...2013265923&c_sex=0&age=0,1&einact=0...7&c_wants=1,2&measure=1,3&measures=20100,20701&uid=",
#   Sys.getenv("NOMIS_KEY")
# )

# rgn <- readr::read_csv(nomis_regional_url, name_repair = tolower)

# regional_percentages <- rgn |>
#   dplyr::select(
#     date,
#     geography_code, geography_name,
#     age_name,
#     einact_name,
#     c_wants_name,
#     measure_name,
#     measures_name,
#     percent_wants_job = obs_value
#   ) |>
#   dplyr::filter(
#     age_name == "Aged 16-24",
#     einact_name == "Total",
#     c_wants_name == "Wants a job",
#     measure_name == "Percent",
#     measures_name == "Value"
#   ) |>
#   dplyr::mutate(date = as.Date(paste0(date, "-01")))

# econ_inactive_want_job <- dplyr::left_join(
#   econ_inactivity_16_24,
#   regional_percentages,
#   by = c("date" = "date", "RGN21CD" = "geography_code")
# ) |>
#   dplyr::mutate(adjusted_value = value * (percent_wants_job / 100)) |>
#   dplyr::mutate(variable_name = "Estimated economically inactive 16-24 who want a job") |>
#   dplyr::select(
#     date, date_name,
#     geography_code,
#     geography_name = geography_name.x,
#     geography_type,
#     variable_name,
#     value = adjusted_value
#   )

# unemployment_rate_16_24 <- nomis |>
#   dplyr::filter(
#     variable_name == "Unemployment rate - aged 16-24",
#     measures_name == "Numerator"
#   )

# # now need a new denominator
# # should be total population of 16-24 by LAD over time
# # because APS estimates have not yet been reweighted,
# # we need to use APS denominator data

# denominators_url <- paste0(
#   "https://www.nomisweb.co.uk/api/v01/dataset/NM_17_5.data.csv?geography=1811939329...1811939332,1811939334...1811939336,1811939338...1811939402&variable=1201&measures=21002&uid=",
#   Sys.getenv("NOMIS_KEY")
# )

# denominators <- readr::read_csv(denominators_url, name_repair = tolower) |>
#   dplyr::mutate(date = as.Date(paste0(date, "-01"))) |>
#   dplyr::select(
#     date,
#     geography_code,
#     population_16_24 = obs_value
#   )

# both_metrics <- dplyr::bind_rows(econ_inactive_want_job, unemployment_rate_16_24) |>
#   dplyr::arrange(date, geography_code) |>
#   dplyr::select(-c(theme, variable_code, measures_code, measures_name)) |>
#   tidyr::pivot_wider(names_from = variable_name) |>
#   dplyr::left_join(denominators) |> 
#   dplyr::mutate(
#     `16-24 % unemployed` = 
#       `Unemployment rate - aged 16-24` / population_16_24,
#     `Estimate 16-24 % who want a job` =
#       (`Unemployment rate - aged 16-24` +
#        `Estimated economically inactive 16-24 who want a job`) / 
#        population_16_24
#   ) |>
#   dplyr::filter(date == max(date)) |>
#   View()


# nomis |>
#   dplyr::filter(variable_name == "Unemployment rate - aged 16-24") |>
#   dplyr::filter(date == max(date)) |> View()
