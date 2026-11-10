# NestBase — quality-tools (ostateczne, Faza B zamknięta)

## 1. Jakość kodu T-SQL

| Narzędzie                                                 | Co robi                                                           | Kiedy użyć                                                                                                                           |
| --------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **tSQLt**                                                 | testy jednostkowe procedur/funkcji/widoków                        | obowiązkowo — patrz `stack.md`                                                                                                       |
| **SQL formatowanie — ręczna konwencja + `.editorconfig`** | ujednolicony styl (wielkość liter na słowach kluczowych, wcięcia) | ustalić konwencję w README/`docs/architecture/runbook.md` zamiast dedykowanego narzędzia — mniejszy narzut niż integracja formattera |
| **tsqllint** (OSS linter T-SQL, opcjonalnie)              | statyczna analiza stylu (np. `SELECT *`, brak `SET NOCOUNT ON`)   | dodatek "jeśli zostanie czas" w Poziomie 3 — nie wymagane, żeby projekt wypadł dobrze                                                |
| **Execution plan / `SET STATISTICS IO, TIME ON`**         | sprawdzanie planów zapytań                                        | opcjonalnie, tylko przy teście wydajnościowym w Poziomie 3                                                                           |

## 2. Jakość kodu Python (warstwa pomocnicza — generator danych, walidacja, eksporty; nie sedno projektu)

| Narzędzie                    | Co robi                                                                                                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **black**                    | automatyczne formatowanie kodu, zero dyskusji o stylu                                                                                                                    |
| **ruff**                     | szybki linter, łapie nieużywane importy i proste błędy stylu                                                                                                             |
| **pytest**                   | testy jednostkowe funkcji w `tools/` (np. funkcja licząca checksumę pliku maszynowego, funkcja walidująca pojedynczy wiersz) — odpowiednik tSQLt, ale dla warstwy Python |
| **pre-commit** (opcjonalnie) | hook uruchamiający `uv run black`/`uv run ruff check`/`uv run pytest -q` przed każdym commitem — dobra praktyka do pokazania, ale nie krytyczna, jeśli zabiera czas      |

## 3. Jakość danych (serce projektu)

| Mechanizm                                             | Co robi                                                                                                                                                                                                                                               | Gdzie w repo                                                                  |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **Tabela `val_reguly_walidacji` jako "silnik reguł"** | reguła = typ (np. `wartosc_dodatnia`, `brak_sieroty`, `duplikat`) + parametry (tabela/kolumna), wykonywana przez skończoną listę prostych, stałych procedur — **nie dynamiczny SQL**, żeby nie wprowadzać ryzyka SQL injection i trzymać testy proste | `db/procedures/walidacja/` + dane w `val_reguly_walidacji`                    |
| **Staging + kontrola przed załadowaniem**             | dane z CSV nie trafiają od razu do tabel docelowych, tylko do `staging_import` bez ograniczeń, potem walidacja                                                                                                                                        | `tools/run_validation.py`, procedura `sp_ValidateStaging` (przykładowa nazwa) |
| **Raport błędów walidacji**                           | `wyniki_walidacji` + eksport do Excela/HTML z podsumowaniem liczby błędów per reguła                                                                                                                                                                  | `reports/`                                                                    |
| **Niezależne przeliczenie wyników**                   | druga ścieżka liczenia tego samego wyniku (inny zapytanie/inna metoda), porównanie z wynikiem procedury — wykrywa błędy logiki, nie tylko błędy danych                                                                                                | test w `db/tests/` kategorii "cross-check"                                    |
| **Testy regresyjne po zmianie cennika/reguły**        | pełny zestaw tSQLt + scenariusze porównywane z poprzednim wynikiem (snapshot)                                                                                                                                                                         | `db/tests/`, zapisany wynik referencyjny w `reports/baseline/`                |
| **Audyt zmian**                                       | `aud_audyt_zmian` przez trigger `AFTER UPDATE/DELETE` — każda korekta jest odtwarzalna (kto/kiedy/co, pole-po-polu, zgodnie z `slownik-danych.md`)                                                                                                              | `db/procedures/audyt/`                                                        |
| **Checksuma pliku maszynowego**                       | wykrywa, czy plik faktycznie się zmienił po korekcie (pole `suma_kontrolna` w `pliki_maszynowe`)                                                                                                                                                      | `tools/export_files.py`                                                       |

### 3.1 Przykładowe reguły (katalog startowy dla `reguly_walidacji`)

- cena, wymiary, ilość i grubość większe od zera (`wartosc_dodatnia`),
- grubość dostępna dla wybranego materiału (jest w `grubosci_materialow`),
- część mieści się w największym dostępnym arkuszu,
- klient i materiał istnieją (`brak_sieroty`),
- duplikaty klientów — ta sama nazwa i miasto (`duplikat`),
- zamówienia bez pozycji i pozycje bez zlecenia,
- suma w paczce danych zgodna z sumą policzoną z pozycji (`suma_zgodna`),
- braki (NULL) w polach wymaganych,
- zmierzony wymiar poza tolerancją bez oznaczenia "odrzut" (`poza_tolerancja`),
- wartości tekstowe, których nie da się zamienić na liczbę (`TRY_CONVERT`) — stąd kolumny `staging_import` jako `NVARCHAR`, nie `DECIMAL`/`DATE` (patrz `slownik-danych.md`).

Wyniki trafiają do `wyniki_walidacji` i do raportu (Excel/HTML) z podsumowaniem i szczegółami błędów.

## 4. CI jako warstwa spinająca wszystko

Pipeline w GitHub Actions (patrz `stack.md`) powinien odpalać w tej kolejności:

1. `uv sync` (instalacja zależności z locka),
2. lint Python (`uv run ruff check`, `uv run black --check .`),
3. `uv run pytest` dla `tools/`,
4. start kontenera SQL Server,
5. wdrożenie migracji (`sqlcmd -i db/migrations/...`),
6. instalacja tSQLt + załadowanie danych testowych (`uv run python tools/generate_data.py`),
7. `EXEC tSQLt.RunAll`,
8. (opcjonalnie) `tsqllint` jako krok informacyjny, nie blokujący na starcie.

## 5. Minimalny zestaw

Nie trzeba od razu wdrażać wszystkiego z tej listy. Na Poziom 1 wystarczy:

- reguły walidacji jako dane (typ + parametry) + raport błędów (główny priorytet — to jest SQL),
- `uv run pytest` na kluczowych funkcjach Pythona,
- `uv run black`/`uv run ruff check` lokalnie (bez pre-commit).
