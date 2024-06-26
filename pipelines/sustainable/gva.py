import duckdb
from pipelines.util import *

URL = 'https://github.com/economic-analytics/edd/raw/main/data/parquet/RGVA_LAD.parquet'
query = f"SELECT \"dates.date\" AS date, \"variable.name\", \"geography.code\", \"industry.name\", value FROM '{URL}' WHERE \"industry.name\"=='All industries';"

def gva_by_local_authority():
    data = remote_parquet_as_dataframe(query)

    # filter the frame
    data = data[(data['variable.name'] == 'GVA Current Prices £m')]

    # get the most recent date
    data = most_recent_date(data, 'date')
    
    # pivot the frame
    data = data.pivot(columns='variable.name', values='value', index='geography.code')
    
    # write to csv
    data.to_csv(os.path.join(SRC_DIR, 'themes/sustainable-growth/gva/_data/gva_lad.csv'))
    return 

if __name__ == "__main__":
    gva_by_local_authority()
    time_updated(os.path.join(SRC_DIR, 'themes/sustainable-growth/gva/index.vto'), 'nicetheme:')
    edd_last_updated_next_updated(id='RGVA_LAD')