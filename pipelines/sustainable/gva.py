import duckdb
from pipelines.util import *
import pandas as pd

URL = 'https://github.com/economic-analytics/edd/raw/main/data/parquet/RGVA_LAD.parquet'

def fastest_growing_sector():
    data = pd.read_csv(os.path.join(WDIR, 'cs/fasting-growing-sector-by-lad23.csv'), usecols=['geography.code', 'industry.name', '2019-01-01', '2022-01-01', 'growth_2019_2022'])
    data.to_csv(os.path.join(SRC_DIR, 'themes/sustainable-growth/gva/_data/fastest_growing_sector_by_LAD23.csv'))
    return

if __name__ == "__main__":
    con = duckdb.connect()

    # @TODO write a generalised function of below
    # @TODO figure out why MAX('date') won't work
    data = con.execute(f"SELECT \"dates.date\" AS date, \"variable.name\", \"geography.code\", \"industry.name\", value FROM '{URL}' WHERE \"industry.name\"=='All industries' AND date='2022-01-01';").fetchdf()

    # possible to rewrite below in the query, 
    # which may be quicker, but not sure if it's
    # worth it given its easier for me to do in pandas.
    data = data.pivot(columns='variable.name', values='value', index='geography.code')
    #data.rename(columns={'GVA Current Prices £m': 'gva_current_prices', 'GVA Constant Prices £m': 'gva_constant_prices'}, inplace=True)
    data.to_csv(os.path.join(SRC_DIR, 'themes/sustainable-growth/gva/_data/gva_lad.csv'))

    fastest_growing_sector()