# NestBase — architektura

## 1. Architektura przepływu danych (logiczna, docelowa)

```
                 ┌────────────────┐
  CSV z paczką   │  staging_import │  (bez ograniczeń integralności)
  danych ───────▶│                 │
                 └────────┬────────┘
                          │  reguly_walidacji (typ reguły + parametry, bez dynamicznego SQL)
                          ▼
                 ┌─────────────────┐
                 │ wyniki_walidacji│──▶ raport błędów (Excel/HTML)
                 └────────┬────────┘
                          │ tylko wiersze bez błędów krytycznych
                          ▼
          ┌───────────────────────────────┐
          │  tabele docelowe (3NF):        │
          │  klienci, zamowienia,          │
          │  pozycje_zamowienia, materialy,│
          │  grubosci_materialow, arkusze  │
          └───────────────┬────────────────┘
                           │ procedury/funkcje T-SQL (kalkulacja, rozkrój)
                           ▼
          ┌───────────────────────────────┐
          │ zlecenia_ciecia + rozkroj     │
          │ pomiary_jakosci                │
          └───────────────┬────────────────┘
                           │ korekta w transakcji (SELECT → UPDATE OUTPUT → audyt)
                           ▼
          ┌───────────────────────────────┐
          │ audyt_zmian                    │──▶ raport przed/po
          │ pliki_maszynowe (CSV/XML)     │──▶ regeneracja po korekcie
          │ wydruki (PDF)                  │
          └───────────────────────────────┘
```

Zasada: dane nigdy nie wchodzą do tabel docelowych bez przejścia przez staging + walidację. Każda korekta w tabelach docelowych **musi** przejść przez ścieżkę audytu i wywołać regenerację powiązanych artefaktów (plik maszynowy, PDF, raport).

## 2. Organizacja obiektów bazy — jeden schemat `dbo`, bez prefiksów

Wszystkie tabele/procedury/funkcje/widoki żyją w domyślnym schemacie `dbo`, bez dodatkowych `CREATE SCHEMA`. Rozróżnienie obszarów (dane domenowe / staging / walidacja / audyt) wynika z samej nazwy tabeli (`staging_import`, `reguly_walidacji`, `wyniki_walidacji`, `pliki_maszynowe`) i z lokalizacji w repo (sekcja 3), **nie** z prefiksów w nazwach obiektów SQL.

tSQLt (gdy zostanie zainstalowany, Faza E) instaluje się automatycznie we własnym schemacie `tSQLt` — nie dotykać ręcznie.

## 3. Struktura repozytorium — stan aktualny

```
NestBase/
├── README.md
├── docker-compose.yml
├── .env / .env.example
├── .gitignore
├── .pre-commit-config.yaml
├── package.json / package-lock.json      # commitlint
├── commitlint.config.js
├── docs/
│   ├── ROADMAP.md
│   ├── plan/                 # description.md, cel-aplikacji.md
│   ├── architecture/          # ten plik, stack.md, quality-tools.md, erd.md, slownik-danych.md
│   └── research/              # wiedza branżowa + decyzje architektoniczne (01–06), research przygotowany z pomocą Claude
├── db/
│   ├── migrations/
│   │   └── V001__initial_schema.sql     # wszystkie 15 tabel Poziomu 1, jedną migracją
│   ├── rollback/
│   │   └── R001__schema_poziom1.sql
│   └── tests/                 # puste — tSQLt, Faza E
├── tools/                      # uv project — warstwa pomocnicza Python
│   ├── pyproject.toml          # zależności: pyodbc, pandas, faker, openpyxl, fpdf2 + dev: black/ruff/pytest/pre-commit
│   ├── uv.lock
│   └── check_sql_naming.py     # hook pre-commit: konwencja nazw ograniczeń SQL
├── reports/                     # puste — Faza D/E (baseline/samples jako podkatalogi, gdy dojdą pierwsze raporty)
├── sql/                          # materiały własne do nauki SQL, poza publicznym repo (.gitignore)
└── .github/
    └── workflows/                # puste — szkielet CI w Fazie C/F
```

