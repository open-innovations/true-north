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

def time_updated(file_path, where):
    # Get the current time
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    update_line = f"updated: {current_time}\n"

    
    # Read the file and modify its contents
    with open(file_path, 'r') as file:
        lines = file.readlines()
    
    # Find the line with "updated:" and update it
    for i, line in enumerate(lines):
        if line.startswith("updated:"):
            lines[i] = update_line
            break
    else:
        # If "updated:" is not found, find `where` and insert after it
        for i, line in enumerate(lines):
            if where in line:
                lines.insert(i + 1, update_line)
                break
    
    # Write the modified contents back to the file
    with open(file_path, 'w') as file:
        file.writelines(lines)
    
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