from pipelines.util import *
import duckdb
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
    start_code = 'JP9H'
    end_code = 'JP9Y'
    codes = [start_code[:-1] + chr(char) for char in range(ord(start_code[-1]), ord(end_code[-1]) + 1 )]
    data = con.execute(f"SELECT \"dates.date\" AS date, \"variable.name\", \"variable.unit\", \"variable.code\", value  FROM '{URL}' WHERE \"dates.freq\"=='m'").fetchdf()
    data = data[data['variable.code'].isin(codes)]
    data.to_csv(os.path.join(SRC_DIR,'themes/people-skills-future/_data/vacancies_by_sector.csv'))

if __name__ == "__main__":
    vacancies_growth()
    vacancies_by_sector()
    print('Finished vacancies')