`tools/generate_data.py`, `run_validation.py`, `export_files.py`, `db.py` (wspólne połączenie `pyodbc`) są **planowane**, nie istnieją jeszcze — pierwszy krok to `generate_data.py`, patrz [`ROADMAP.md`](../ROADMAP.md) Faza D i `sql/nauka/03-generator-danych-testowych.md`. Podobnie `db/procedures/` i `db/views/` jeszcze nie istnieją — założy je pierwsza procedura/widok w Fazie D.

### Uzasadnienie decyzji

- **Migracje numerowane, nigdy edytowane po scaleniu** — umożliwia odtworzenie dowolnego stanu bazy i jasną historię zmian schematu. Wykonywane ręcznie (`sqlcmd`/SSMS), bez dodatkowego narzędzia migracyjnego (porównanie opcji: [`research/architecture/02-zarzadzanie-migracjami.md`](../research/architecture/02-zarzadzanie-migracjami.md)).
- **Rollback 1:1 z migracją, pisany od razu** — `R001` istnieje już razem z `V001`, nie czekaliśmy do Poziomu 3.
- **`db/tests/` ma odzwierciedlać strukturę `db/procedures/`**, gdy obie się zapełnią — ułatwia znalezienie testu dla danej procedury.
- **`tools/db.py` jako jeden punkt połączenia** (gdy powstanie) — unika duplikacji connection stringa w kilku skryptach, bez budowania całej warstwy ORM.

## 4. Konwencje nazewnictwa

| Obiekt           | Konwencja                                 | Przykład                                 | Stan                                                           |
| ---------------- | ----------------------------------------- | ---------------------------------------- | -------------------------------------------------------------- |
| Tabela           | `snake_case`, liczba mnoga, PL            | `pozycje_zamowienia`                     | stosowane w `V001`                                             |
| Ograniczenie     | prefiks `PK_`/`FK_`/`CK_`/`UQ_`/`DF_`     | `PK_klienci`, `FK_zamowienia_klienta`    | stosowane w `V001`, sprawdzane hookiem `sql-naming-convention` |
| Kolumna PK       | `id`                                      | `zamowienia.id`                          | stosowane                                                      |
| Kolumna FK       | `<tabela_w_liczbie_pojedynczej>_id`       | `klient_id`, `material_id`               | stosowane                                                      |
| Procedura        | `sp_<Czasownik><Rzeczownik>`              | `sp_RunValidation`, `sp_ApplyCorrection` | planowane — brak procedur jeszcze                              |
| Funkcja skalarna | `fn_<Nazwa>`                              | `fn_PowierzchniaCzesci`                  | planowane                                                      |
| Widok            | `vw_<Nazwa>`                              | `vw_RaportWykorzystaniaArkusza`          | planowane                                                      |
| Test tSQLt       | klasa testowa = nazwa testowanego obiektu | `test_fn_PowierzchniaCzesci`             | planowane                                                      |
| Plik migracji    | `V<NNN>__<opis_snake_case>.sql`           | `V001__initial_schema.sql`               | stosowane                                                      |

## 5. Decyzje zamknięte (Faza B, [`ROADMAP.md`](../ROADMAP.md))

- **Jeden schemat `dbo`, bez prefiksów** (sekcja 2) → [`research/architecture/01-organizacja-schematow.md`](../research/architecture/01-organizacja-schematow.md)
- **Ręczne numerowane migracje**, bez Flyway/DbUp/SSDT → [`02-zarzadzanie-migracjami.md`](../research/architecture/02-zarzadzanie-migracjami.md)
- **Trigger + tabela `audyt_zmian`** jako audyt (nie temporal tables/CDC) → [`03-mechanizm-audytu.md`](../research/architecture/03-mechanizm-audytu.md)
- **Reguły walidacji jako typ + parametry, nie dynamiczny SQL** → [`04-silnik-walidacji.md`](../research/architecture/04-silnik-walidacji.md); patrz `quality-tools.md` sekcja 3
- **Jedna uniwersalna tabela `staging_import`** → [`05-struktura-stagingu.md`](../research/architecture/05-struktura-stagingu.md)
- **Shelf packing "półkami"** (rozkrój świadomie uproszczony, nie prawdziwy nesting 2D) → [`06-model-rozkroju.md`](../research/architecture/06-model-rozkroju.md)
- Docker vs. natywna instalacja SQL Server — patrz `stack.md`; obecnie używany Docker (`docker-compose.yml`, kontener `nestbase-sql`).
