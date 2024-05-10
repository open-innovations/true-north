# Overview
Repo for the True North data dashboard in partnership with Brabners and SevenHills.

# Data pipelines
Data is pulled from its sources into the `working` directory. For data sources we already scrape, this is done using `dvc import-url`. To update this data you can run `dvc update -R working`. The `-R` flag tells `dvc` to recursively go through the `working` directory and check for updates. Data files in `working` are not checked in by default. 

Next, in `pipelines` we process the data sources to extract only the data we need for the site. This is then stored in the `data` directory and checked in to GitHub. This data drives the visualisations on the site. 

Additionally, we grab metadata (primarily lookup tables for ONS 4-letter codes) to rename variables when required. 

# YFF data
We use data from the `yff-data-pipelines` repo which scrapes the latest data for various themes directly from ONS, Nomis etc.