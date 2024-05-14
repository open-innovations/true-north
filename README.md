# Overview
Repo for the True North data dashboard in partnership with Brabners and SevenHills.

# Data pipelines
Data is pulled from its sources into the `working` directory. For data sources we already scrape, this is done using `dvc import-url`. To update this data you can run `dvc update -R working`. The `-R` flag tells `dvc` to recursively go through the `working` directory and check for updates. Data files in `working` are not checked in by default. 

Next, in `pipelines` we process the data sources to extract only the data we need for the site. This is then stored in the `data` directory and checked in to GitHub. This data drives the visualisations on the site. 

Additionally, we grab metadata (primarily lookup tables for ONS 4-letter codes) to rename variables when required. 

# YFF data
We use data from the `yff-data-pipelines` repo which scrapes the latest data for various themes directly from ONS, Nomis etc.

Vacancies growth by sector is taken from an ONS graph they publish and YFF scrape to get the latest stats. We could replicate the ONS growth figure using the UNEM data set from EDD, although may not be worthwhile as could adapt code from YFF to get historic stats too.

# Immigration data
Useful stuff available [here](https://www.gov.uk/government/statistics/immigration-statistics-year-ending-september-2022/why-do-people-come-to-the-uk-to-work#data-tables).
Specifically, this dataset has data on global talent visa applications and admissions by date, nationality, region, applicant type and case outcome.