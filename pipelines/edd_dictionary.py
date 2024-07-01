from util import *
import os 

QUERY = f"SELECT * FROM 'https://raw.githubusercontent.com/economic-analytics/edd/main/data/edd_dict.csv';"

if __name__ == '__main__':
    print(os.getcwd())
    data = remote_file_as_dataframe(QUERY)
    # print(data['id'].unique())
    data.set_index('id', inplace=True)
    # print(data.index)
    with open('src/_data/edd_dictionary.yaml', 'w') as file:
        for id in data.index:
            last_update = data.loc[id, 'last_update']
            next_update = data.loc[id, 'next_update']
            desc = data.loc[id, 'desc']
            url = data.loc[id, 'url']
            if type(last_update) != str:
                continue
            file.writelines(f"{id}:\n  last_update: '{last_update}'\n  next_update: '{next_update}'\n  desc: '{desc}'\n  url: '{url}'\n")
    print('Finished')