"""Generator danych testowych do dbo.staging_import."""

import os

import pyodbc


def connect() -> pyodbc.Connection:
    return pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=localhost,1433;DATABASE=NestBase;UID=sa;"
        f"PWD={os.environ['MSSQL_SA_PASSWORD']};TrustServerCertificate=yes;"
    )


if __name__ == "__main__":
    conn = connect()
    print("Połączono z bazą:", conn.getinfo(pyodbc.SQL_DATABASE_NAME))
    conn.close()
