from pipelines.util import *


def employment_LAD_hexmap():
    data = etl_load(WDIR, 'cs/nomis-lad.csv')
    data = etl.select(data, "{variable_name} == 'Employment rate - aged 16-64' and {measures_code} == '20599' and {measures_name} == 'Variable' and {theme} == 'employment' ")
    data = etl.cut(data, 'date', 'geography_code', 'value')
    # make na values blank strings
    data = etl.convert(data, {'value': lambda v: v if v != 'NA' else ''})
    data = etl.recast(data, key='geography_code', variablefield='date', valuefield='value', samplesize=10000)
    etl_write(data, os.path.join(TOP, 'src/themes/people-skills-future/employment/_data/employment_LAD.csv'))

def economic_inactivity_LAD_hexmap():
    data = etl_load(WDIR, 'cs/nomis-lad.csv')
    data = etl.select(data, "{variable_name} == '% who are economically inactive - aged 16-64' and {measures_code} == '20599' and {measures_name} == 'Variable' ")
    data = etl.cut(data, 'date', 'geography_code', 'value')
    # make NA values blank strings
    data = etl.convert(data, {'value': lambda v: v if v != 'NA' else ''})
    data = etl.recast(data, key='geography_code', variablefield='date', valuefield='value', samplesize=10000)
    etl_write(data, os.path.join(TOP, 'src/themes/people-skills-future/employment/_data/economic_inactivity_LAD.csv'))

if __name__ == "__main__":
    data = etl_load(WDIR, "cs/cs-true-north.csv")

    data = etl.select(data, "{variable_name} == 'Employment rate - aged 16-64' and {measures_code} == '20599' and {measures_name} == 'Variable' ")

    data = etl.cut(data, 'date', 'geography_code', 'value')

    data = etl.recast(data, key='date', variablefield='geography_code', valuefield='value')

    # convert the iso dates to unix
    data = etl.addfield(data, 'unix_timestamp', iso_to_unix)

    data = etl.addfield(data, 'decimal_date', decimal_date)

    etl_write(data, os.path.join(TOP, 'src/themes/people-skills-future/employment/_data/employment.csv'))

    ei_data = etl_load(WDIR, "cs/cs-true-north.csv")

    ei_data = etl.select(ei_data, "{variable_name} == '% who are economically inactive - aged 16-64' and {measures_name} == 'Variable' ")

    ei_data = etl.cut(ei_data, 'date', 'geography_code', 'value')

    ei_data = etl.recast(ei_data, key='date', variablefield='geography_code', valuefield='value')

    # convert the iso dates to unix
    ei_data = etl.addfield(ei_data, 'unix_timestamp', iso_to_unix)

    ei_data = etl.addfield(ei_data, 'decimal_date', decimal_date)

    etl_write(ei_data, os.path.join(TOP, 'src/themes/people-skills-future/employment/_data/economic_inactivity.csv'))

    employment_LAD_hexmap()

    economic_inactivity_LAD_hexmap()