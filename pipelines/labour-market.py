import os
import sys
import petl as etl

#set some directory paths
THIS_DIR = os.path.dirname(__file__)
TOP = os.path.abspath(os.path.join(THIS_DIR, os.pardir))

WDIR = os.path.join(TOP, 'working/labour-market')
DATA_DIR = os.path.join(TOP, 'src/_data')
METADATA_DIR = os.path.join(TOP, 'metadata')

if __name__ == "__main__":
    # load the data and select the codes we need
    data = etl.fromcsv(os.path.join(WDIR, 'lms.csv'))
    data = etl.select(data, lambda x: x.variable == 'MGSX')

    # load the lookup table and rename
    lookup = etl.fromcsv(os.path.join(METADATA_DIR, 'lms-codes.csv'))
    lookup = etl.select(lookup, lambda x: x.CDID == 'MGSX')
    name = str(etl.values(lookup, 'Title'))[7:].strip("'") # get rid of "title" from the beginning of the string
    data = etl.replace(data, 'variable', 'MGSX', name)

    # write to csv
    etl.tocsv(data, os.path.join(DATA_DIR, 'lms.csv'))
    print('done')
    