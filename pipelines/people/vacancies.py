from pipelines.util import *

if __name__ == "__main__":

    # # Load data
    # data = etl_load(WDIR, 'vacancies/vacancies-growth-by-sector.csv')
    # # Write to csv
    # etl_write(data, os.path.join(DATA_DIR, 'vacancies/growth_by_sector'))
    data = etl_load(WDIR, 'cs/vacancies_by_sector_percentage_change_on_previous.csv')
    data = etl.cut(data, 'dates.date', 'value', 'variable.name')
    most_recent_date = max(etl.values(data, 'dates.date'))
    data = etl.selecteq(data, 'dates.date', most_recent_date)
    data = etl.recast(data, key='dates.date', variablefield='variable.name', valuefield='value')
    data = etl.setheader(data, split_text(on="-", headers=etl.header(data)))
    etl_write(data, os.path.join(SRC_DIR, 'themes/people-skills-future/_data/growth_by_sector.csv'))
    
    print('Finished vacancies')