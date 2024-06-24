import duckdb
from pipelines.util import *

URL = 'https://github.com/economic-analytics/edd/raw/main/data/parquet/RGVA_LAD.parquet'

def gva_by_local_authority():
    con = duckdb.connect()

    # @TODO write a generalised function of below
    # @TODO figure out why MAX('date') won't work
    data = con.execute(f"SELECT \"dates.date\" AS date, \"variable.name\", \"geography.code\", \"industry.name\", value FROM '{URL}' WHERE \"industry.name\"=='All industries';").fetchdf()

    # possible to rewrite below in the query, 
    # which may be quicker, but not sure if it's
    # worth it given its easier for me to do in pandas.
    data = data[(data['variable.name'] == 'GVA Current Prices £m') & (data['date'] == max(data['date']))]
    data = data.pivot(columns='variable.name', values='value', index='geography.code')
    #data.rename(columns={'GVA Current Prices £m': 'gva_current_prices', 'GVA Constant Prices £m': 'gva_constant_prices'}, inplace=True)
    data.to_csv(os.path.join(SRC_DIR, 'themes/sustainable-growth/gva/_data/gva_lad.csv'))

if __name__ == "__main__":
    gva_by_local_authority()
    time_updated(os.path.join(SRC_DIR, 'themes/sustainable-growth/gva/index.vto'), 'nicetheme:')