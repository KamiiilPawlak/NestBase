"""Generator danych testowych do dbo.staging_import."""

import os
import random
from datetime import datetime, timedelta

import pyodbc
from faker import Faker

fake = Faker("pl_PL")


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


def wiersz_bazowy(numer_wiersza: int, materialy: list[str]) -> dict:
    """Jeden poprawny wiersz staging_import - bez błędów."""
    grubosc = random.choice([3.0, 5.0])
    return {
        "nazwa_pliku": "generated_test_data.csv",
        "numer_wiersza": numer_wiersza,
        "data_importu": datetime.now() - timedelta(days=random.randint(0, 30)),
        "klient_nazwa": fake.company(),
        "klient_miasto": fake.city(),
        "klient_region": fake.region(),
        "zamowienie_data": fake.date_this_year().isoformat(),
        "zamowienie_status": random.choice(
            ["nowe", "potwierdzone", "w_realizacji", "zakonczone", "anulowane"]
        ),
        "material_nazwa": random.choice(materialy),
        "nazwa_czesci": fake.word(),
        "grubosc_mm": str(grubosc),
        "szerokosc_mm": str(round(random.uniform(50, 1200), 1)),
        "wysokosc_mm": str(round(random.uniform(50, 1200), 1)),
        "dlugosc_ciecia_mm": str(round(random.uniform(200, 5000), 1)),
        "liczba_przebic": str(random.randint(1, 20)),
        "ilosc": str(random.randint(1, 50)),
        "cena_jednostkowa": str(round(random.uniform(10, 500), 2)),
    }


if __name__ == "__main__":
    conn = connect()
    materialy = pobierz_materialy(conn)
    conn.close()

    print("Przykładowy wiersz:", wiersz_bazowy(1, materialy))
