from pipelines.util import *

if __name__ == "__main__":

    data = etl_load(WDIR, 'cs/vacancies_by_sector_percentage_change_on_previous.csv')

    data = etl.cut(data, 'dates.date', 'value', 'variable.name')

    data = etl.recast(data, key='dates.date', variablefield='variable.name', valuefield='value')

    data = etl.setheader(data, split_text(on="-", headers=etl.header(data)))

    data = etl.setheader(data, slugify_column_names(etl.header(data)))

    # transpose the table for the bar chart visualisation
    data = etl.transpose(data).rename({"dates_date": "sector"})

    etl_write(data, os.path.join(SRC_DIR, 'themes/people-skills-future/_data/growth_by_sector.csv'))
    
    print('Finished vacancies')