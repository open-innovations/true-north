from pipelines.util import *
import duckdb

URL = "https://raw.githubusercontent.com/open-innovations/yff-data-pipelines/main/data/processed/neet.csv"

if __name__ == "__main__":
    con = duckdb.connect()
    data = con.execute(f"SELECT date, sheet, age, measure, value FROM '{URL}' WHERE sheet=='People - SA' AND age=='Aged 16-24' AND measure=='People who were NEET as a percentage of people in relevant population group'").fetch_df()
    data = data.tail(1).set_index('date')
    data.to_csv(os.path.join(SRC_DIR, 'themes/people-skills-future/_data/neet.csv'))