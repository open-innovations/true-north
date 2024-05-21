# Overview
Repo for the True North data dashboard in partnership with Brabners and SevenHills.

# Data pipelines
We use `duckdb` and python to pull data from [EDD](https://github.com/economic-analytics/edd/tree/main/data/parquet) (which acts as a database). This is the default and preferred option.

Where data is not currently available in EDD, we either download manually into `working` or other scripts in `working/cs` download open data from NOMIS, ONS etc. These will eventually be incorporated into EDD and switched to duckdb / python scripts.

For all non-EDD related data we can use `dvc` and  `import-url` if there is a stable URL with regularly updated data. For example, we will manage B Corp data this way.

In `pipelines` we process the data sources to extract only the data we need for the site. These files are stored in data directories available to the website in `src` and checked in to GitHub. These data files drive the visualisations on the site. 

# Immigration data
[This dataset](https://www.gov.uk/government/statistical-data-sets/immigration-system-statistics-data-tables#entry-clearance-visas-granted-outside-the-uk) contains national data for Global Talent Visas (and others).