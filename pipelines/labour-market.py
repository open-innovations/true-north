import os
import sys
import petl as etl

THIS_DIR = os.path.dirname(__file__)
TOP = os.path.abspath(os.path.join(THIS_DIR, os.pardir))

WDIR = os.path.join(TOP, 'working/labour-market')
DATA_DIR = os.path.join(TOP, 'data')
METADATA_DIR = os.path.join(TOP, 'metadata')

if __name__ == "__main__":
    # print(os.getcwd())
    data = etl.fromcsv(os.path.join(WDIR, 'lms.csv'))
    data = etl.select(data, lambda x: x.variable == 'MGSX')

    lookup = etl.fromcsv(os.path.join(METADATA_DIR, 'lms-codes.csv'))
    lookup = etl.select(lookup, lambda x: x.CDID == 'MGSX')
    name = str(etl.values(lookup, 'Title'))[7:].strip("'") # get rid of "title"
    data = etl.replace(data, 'variable', 'MGSX', name)
    etl.tocsv(data, os.path.join(DATA_DIR, 'lms.csv'))
    