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


LICZBA_WIERSZY = 500
PLAN_BLEDOW = {
    "sierota": 15,
    "duplikat": 10,
    "wartosc_ujemna": 8,
    "tekst_w_liczbie": 5,
}


def wstrzyknij_blad(wiersz: dict, typ_bledu: str) -> None:
    if typ_bledu == "sierota":
        wiersz["material_nazwa"] = "Material_Ktory_Nie_Istnieje"
    elif typ_bledu == "wartosc_ujemna":
        wiersz["cena_jednostkowa"] = "-10.00"
    elif typ_bledu == "tekst_w_liczbie":
        wiersz["grubosc_mm"] = "dwa"
    else:
        raise ValueError(f"Nieznany typ błędu do wstrzyknięcia jednowierszowo: {typ_bledu}")


def wygeneruj_wiersze(materialy: list[str]) -> tuple[list[dict], dict[str, int]]:
    wiersze = [wiersz_bazowy(i + 1, materialy) for i in range(LICZBA_WIERSZY)]

    bledy_jednowierszowe = {typ: ile for typ, ile in PLAN_BLEDOW.items() if typ != "duplikat"}
    liczba_duplikatow = PLAN_BLEDOW["duplikat"]

    pozycje = random.sample(
        range(LICZBA_WIERSZY),
        k=sum(bledy_jednowierszowe.values()) + 2 * liczba_duplikatow,
    )
    i = 0

    for typ_bledu, ile in bledy_jednowierszowe.items():
        for _ in range(ile):
            wstrzyknij_blad(wiersze[pozycje[i]], typ_bledu)
            i += 1

    wstrzykniete_duplikaty = 0
    for _ in range(liczba_duplikatow):
        source_idx, target_idx = pozycje[i], pozycje[i + 1]
        i += 2
        wiersze[target_idx]["klient_nazwa"] = wiersze[source_idx]["klient_nazwa"]
        wiersze[target_idx]["klient_miasto"] = wiersze[source_idx]["klient_miasto"]
        wstrzykniete_duplikaty += 1

    wstrzykniete = dict(bledy_jednowierszowe)
    wstrzykniete["duplikat"] = wstrzykniete_duplikaty
    return wiersze, wstrzykniete


KOLUMNY = [
    "nazwa_pliku",
    "numer_wiersza",
    "data_importu",
    "klient_nazwa",
    "klient_miasto",
    "klient_region",
    "zamowienie_data",
    "zamowienie_status",
    "material_nazwa",
    "nazwa_czesci",
    "grubosc_mm",
    "szerokosc_mm",
    "wysokosc_mm",
    "dlugosc_ciecia_mm",
    "liczba_przebic",
    "ilosc",
    "cena_jednostkowa",
]


def zapisz(conn: pyodbc.Connection, wiersze: list[dict]) -> None:
    cursor = conn.cursor()
    placeholders = ", ".join(["?"] * len(KOLUMNY))
    cursor.executemany(
        f"INSERT INTO dbo.staging_import ({', '.join(KOLUMNY)}) VALUES ({placeholders})",
        [tuple(w[kolumna] for kolumna in KOLUMNY) for w in wiersze],
    )
    conn.commit()


def main() -> None:
    random.seed(42)  # powtarzalność między uruchomieniami

    conn = connect()
    try:
        materialy = pobierz_materialy(conn)
        wiersze, wstrzykniete = wygeneruj_wiersze(materialy)
        zapisz(conn, wiersze)
    finally:
        conn.close()

    print(f"Wstawiono {len(wiersze)} wierszy do dbo.staging_import.")
    print(f"Wstrzyknięte błędy (oczekiwany wynik walidacji): {wstrzykniete}")


if __name__ == "__main__":
    main()
