from pipelines.util import *
import pandas as pd

def quarters_to_iso(quarter_str):
    year, qtr = quarter_str.split()
    month = (int(qtr[1])-1)*3 + 1
    return f"{year}-{month:02d}-01"
if __name__ == "__main__":
    df = pd.read_excel(os.path.join(WDIR, 'innovation-change/entry-clearance-visa-outcomes-datasets-dec-2023.xlsx'),
                       sheet_name="Data_Vis_D02", header=1)
    
    df = df.loc[(df['Visa type subgroup']=='Global Talent') & 
                (df['Case outcome']=='Issued')]
    
    df['Quarter'] = df['Quarter'].apply(quarters_to_iso)

    df['unix_timestamp'] = pd.to_datetime(df['Quarter']).astype(int)

    df = df.groupby(by=['Year', 'Quarter', 'unix_timestamp']).sum('Decisions')

    df.to_csv(os.path.join(SRC_DIR,'themes/innovation-change/_data/global_talent.csv'))
    print('Done')