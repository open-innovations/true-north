from pipelines.util import *
import pandas as pd

if __name__ == "__main__":
    data = pd.read_excel(os.path.join(WDIR, 'true-north/northern_stars.xlsx'))
    # sort values by date, descending
    data.sort_values('date_published', inplace=True, ascending=False)
    data.to_csv(os.path.join(SRC_DIR, '_data/dashboard/northern_stars.csv'))