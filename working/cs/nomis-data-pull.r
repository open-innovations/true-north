# nomis data pull

library(dotenv)

geographies <- list(
  lad = c(
    "E06000001", "E06000004", "E06000002", "E06000003", "E06000005",
    "E06000047", "E06000057", "E08000021", "E08000022", "E08000023",
    "E08000037", "E08000024", "E06000063", "E06000064", "E08000003",
    "E08000006", "E08000009", "E08000007", "E08000008", "E08000001",
    "E08000010", "E08000002", "E08000004", "E08000005", "E06000008",
    "E06000009", "E07000121", "E07000128", "E07000119", "E07000123",
    "E07000124", "E07000126", "E07000117", "E07000120", "E07000122",
    "E07000125", "E07000118", "E07000127", "E06000007", "E06000049",
    "E06000050", "E06000006", "E08000011", "E08000013", "E08000012",
    "E08000014", "E08000015", "E06000010", "E06000011", "E06000012",
    "E06000013", "E06000014", "E06000065", "E08000016", "E08000017",
    "E08000018", "E08000019", "E08000032", "E08000035", "E08000033",
    "E08000034", "E08000036"
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
  url <- paste0(endpoint, selectors, "&uid=", Sys.getenv("NOMIS_KEY"))
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

readr::write_csv(data_out, "working/cs/nomis-lad.csv")
arrow::write_parquet(data_out, "working/cs/nomis-lad.parquet")

