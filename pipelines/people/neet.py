from pipelines.util import *

HEADLINE_URL = "https://raw.githubusercontent.com/open-innovations/yff-data-pipelines/main/data/processed/neet.csv"

LOCAL_AUTHORITY_URL = "https://raw.githubusercontent.com/open-innovations/yff-data-pipelines/main/data/processed/yff/neet-factors.csv"

def total_neet_16_24():
    con = duckdb.connect()
    data = con.execute(f"SELECT date, sheet, age, measure, value FROM '{HEADLINE_URL}' WHERE sheet=='People - SA' AND age=='Aged 16-24' AND measure=='People who were NEET as a percentage of people in relevant population group'").fetch_df()
    data = data.tail(1).set_index('date')
    data.to_csv(os.path.join(SRC_DIR, 'themes/people-skills-future/_data/neet.csv'))
    return
    
def neet_by_local_authority():
    con = duckdb.connect()
    data = con.execute(f"SELECT * FROM '{LOCAL_AUTHORITY_URL}' WHERE variable=='Total Score'").fetchdf()
    data.to_csv(os.path.join(SRC_DIR, 'themes/people-skills-future/_data/risk_of_neet_by_la.csv'), index=False)

if __name__ == "__main__":
    total_neet_16_24()
    neet_by_local_authority()