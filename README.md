# Overview
Repo for the True North data dashboard in partnership with <a href="https://www.brabners.com">Brabners</a>.

# Data pipelines
We use `duckdb`, `python` and `R` to pull data from [EDD](https://github.com/economic-analytics/edd/tree/main/data/parquet) (which acts as a database) and <a href="https://open-innovations.github.io/true-north/resources/">other sources</a>. This is the default and preferred option.

For static datasets, we download them manually into `working`.

We track data dependencies using `dvc`.

In `pipelines` we process the data sources to extract only the data we need for the site. These files are stored in data directories available to the website in `src` and checked in to GitHub. These data files drive the visualisations on the site. 

# Site structure
We use Lume to generate a static site and OI Lume charts for the visualisations.