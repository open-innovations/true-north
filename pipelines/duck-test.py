import duckdb

con = duckdb.connect()

url = 'https://github.com/economic-analytics/edd/raw/main/data/parquet/UCST.parquet'

data = con.execute(f"SELECT * FROM read_parquet('{url}')").fetchdf()

print(data)