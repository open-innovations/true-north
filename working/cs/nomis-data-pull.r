# nomis data pull

geographies <- list(
  regions = c(
    "E12000001",
    "E12000002",
    "E12000003"
    )
)

geogs <- unlist(geographies)

variables <- list(
  employment = c(employment = 45 #,
                 # employment_by_industry = 1329:1338
  ),
  unemployment = 84,
  economic_activity = 18,
  economic_inactivity = c(
    inactivity = 111,
    inactivity_by_age = c(1219, 1220, 117, 118),
    inactivity_reasons = 1493:1499,
    inactivity_wants_job = 1487:1488
  ),
  self_employment = 74,
  youth_unemployment = 1213,
  qualifications = c(344, 720, 290)
)

vars <- unlist(variables)

measures <- list(
  variable = 20599,
  numerator = 21001
)

meas <- unlist(measures)

build_nomis_url <- function(geography, variable, measures) {
  endpoint <- "https://www.nomisweb.co.uk/api/v01/dataset/NM_17_5.data.csv?"
  geography <- paste0("geography=", paste(geography, collapse = ","))
  variable <- paste0("variable=", paste(variable, collapse = ","))
  measure <- paste0("measures=", paste(measures, collapse = ","))
  selectors <- paste(geography, variable, measure, sep = "&")
  url <- paste0(endpoint, selectors, "&uid=0xce1485b8af597e9021c978a63225cd5b792607df")
  return(url)
}

build_nomis_url(geogs, vars, meas)

# readr::read_csv(build_nomis_url(geogs, vars, meas))

retrieve_nomis_data <- function(url) {
  readr::read_csv(url, name_repair = tolower) |>
    dplyr::select(date, date_name,
                  geography_code, geography_name, geography_type,
                  variable_code, variable_name,
                  measures_code = measures, measures_name,
                  value = obs_value) |>
    dplyr::mutate(date = as.Date(paste0(date, "-01")))
}

data <- list()
data$employment <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$employment),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Employment") |>
  dplyr::mutate(is_summary = TRUE)

data$unemployment <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$unemployment),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Unemployment") |>
  dplyr::mutate(is_summary = TRUE)

data$economic_activity <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$economic_activity),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Economic activity") |>
  dplyr::mutate(is_summary = TRUE)

data$economic_inactivity <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$economic_inactivity),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Economic inactivity") |>
  dplyr::mutate(is_summary = ifelse(variable_code == 111, TRUE, FALSE))

data$self_employment <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$self_employment),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Self employment") |>
  dplyr::mutate(is_summary = TRUE)

data$youth_unemployment <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$youth_unemployment),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Youth unemployment") |>
  dplyr::mutate(is_summary = TRUE)

data$qualifications <- retrieve_nomis_data(
  build_nomis_url(unlist(geographies),
                  unlist(variables$qualifications),
                  unlist(measures))
) |>
  dplyr::mutate(category = "Qualifications") |>
  dplyr::mutate(is_summary = ifelse(variable_code == 290, TRUE, FALSE))

data_out <- dplyr::bind_rows(data, .id = "theme") |>
  dplyr::select(-category, -is_summary)

readr::write_csv(data_out, "working/cs-true-north.csv")
arrow::write_parquet(data_out, "working/cs-true-north.parquet")

