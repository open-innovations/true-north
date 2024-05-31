from pipelines.util import *
import duckdb
import pandas as pd

URL = "https://raw.githubusercontent.com/open-innovations/yff-data-pipelines/main/data/processed/neet.csv"

def total_neet_16_24():
    con = duckdb.connect()
    data = con.execute(f"SELECT date, sheet, age, measure, value FROM '{URL}' WHERE sheet=='People - SA' AND age=='Aged 16-24' AND measure=='People who were NEET as a percentage of people in relevant population group'").fetch_df()
    data = data.tail(1).set_index('date')
    data.to_csv(os.path.join(SRC_DIR, 'themes/people-skills-future/_data/neet.csv'))
    return
    
def neet_by_local_authority():
    data = pd.read_csv(os.path.join(WDIR, 'neet/ud_neet_characteristics.csv'))
    # combine all codes into one column. Uses LA code if exists, the region, then country.
    data['geography_code'] = data['new_la_code'].combine_first(data['region_code']).combine_first(data['country_code'])
    # data = data[data['new_la_code'].notnull()]

    #drop un-used columns
    data.drop(columns=['time_identifier', 'country_name', 'country_code', 'region_code', 'region_name', 'old_la_code', 'geographic_level'], inplace=True)
    data = data[(data['Age']=='16-17') & (data['Characteristic']=='Total') & (data['time_period']==max(data['time_period']))]
    data.set_index('time_period', inplace=True)
    data.index.rename('date', inplace=True)
    data.to_csv(os.path.join(SRC_DIR, 'themes/people-skills-future/_data/most_recent_neet_by_la.csv'))

if __name__ == "__main__":
    total_neet_16_24()
    neet_by_local_authority()