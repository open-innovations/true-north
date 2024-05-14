from util import *

if __name__ == "__main__":

    # Load data
    data = etl_load(WDIR, 'vacancies/vacancies-growth-by-sector.csv')

    # Write to csv
    etl_write(data, os.path.join(DATA_DIR, 'vacancies/growth_by_sector'))

    print('Finshed vacancies')