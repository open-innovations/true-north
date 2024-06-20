#ukbc-local-units

# https://www.nomisweb.co.uk/api/v01/dataset/NM_141_1.data.csv?
# geography=1811939329...1811939332,1811939334...1811939336,1811939338...1811939428,1811939436...1811939442,1811939768,1811939769,1811939443...1811939497,1811939499...1811939501,1811939503,1811939505...1811939507,1811939509...1811939517,1811939519,1811939520,1811939524...1811939570,1811939575...1811939599,1811939601...1811939628,1811939630...1811939634,1811939636...1811939647,1811939649,1811939655...1811939664,1811939667...1811939680,1811939682,1811939683,1811939685,1811939687...1811939704,1811939707,1811939708,1811939710,1811939712...1811939717,1811939719,1811939720,1811939722...1811939730,1811939757...1811939767&
# date=latest&
# industry=150994945...150994965&
# employment_sizeband=0,10,20,30,40&
# legal_status=0,10,1...3,7,20&
# measures=20100&
# uid=0xce1485b8af597e9021c978a63225cd5b792607df

library(dotenv)

dataset <- "NM_141_1" # UKBC local units employees

# extract LAD21s in the North from ONS lookup
lad21_rgn21 <- readr::read_csv("working/cs/LAD21_RGN21_EN_LU.csv") |>
  dplyr::filter(RGN21CD %in% paste0("E1200000", 1:3))

geographies <- list(
  lad = lad21_rgn21$LAD21CD
)

geogs <- unlist(geographies)

date = "latest" # 2023

industries <- "150994945...150994965" # SIC 2007 Sections (A:U)

employment_sizeband <- list(
  total = 0,
  micro = 10,
  small = 20,
  medium = 30,
  large = 40
)

emp_sizeband <- unlist(employment_sizeband)

legal_status <- list(
  total = 0,
  private_sector_total = 10,
  company = 1,
  sole_propietor = 2,
  partnership = 3,
  non_profit_mutual = 7,
  public_sector_total = 20
)

lgl_status <- unlist(legal_status)

measures <- list(
  value = 20100
)

meas <- unlist(measures)

build_nomis_url_2 <- function(
  dataset, geography, date, industry,
  employment_sizeband, legal_status, measures
) {
  endpoint <- "https://www.nomisweb.co.uk/api/v01/dataset/"
  geography  <- paste0("geography=", paste(geography, collapse = ","))
  date <- paste0("date=", paste0(date, collapse = ","))
  industry  <- paste0("industry=", paste(industry, collapse = ","))
  employment_sizeband <- paste0("employment_sizeband=", paste(employment_sizeband, collapse = ","))
  legal_status <- paste0("legal_status=", paste(legal_status, collapse = ","))
  measures <- paste0("measures=", paste(measures, collapse = ","))
  selectors <- paste(geography, date, industry, employment_sizeband, legal_status, measures, sep = "&")
  url <- paste0(endpoint, dataset, ".data.csv?", selectors, "&uid=", Sys.getenv("NOMIS_KEY"))
  return(url)
}

url <- build_nomis_url_2(dataset, geogs, date, industries, emp_sizeband, lgl_status, meas)

ukbc <- readr::read_csv(url, name_repair = tolower) |>
  dplyr::mutate(
    date = as.Date(paste0(date, "-01-01")),
    dates.freq = "a"
  ) |>
  dplyr::mutate(dataset = "UKBC_LU") |>
  dplyr::mutate(geography.type = "LAD21") |>
  dplyr::mutate(industry.name = gsub("[A-Za-z0-9] : ", "", industry_name)) |>
  dplyr::mutate(variable.name = "Number of local units") |>
  dplyr::select(
    dataset,
    dates.date = date, dates.freq,
    geography.code = geography_code,
    geography.name = geography_name,
    geography.type,
    industry.code = industry_code,
    industry.name,
    employment_sizeband.code = employment_sizeband_code,
    employment_sizeband.name = employment_sizeband_name,
    legal_status.code = legal_status_code,
    legal_status.name = legal_status_name,
    variable.name,
    value = obs_value
  )

readr::write_csv(ukbc, "working/cs/ukbc_lu.csv")
arrow::write_parquet(ukbc, "working/cs/ukbc_lu.parquet")
