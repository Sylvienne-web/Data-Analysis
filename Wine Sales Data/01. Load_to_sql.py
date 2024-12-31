import pandas as pd
import pyodbc, urllib, math
from sqlalchemy import create_engine
from sqlalchemy.types import NVARCHAR

# 1. Open csv file into defined dictionary
file = r"your_path"
data_types = {'Date': 'object',
 'Store Number': 'object',
 'Store Name': 'object',
 'City': 'object',
 'Category Name': 'object',
 'Vendor Number': 'object',
 'Vendor Name': 'object'}
data = pd.read_csv(file, dtype=data_types)

# 2. Format datetime to SQL Server's standards
data['Date'] = pd.to_datetime(data['Date'], format='%m/%d/%Y')
data['Date'] = data['Date'].dt.strftime('%Y-%m-%d')

# 3. Drop space in column names
data.columns = data.columns.str.replace(' ', '_')

# 4. Save raw data after manipulating
csv_file_dest = r"C:\your_dest_path"
data.to_csv(csv_file_dest)

# 5. Set up SQL Server & specify location to load data
sqlserver = urllib.parse.quote_plus(r"Driver={ODBC Driver 17 for SQL Server};Server=your_server;Database=your_database;Trusted_Connection=Yes;")
engine = create_engine('mssql+pyodbc:///?odbc_connect={}'.format(sqlserver),fast_executemany=True)
tablename='HMD_TABLE'
schemaname = 'dbo'
txt_cols = data.select_dtypes(include = ['object']).columns
columns = {col_name: NVARCHAR for col_name in txt_cols}

# 6. Load every 500,000 rows to SQL Server
start = 0
end = math.ceil(len(data)/100000)*100000
step = 500000
for i in range(start,end,step):
    data_sample = data.iloc[i:i+step,:]
    data_sample.to_sql(tablename, schema=schemaname, con=engine, index=False, if_exists='append',dtype = columns)
    print(f"Rows {i}-{i+step} done")







