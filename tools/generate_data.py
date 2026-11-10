"""Generator danych testowych do dbo.staging_import."""

import os

import pyodbc


def connect() -> pyodbc.Connection:
    return pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=localhost,1433;DATABASE=NestBase;UID=sa;"
        f"PWD={os.environ['MSSQL_SA_PASSWORD']};TrustServerCertificate=yes;"
    )


def pobierz_materialy(conn: pyodbc.Connection) -> list[str]:
    cursor = conn.cursor()
    cursor.execute("SELECT nazwa FROM dbo.materialy")
    nazwy = [row.nazwa for row in cursor.fetchall()]
    if not nazwy:
        raise RuntimeError(
            "Tabela dbo.materialy jest pusta - uruchom najpierw V002__seed_reference_data.sql."
        )
    return nazwy


if __name__ == "__main__":
    conn = connect()
    print("Materiały w bazie:", pobierz_materialy(conn))
    conn.close()
