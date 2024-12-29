# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 12:10:33 2024

@author: thao
"""
import pandas as pd
import pyodbc, urllib, math
from sqlalchemy import create_engine
from sqlalchemy.types import NVARCHAR

file = r"C:\Users\phanh\Downloads\Technical_Test_BI\data_sales.csv"

data_types = {'Date': 'object',
 'Store Number': 'object',
 'Store Name': 'object',
 'City': 'object',
 'Category Name': 'object',
 'Vendor Number': 'object',
 'Vendor Name': 'object'}

data = pd.read_csv(file, dtype=data_types)

data['Date'] = pd.to_datetime(data['Date'], format='%m/%d/%Y')
data['Date'] = data['Date'].dt.strftime('%Y-%m-%d')

# t1 = data[0:100]

# Columns' names in SQL Server cannot have space
data.columns = data.columns.str.replace(' ', '_')

csv_file_dest = r"C:\Users\phanh\Downloads\Technical_Test_BI\data_sales_standardized.csv"
data.to_csv(csv_file_dest)

sqlserver = urllib.parse.quote_plus(r"Driver={ODBC Driver 17 for SQL Server};Server=PTHAOKEKE\SQLEXPRESS;Database=interview_data;Trusted_Connection=Yes;")
engine = create_engine('mssql+pyodbc:///?odbc_connect={}'.format(sqlserver),fast_executemany=True)

tablename='HMD_TABLE'
schemaname = 'dbo'
txt_cols = data.select_dtypes(include = ['object']).columns
columns = {col_name: NVARCHAR for col_name in txt_cols}

start = 0
end = math.ceil(len(data)/100000)*100000
step = 500000
for i in range(start,end,step):
    data_sample = data.iloc[i:i+step,:]
    data_sample.to_sql(tablename, schema=schemaname, con=engine, index=False, if_exists='append',dtype = columns)
    print(f"Rows {i}-{i+step} done")







