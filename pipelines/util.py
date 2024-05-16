import os
from datetime import datetime
import petl as etl
from slugify import slugify

#set some directory paths
THIS_DIR = os.path.dirname(__file__)
TOP = os.path.abspath(os.path.join(THIS_DIR, os.pardir))

WDIR = os.path.join(TOP, 'working')
DATA_DIR = os.path.join(TOP, 'src/_data')
SRC_DIR = os.path.join(TOP, 'src')
METADATA_DIR = os.path.join(TOP, 'metadata')

def etl_load(working, fname):
    '''load `fname`.csv from `working`.'''
    assert fname[-3:] == 'csv', 'Not a csv file'  
    data = etl.fromcsv(os.path.join(working, fname))
    return data

def etl_write(data, fpath):
    '''write `data` to a csv (or other if declared) file located at fpath.'''
    return etl.tocsv(data, fpath)

def iso_to_unix(row):
    iso_date = row['date']
    dt = datetime.fromisoformat(iso_date)
    return int(dt.timestamp())

def slugify_column_names(headers):
    return [slugify(header, separator='_') for header in headers]

def split_text(on, headers):
    l = []
    for header in headers:
        try:
            txt = str(header).split(on)[1]
            l.append(txt)
        except:
            l.append(header) 
    return l
