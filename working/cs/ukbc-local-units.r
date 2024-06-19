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

ukbc <- readr::read_csv(url, name_repair = tolower)

readr::write_csv(ukbc, "working/cs/ukbc.csv")
arrow::write_parquet(ukbc, "working/cs/ukbc.parquet")

ukbc |>
  dplyr::filter(
    employment_sizeband_code == 0,
    legal_status_code == 7
  ) |>
  dplyr::group_by(date) |>
  dplyr::summarise(obs_value = sum(obs_value))
