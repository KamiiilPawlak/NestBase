# NestBase

NestBase to baza danych Microsoft SQL Server / T-SQL dla małego zakładu cięcia blach laserem/CNC: zamówienia → kalkulacja → rozkrój → zlecenia produkcyjne → kontrola jakości → walidacja danych → audyt korekt → pliki maszynowe/raporty.

Skupia się na modelowaniu danych z integralnością, logice biznesowej w T-SQL, walidacji i bezpiecznych korektach, audycie zmian oraz testach automatycznych — to tu jest clou, nie w realnym wdrożeniu produkcyjnym.

Pełny cel, zasady i zakres: [`docs/plan/description.md`](docs/plan/description.md); scenariusz biznesowy i role użytkowników: [`docs/plan/cel-aplikacji.md`](docs/plan/cel-aplikacji.md).

## Stack technologiczny

| Warstwa            | Technologia                                                                                     |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| Baza danych        | Microsoft SQL Server 2022 (Developer Edition)                                                   |
| Środowisko lokalne | Docker Desktop (`docker-compose.yml`)                                                           |
| Klient             | SSMS 22                                                                                         |
| Migracje           | ręczne numerowane skrypty `.sql` (`db/migrations/`)                                             |
| Testy bazy         | tSQLt                                                                                           |
| Warstwa pomocnicza | Python 3.12 + `uv` (`tools/`) — generator danych, eksport plików/raportów, nie logika biznesowa |
| CI/CD              | GitHub Actions                                                                                  |

Pełne uzasadnienie wyboru: [`docs/architecture/stack.md`](docs/architecture/stack.md).

## Szybki start

**Wymagania:** Docker Desktop, SSMS (lub inny klient SQL Server), Git.

```bash
git clone <adres-repo>
cd NestBase
cp .env.example .env    # w razie potrzeby zmień MSSQL_SA_PASSWORD

docker compose up -d    # start kontenera SQL Server 2022 na localhost:1433
```

Następnie wykonaj migrację (`db/migrations/V001__initial_schema.sql`) jednym z dwóch sposobów:

- **SSMS:** połącz się (`Server name: localhost,1433`, SQL Server Authentication, login `sa`, hasło z `.env`).
- **sqlcmd w kontenerze:**

  ```bash
  docker exec -i nestbase-sql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "<hasło z .env>" -C \
    -i /dev/stdin < db/migrations/V001__initial_schema.sql
  ```

Baza `NestBase` powstaje od zera. Weryfikacja (powinno być 15 tabel):

```bash
docker exec -i nestbase-sql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "<hasło z .env>" -C -d NestBase \
  -Q "SELECT COUNT(*) AS liczba_tabel FROM sys.tables;"
```

Rollback: `db/rollback/R001__schema_poziom1.sql`.

## Warsztat deweloperski (opcjonalnie)

Potrzebne dopiero do pracy z `tools/` (generator danych, eksporty) albo do commitowania zmian — nie do samego postawienia bazy:

```bash
uv run --project tools pre-commit install   # instaluje zależności (uv.lock) i hooki pre-commit + commitlint
```

Szczegóły narzędzi: [`docs/architecture/quality-tools.md`](docs/architecture/quality-tools.md).

## Struktura repozytorium

```text
NestBase/
├── docker-compose.yml       # lokalny SQL Server 2022
├── docs/
│   ├── ROADMAP.md           # status projektu i kolejne kroki
│   ├── plan/                 # co i dlaczego budujemy
│   ├── architecture/         # jak to zbudowane (architektura, ERD, słownik danych, stack)
│   └── research/             # wiedza branżowa + uzasadnienie decyzji architektonicznych
├── db/
│   ├── migrations/           # V001__..., numerowane, nigdy edytowane po scaleniu
│   ├── rollback/              # rollback 1:1 z migracją
│   └── tests/                 # testy tSQLt (procedures/ i views/ jeszcze nie utworzone)
├── tools/                       # uv project — generator danych, walidacja, eksport plików
└── reports/                      # wyniki referencyjne i przykładowe raporty
```

Pełna, aktualna struktura wraz z uzasadnieniem każdego katalogu: [`docs/architecture/architecture.md`](docs/architecture/architecture.md).

## Architektura

Dane przechodzą zawsze przez staging + walidację przed trafieniem do tabel docelowych; każda korekta w tabelach docelowych przechodzi przez audyt i wywołuje regenerację powiązanych artefaktów (plik maszynowy, PDF, raport). Diagram przepływu i pełny ERD: [`docs/architecture/architecture.md`](docs/architecture/architecture.md), [`docs/architecture/erd.md`](docs/architecture/erd.md).

Wszystkie obiekty żyją w jednym schemacie `dbo`, bez prefiksów w nazwach — obszary (dane domenowe/staging/walidacja/audyt) rozróżnia sama nazwa tabeli i lokalizacja w repo. Uzasadnienie i rozważone alternatywy: [`docs/research/architecture/`](docs/research/architecture/checklist.md).

## Testy

Testy jednostkowe T-SQL w **tSQLt** (`db/tests/`, min. 15 testów z przypadkami brzegowymi)

## CI/CD

Szkielet GitHub Actions (checkout → kontener SQL Server → migracje → `tSQLt.RunAll`)

## Metoda pracy

Research branżowy i dokumentacja (`docs/research/`, `docs/plan/`, `docs/architecture/`) były przygotowywane z pomocą Claude (Anthropic) jako asystenta researchu i pisania dokumentacji.

## Licencja

Projekt portfolio — do ustalenia; domyślnie rozważana licencja MIT.
