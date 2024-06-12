from pipelines.util import *
import duckdb
import pandas as pd

def vacancies_growth():

    data = etl_load(WDIR, 'cs/vacancies_by_sector_percentage_change_on_previous.csv')

    data = etl.cut(data, 'dates.date', 'value', 'variable.name')

    data = etl.recast(data, key='dates.date', variablefield='variable.name', valuefield='value')

    data = etl.setheader(data, split_text(on="-", headers=etl.header(data)))

    data = etl.setheader(data, slugify_column_names(etl.header(data)))

    # transpose the table for the bar chart visualisation
    data = etl.transpose(data).rename({"dates_date": "sector"})

    etl_write(data, os.path.join(SRC_DIR, 'themes/people-skills-future/_data/growth_by_sector.csv'))

    return

def vacancies_by_sector():
    URL = "https://github.com/economic-analytics/edd/raw/main/data/parquet/LMS.parquet"
    con = duckdb.connect()

    # make a list of codes from JP9H to JP9Y
    start_code = 'JP9H'
    end_code = 'JP9Y'
    codes = [start_code[:-1] + chr(char) for char in range(ord(start_code[-1]), ord(end_code[-1]) + 1 )]

    # get the required columns and select those with "variable.name" in "codes".
    data = con.execute(f"SELECT \"dates.date\" AS date, \"variable.name\", \"variable.unit\", \"variable.code\", value  FROM '{URL}' WHERE \"dates.freq\"=='m'").fetchdf()
    data = data[data['variable.code'].isin(codes)]

    # Remove recurring string from "variable.name" column
    data['variable.name'] = data['variable.name'].str.replace(pat="UK Job Vacancies (thousands) - ", repl="")

    data['unix'] = pd.to_datetime(data['date'], format=f'%Y-%m-%d').astype(int).div(10**6).astype(int)
    data['decimal_date'] = data['unix'].div((86400*365.25)).add(1970).round(2)

    # pivot data to wide format for visualisation
    data = data.pivot(index=['decimal_date', 'date'], columns='variable.name', values='value')
    
    # limit the time series to last 10 years -> 12months x 10 years = 120 values.
    data = data.tail(120)

    data.to_csv(os.path.join(SRC_DIR,'themes/people-skills-future/_data/vacancies_by_sector.csv'))
    return data

def yearly_change_by_sector(data):
    # Get yearly data going back from most recent data, then flip to put in correct order.
    data = data.iloc[-1::-12, :].copy()
    data.sort_values(by='decimal_date', ascending=True, inplace=True)
    # iterate through each column to work out pct change.
    for col in data.columns.to_list():
        data[f'{col}'] = data[f'{col}'].pct_change().mul(100).round(1)
    
    data.reset_index(inplace=True)
    data.drop(columns='date', inplace=True)
    data.set_index('decimal_date', inplace=True)
    data = data.T
    data.index.rename('sector', inplace=True)
    data.to_csv(os.path.join(SRC_DIR, 'themes/people-skills-future/_data/vacancies_yearly_change_by_sector.csv'))
    
    return

if __name__ == "__main__":
    vacancies_growth()
    data = vacancies_by_sector()
    yearly_change_by_sector(data)
    print('Finished vacancies')