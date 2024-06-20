# demography

# ons_url <- "https://www.ons.gov.uk/file?uri=/businessindustryandtrade/business/activitysizeandlocation/datasets/businessdemographyreferencetable/current/businessdemographyexceltables2022.xlsx"

# warning: file has been manually corrected to deal with incorrect geocodes
# redownloading will cause an error
local_path <- "working/cs/business-demography.xlsx"

# download.file(ons_url, local_path, mode = "wb")

sheet <- "Table 6.1"

business_demography <- readxl::read_excel(
  local_path,
  sheet = sheet,
  skip = 4)

names(business_demography)[1:2] <- c("geography.code", "geography.name")

business_demography$dates.date <- as.Date("2022-01-01")
business_demography$births_percent <- business_demography$Births / business_demography$Active
business_demography$deaths_percent <- business_demography$Deaths / business_demography$Active

business_demography <- business_demography[5:87, ]

business_demography <- business_demography |>
  dplyr::filter(!grepl("E11|E12", geography.code)) |>
  dplyr::select(
    dates.date,
    dplyr::everything()
  )

readr::write_csv(business_demography, "working/cs/business-demography.csv")
arrow::write_parquet(business_demography, "working/cs/business-demography.parquet")
