import os
import duckdb
import petl as etl
from datetime import datetime
from slugify import slugify
import pandas as pd

#set some directory paths
THIS_DIR = os.path.dirname(__file__)
TOP = os.path.abspath(os.path.join(THIS_DIR, os.pardir))

WDIR = os.path.join(TOP, 'working')
DATA_DIR = os.path.join(TOP, 'src/_data')
SRC_DIR = os.path.join(TOP, 'src')
METADATA_DIR = os.path.join(TOP, 'metadata')

# Load the SIC-code lookup file.
sic_lookup = pd.read_csv(os.path.join(METADATA_DIR, 'SIC_section_lookup.csv'))

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

def decimal_date(row):
    timestamp = row['unix_timestamp']
    return round((timestamp / (86400*365.25)) + 1970, 2)

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

def time_updated(file_path):
    # Get the current time
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    update_line = f"{current_time}\n"

    with open(file_path, 'w') as file:
        file.writelines(update_line)
    
    print(f"Timestamp added to file {file_path}")

def add_decimal_date_to_dataframe(data, datename, div=10**9):
    '''
    ---
    Adds a decimal date column.
    ---
        data: the dataframe
        datename: the name of the date column
        div: the amount to divide the unix timestamp by, default is 10**9
    '''
    data['unix'] = pd.to_datetime(data[datename], format=f'%Y-%m-%d').astype(int).div(div).astype(int)
    data['decimal_date'] = data['unix'].div((86400*365.25)).add(1970).round(2)
    return data

def most_recent_date(data, datename):
    '''
    ---
    Get rows where the date is the most recent value
    ---
        data: pandas dataframe
        datename: the name of the date column
    '''
    assert datename in data.columns.to_list(), f"The date name: {datename} is not a column in the dataframe."
    max_date = max(data[datename])
    print(f'Getting data for {datename} == {max_date}')
    data = data[data[datename]==max_date]

    return data

def remote_file_as_dataframe(query):
    con = duckdb.connect()
    data = con.execute(query).fetchdf()
    return data

def edd_last_updated_next_updated(id):
    data = remote_file_as_dataframe(f"SELECT id, \"desc\", last_update, next_update FROM 'https://raw.githubusercontent.com/economic-analytics/edd/main/data/edd_dict.csv' WHERE id=='{id}';")
    return print(data)

def sic_code_bar_chart(IN, OUTDIR, FNAME, top=6):
    '''
    ---
    Read the raw datacity data split by sic section, and format into a bar chart
    ---
        IN: the raw data file, as downloaded from TDC
        OUTDIR: directory to store output file
        FNAME: name for the output file
        top: how many values to get.
    '''
    # Read the csv located at `IN`
    d = pd.read_csv(f'{IN}')

    # Sort values according to count, highest at the top
    d.sort_values(by='Count', ascending=False, inplace=True)

    # Take the top 6 largest counts only
    assert top <= len(d)
    d = d.head(top)

    # Add the code's full name.
    d = d.merge(sic_lookup, 'inner', on='SICHLU')

    d.to_csv(os.path.join(OUTDIR, FNAME), index=False)
    return