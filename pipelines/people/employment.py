from pipelines.util import *

if __name__ == "__main__":
    data = etl_load(WDIR, "cs-true-north.csv")
    data = etl.select(data, "{variable_name} == 'Employment rate - aged 16-64' and {measures_code} == '20599' and {measures_name} == 'Variable' ")
    # data = etl.melt(data, key=['date', 'geography_code'], variables='value')
    # data = etl.pivot(data, 'date', 'geography_code', 'value', sum)
    data = etl.cut(data, 'date', 'geography_code', 'value')
    data = etl.recast(data, key='date', variablefield='geography_code', valuefield='value')
    data = etl.addrownumbers(data, start=1, field='index') #@TODO convert to a unix timestamp instead.
    etl_write(data, os.path.join(TOP, 'src/themes/people-skills-future/_data/unemployment.csv'))
    print("Got unemployment data")