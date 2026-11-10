# NestBase — roadmapa projektu

Status: Fazy A–C zamknięte, Faza D w toku. Reszta — patrz checklisty niżej.

## Faza A — Research i projekt tabel ✅

- [x] Research branżowy → `research/01`–`04`
- [x] Encje od procesu biznesowego (w tym tabela `maszyny`, decyzja o braku etapu "oferty") → [`research/architecture/00-projektowanie-tabel-i-kluczy.md`](research/architecture/00-projektowanie-tabel-i-kluczy.md)
- [x] Kolumny, PK/FK, typy, normalizacja (15/15 tabel) → [`architecture/slownik-danych.md`](architecture/slownik-danych.md)
- [ ] _(opcjonalnie, tylko przy dashboardzie Poziomu 3)_ terminologia ERP/MES → `research/checklist.md`

## Faza B — Decyzje architektoniczne ✅

- [x] Organizacja obiektów bazy → jeden schemat `dbo` → [`01-organizacja-schematow.md`](research/architecture/01-organizacja-schematow.md)
- [x] Migracje → ręczne numerowane skrypty → [`02-zarzadzanie-migracjami.md`](research/architecture/02-zarzadzanie-migracjami.md)
- [x] Audyt → trigger + tabela `audyt_zmian` → [`03-mechanizm-audytu.md`](research/architecture/03-mechanizm-audytu.md)
- [x] Silnik walidacji → typ reguły + stałe procedury → [`04-silnik-walidacji.md`](research/architecture/04-silnik-walidacji.md)
- [x] Staging → jedna tabela `staging_import` → [`05-struktura-stagingu.md`](research/architecture/05-struktura-stagingu.md)
- [x] Rozkrój → shelf packing "półkami" → [`06-model-rozkroju.md`](research/architecture/06-model-rozkroju.md)
- [x] Dashboard (Poziom 3) → Power BI Desktop
- [ ] Otwarte: nazwa projektu, język README — nie blokuje Fazy C

Pełne uzasadnienie każdej decyzji: [`research/architecture/checklist.md`](research/architecture/checklist.md). Odzwierciedlone jako wersja ostateczna w [`architecture/architecture.md`](architecture/architecture.md) i [`architecture/quality-tools.md`](architecture/quality-tools.md).

## Faza C — Środowisko ✅

- [x] Git/GitHub
- [x] Python 3.12 + `uv` (`pyodbc`, `pandas`, `Faker`, `openpyxl`, `fpdf2`) → `tools/pyproject.toml`
- [x] `black`/`ruff`/`pytest` skonfigurowane
- [x] `pre-commit` (ogólne hooki + black/ruff/pytest + własny `sql-naming-convention`)
- [x] `commitlint` (Conventional Commits, hook `commit-msg`)
- [x] Docker Desktop + `docker-compose.yml` (SQL Server 2022)
- [x] SSMS 22, ODBC Driver 18
- [ ] tSQLt zainstalowany w bazie
- [ ] Szkielet GitHub Actions (checkout → kontener → migracje → `tSQLt.RunAll`)
- [ ] Skrypty PowerShell (`scripts/setup.ps1`, `migrate.ps1`, `reset-db.ps1`)

## Faza D — Poziom 1

- [x] Schemat bazy wdraża się od zera jednym przebiegiem (`db/migrations/V001__...`, 14/14 tabel, zweryfikowane)
- [x] ERD (`docs/architecture/erd.md`)
- [x] README
- [x] Generator danych testowych z wstrzykniętymi błędami (`tools/generate_data.py`)
- [ ] Min. 20 zapytań raportowych/walidacyjnych z komentarzem biznesowym
- [ ] Staging + walidacja + raport błędów, wykrywający realnie wstrzyknięte błędy
- [ ] Bezpieczna korekta danych w transakcji (`SELECT` → `BEGIN TRAN` → `UPDATE...OUTPUT` → `COMMIT`/`ROLLBACK`)

DoD: schemat się wdraża, dane się ładują, 20 zapytań ma sens, walidacja łapie błędy, korekta ma widoczną ścieżkę transakcyjną, README działa.

## Faza E — Poziom 2

- [ ] tSQLt, min. 15 testów + przypadki brzegowe (NULL, zero, remisy)
- [ ] Audyt (`audyt_zmian` + trigger), log pokazuje kto/kiedy/co
- [ ] Eksport pliku maszynowego (CSV/XML) i karty zlecenia (PDF) po korekcie
- [ ] Raport przed/po na konkretnym przykładzie
- [ ] Raport Excel z tabelą przestawną
- [ ] Runbook (`docs/architecture/runbook.md`)

DoD: `tSQLt.RunAll` zielone, audyt pokazuje kto/kiedy/co, plik/PDF regeneruje się po korekcie, raport przed/po pokazuje różnicę.

## Faza F — Poziom 3

- [ ] Pełny pipeline GitHub Actions z badge w README
- [ ] Rollbacki przetestowane dla każdej migracji
- [ ] Test wydajnościowy na milionie wierszy (plan z indeksem i bez)
- [ ] Dashboard w Power BI Desktop

DoD: CI przechodzi na pustym środowisku, rollback przetestowany, test na dużej skali ma porównanie planów.

---

## Poza zakresem

- prawdziwa optymalizacja rozkroju (bin packing) — model jest uproszczony,
- integracja z realną maszyną CNC,
- wielu użytkowników/role security w bazie,
- UI/frontend jako pełna aplikacja.

## Ryzyka

- Logika biznesowa (walidacja, agregacje, korekty, raporty) ma być w T-SQL, nie w Pythonie.
- Rozkrój uproszczony musi być jasno opisany w README.
- tSQLt nie tylko oczywiste przypadki.
- Sprawdzać adnotację "Poziom złożoności" przed każdą decyzją — przeinżynierowanie jest złe tak samo jak zbyt prosty projekt.
- Koszt materiału liczyć proporcjonalnie z całego arkusza, nie z powierzchni samej części.
- Bez kolumn audytowych (`created_at`, `is_deleted`) na tabelach domenowych — to robi `audyt_zmian`.
