# NestBase — stack technologiczny

## 1. Baza danych

| Element                        | Decyzja                                                                                               | Uzasadnienie                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------------------------------ | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Silnik                         | **Microsoft SQL Server 2022** (Developer Edition, obraz `mcr.microsoft.com/mssql/server:2022-latest`) | darmowa, pełna funkcjonalność, standard branżowy dla tej skali projektu                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Środowisko lokalne             | **Docker Desktop**                                                                                    | identyczne środowisko lokalnie i w CI (ten sam obraz) — brak "works on my machine". _Sprawdzone lokalnie: Docker Desktop zainstalowany (v29.8.0); silnik odpalany na start pracy, nie działa w tle stale._ Natywna instalacja SQL Server jest też obecna na maszynie (usługa `MSSQLSERVER`), ale **nie jest** głównym środowiskiem projektu — zostaje jako zapasowa opcja offline, nieużywana w standardowym workflow.                                                                                                          |
| Klient/IDE                     | **SSMS 22**                                                                                           | _Sprawdzone lokalnie: SSMS 22 zainstalowane (`C:\Program Files\Microsoft SQL Server Management Studio 22\...`) — poprawka po wcześniejszym błędnym sprawdzeniu, które szukało tylko w `Program Files (x86)` i wersji 19/20._ Najdojrzalszy GUI do pisania/debugowania T-SQL, bez konta/dostępu do Azure. VS Code jest też zainstalowany z `ms-mssql.mssql`, `ms-mssql.sql-database-projects-vscode`, `prettier-sql-vscode` — dobry do commitowania skryptów `.sql` razem z resztą repo, ale pomocniczo, nie jako główny klient. |
| Zarządzanie schematem/migracje | ręczne, numerowane skrypty SQL (`V001__...sql`), opisane w `architecture.md`                          | prostota, pełna kontrola nad T-SQL, zero nowego narzędzia do nauki — dobrze pokazuje zrozumienie samej idei migracji. (Flyway/DbUp/SSDT świadomie nieużywane — porównanie w `research/architecture/02-zarzadzanie-migracjami.md`; rozszerzenie `sql-database-projects-vscode` jest dostępne w VS Code, ale nie jest w tym projekcie wykorzystywane, żeby nie dublować decyzji o migracjach.)                                                                                                                                    |

## 2. Testy bazy danych

| Element                              | Decyzja                                         | Uzasadnienie                                                                                            |
| ------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Framework testów jednostkowych T-SQL | **tSQLt**                                       | standard w ekosystemie SQL Server, izolacja przez `FakeTable`/`SpyProcedure`, czytelny raport PASS/FAIL |
| Uruchamianie testów                  | `EXEC tSQLt.RunAll` lokalnie, ten sam krok w CI | jeden mechanizm, bez duplikacji logiki                                                                  |

## 3. Warstwa skryptowa (Python — pomocnicza, nie sedno projektu)

| Element                              | Decyzja                                                       | Uzasadnienie                                                                                                                                                                                                          |
| ------------------------------------ | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Wersja                               | **Python 3.12**                                               | _Sprawdzone lokalnie: zainstalowany Python 3.12.10._                                                                                                                                                                  |
| Sterownik do SQL Server              | **pyodbc** + **ODBC Driver 18 for SQL Server**                | _Sprawdzone lokalnie: ODBC Driver 17 i 18 już zainstalowane; `pyodbc` jeszcze nie — doda się przez `uv add` w ramach `tools/pyproject.toml`._ Najbardziej standardowy łącznik do MSSQL w Pythonie.                    |
| Dane tabelaryczne / generator danych | **pandas** + `Faker` (do realistycznych nazw klientów, miast) | szybkie generowanie i manipulacja danymi testowymi z błędami                                                                                                                                                          |
| Raport Excel                         | **openpyxl**                                                  | zapis `.xlsx` z formatowaniem i tabelą przestawną                                                                                                                                                                     |
| PDF (karty zlecenia)                 | **fpdf2**                                                     | lekkie generowanie PDF z szablonu, jedna zależność, bez dodatkowego layoutu HTML (odrzucono `weasyprint` — cięższa zależność niepotrzebna na tę skalę, i `reportlab` — więcej API do ogarnięcia niż daje tu wartości) |
| Zarządzanie zależnościami            | **uv** (`pyproject.toml` + `uv.lock`)                         | _Sprawdzone lokalnie: `uv` już zainstalowane._ Szybki, jeden plik lock, `uv run` zamiast ręcznego aktywowania `venv`                                                                                                  |

