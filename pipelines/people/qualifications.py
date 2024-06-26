from pipelines.util import *

def nvq():
    # Load data
    data = etl_load(WDIR, 'cs/cs-true-north.csv')
    # Filter data
    data = etl.select(data, lambda rec: rec.Theme == 'qualifications' and rec.measures_name == 'Variable' and rec.variable_name == '% with NVQ4+ - aged 16-64')
    # Drop "NA" values.
    data = etl.select(data, lambda row: all(v != 'NA' for v in row))
    # Keep only necessary columns
    data = etl.cut(data, "date", "geography_code", "variable_name", "value")
    # Reshape data
    data = etl.recast(data, key='date', variablefield='geography_code', valuefield='value')
    # Convert the iso dates to unix
    data = etl.addfield(data, 'unix_timestamp', iso_to_unix)
    # Write to file
    etl_write(data, os.path.join(SRC_DIR, 'themes/people-skills-future/qualifications/_data/nvq_4plus.csv'))
    return 

if __name__ == "__main__":
    nvq()