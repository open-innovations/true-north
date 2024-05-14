from util import *

if __name__ == "__main__":
    # load the data and select the codes we need
    data = etl_load(WDIR, 'labour-market/lms.csv')
    data = etl.select(data, lambda x: x.variable == 'MGSX')

    # load the lookup table and rename
    lookup = etl.fromcsv(os.path.join(METADATA_DIR, 'lms-codes.csv'))
    lookup = etl.select(lookup, lambda x: x.CDID == 'MGSX')
    name = str(etl.values(lookup, 'Title'))[7:].strip("'") # get rid of "title" from the beginning of the string
    data = etl.replace(data, 'variable', 'MGSX', name)

    # write to csv
    etl_write(data, os.path.join(DATA_DIR, 'labour-market/lms'))
    print('Finished labour-market')
    