## 4. Raporty i analiza

| Element                           | Decyzja                                            | Uzasadnienie                                                                                                                                                                                             |
| --------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Raport podstawowy                 | widoki SQL + eksport do Excela (tabela przestawna) | pokrywa wymóg raportowania (min. 20 zapytań, raport Excel) bez dodatkowej infrastruktury                                                                                                                 |
| Dashboard (Poziom 3, opcjonalnie) | **Power BI Desktop**                               | bezpłatne do lokalnego użytku (tylko publikacja w Power BI Pro/Premium jest płatna — nieużywana tutaj); natywne podłączenie do SQL Server, mniej kodu niż własna strona HTML — patrz `ROADMAP.md` Faza F |

## 5. CI/CD

| Element               | Decyzja                                                                                                                                                                     | Uzasadnienie                                                                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| CI                    | **GitHub Actions**                                                                                                                                                          | darmowe dla publicznego repo, natywna integracja z GitHub                              |
| Kontener testowy w CI | ten sam obraz `mcr.microsoft.com/mssql/server:2022-latest` jako `services:` w workflow                                                                                      | identyczny obraz lokalnie (Docker, sekcja 1) i w CI — jedno źródło prawdy o środowisku |
| Kroki workflow        | checkout → start kontenera SQL Server → `sqlcmd` ładuje migracje i tSQLt → `sqlcmd`/skrypt Python ładuje dane testowe → `EXEC tSQLt.RunAll` → publikacja wyniku (badge/log) | odwzorowuje realny pipeline CI dla bazy danych                                         |

## 6. Kontrola wersji i dokumentacja

| Element             | Decyzja                                                                                                                      |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| VCS                 | Git + GitHub (publiczne repo)                                                                                                |
| Diagramy ERD        | Mermaid w Markdown (`docs/architecture/erd.md`) — renderuje się natywnie na GitHub, zero zależności od zewnętrznych narzędzi |
| Format dokumentacji | Markdown w `docs/`                                                                                                           |
| Research branżowy   | przygotowany z pomocą **Claude** (Anthropic) jako asystenta researchu/pisania dokumentacji — decyzje i uzasadnienia recenzowane przez autora |

## 7. Minimalny zestaw do zainstalowania — stan lokalny

| #   | Narzędzie                              | Stan na tej maszynie (sprawdzone 2026-11-07)                                                                          |
| --- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 1   | Docker Desktop + obraz SQL Server 2022 | ✅ Docker Desktop zainstalowany (v29.8.0); obraz pobiera się przy pierwszym `docker compose up`                       |
| 2   | SSMS 22                                | ✅ zainstalowane                                                                                                      |
| 3   | ODBC Driver 18 for SQL Server          | ✅ zainstalowany                                                                                                      |
| 4   | Python 3.12 zarządzany przez `uv`      | ✅ oba zainstalowane; zależności (`pyodbc`, `pandas`, `openpyxl`, `fpdf2`, `faker`) jeszcze do dodania przez `uv add` |
| 5   | tSQLt (`tSQLt.class.sql`)              | ⏳ do zainstalowania w bazie, w ramach migracji                                                                       |
| 6   | Git                                    | ✅ (repo już istnieje)                                                                                                |

Szczegóły narzędzi jakości (linting, formatowanie, statyczna analiza) są w [`quality-tools.md`](quality-tools.md). Status projektu i kolejne kroki — [`ROADMAP.md`](../ROADMAP.md).
