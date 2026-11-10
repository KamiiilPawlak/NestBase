# NestBase — słownik danych

## Przyjęte reguły (stosowane do każdej tabeli niżej)

- **PK:** `id INT IDENTITY(1,1) PRIMARY KEY` w każdej tabeli domenowej (wyjątek: `audyt_zmian` → `BIGINT`, więcej wierszy).
- **FK:** domyślnie `NO ACTION`. `CASCADE` tylko tam, gdzie dziecko nie ma sensu bez rodzica (`pozycje_zamowienia → zamowienia`).
- **Typy:** pieniądze/stawki `DECIMAL(10,2)` (jednostkowe `DECIMAL(12,4)`), wymiary/masy `DECIMAL(10,2)`/`(10,3)`, sztuki `INT`, data bez godziny `DATE`, data+godzina `DATETIME2`, tekst `NVARCHAR` (zawsze, nie `VARCHAR`), tak/nie `BIT`, suma kontrolna `CHAR(64)`.
- **Bez kolumn generycznych** (`created_at`, `is_deleted`, `created_by`) na tabelach domenowych — pokrywa to `audyt_zmian`.
- **Walidacja na granicy:** rzeczy wykrywalne w `reguly_walidacji` (duplikaty, sieroty) nie muszą być też `CHECK`/`UNIQUE` w tabeli docelowej — ta jest już "po walidacji".

## Tabele domenowe

### `klienci`

| Kolumna | Typ           | Ograniczenia |
| ------- | ------------- | ------------ |
| id      | INT IDENTITY  | PK           |
| nazwa   | NVARCHAR(200) | NOT NULL     |
| miasto  | NVARCHAR(100) | NOT NULL     |
| region  | NVARCHAR(100) | NULL         |

Bez `NIP`/`email`/`telefon` — nic ich nie używa (YAGNI). Bez `UNIQUE(nazwa, miasto)` — duplikaty klientów wykrywa reguła walidacji, nie constraint (dane docelowe już po weryfikacji).

### `materialy`

| Kolumna       | Typ           | Ograniczenia          |
| ------------- | ------------- | --------------------- |
| id            | INT IDENTITY  | PK                    |
| nazwa         | NVARCHAR(100) | NOT NULL, UNIQUE      |
| gestosc_kg_m3 | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |
| cena_za_kg    | DECIMAL(12,4) | NOT NULL, CHECK (> 0) |

### `grubosci_materialow`

| Kolumna                | Typ           | Ograniczenia                             |
| ---------------------- | ------------- | ---------------------------------------- |
| id                     | INT IDENTITY  | PK                                       |
| material_id            | INT           | NOT NULL, FK → `materialy(id)` NO ACTION |
| grubosc_mm             | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                    |
| predkosc_ciecia_mm_min | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                    |
| czas_przebicia_s       | DECIMAL(10,2) | NOT NULL, CHECK (>= 0)                   |

`UNIQUE(material_id, grubosc_mm)` — cel dla złożonego FK z `pozycje_zamowienia` i `arkusze` (patrz niżej). Bez `kerf_mm` na razie — nieużywane w obecnym uproszczonym modelu rozkroju (możliwe rozszerzenie Poziomu 3).

### `maszyny`

| Kolumna          | Typ           | Ograniczenia          |
| ---------------- | ------------- | --------------------- |
| id               | INT IDENTITY  | PK                    |
| nazwa            | NVARCHAR(100) | NOT NULL, UNIQUE      |
| stawka_godzinowa | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |

### `zamowienia`

| Kolumna   | Typ          | Ograniczenia                                                                                             |
| --------- | ------------ | -------------------------------------------------------------------------------------------------------- |
| id        | INT IDENTITY | PK                                                                                                       |
| klient_id | INT          | NOT NULL, FK → `klienci(id)` NO ACTION                                                                   |
| data      | DATE         | NOT NULL                                                                                                 |
| status    | NVARCHAR(20) | NOT NULL, DEFAULT `'nowe'`, CHECK IN (`nowe`, `potwierdzone`, `w_realizacji`, `zakonczone`, `anulowane`) |

Bez osobnego `termin_realizacji` — harmonogram żyje w `zlecenia_ciecia.data_planowana`. Reguła walidacji: zamówienie ze statusem `zakonczone` bez żadnej pozycji lub bez żadnego powiązanego `zlecenia_ciecia` jest sierotą/niekonsekwencją (patrz `quality-tools.md` §3.1, `research/02-proces-biznesowy-i-dokumenty.md` §4).

### `pozycje_zamowienia`

| Kolumna           | Typ           | Ograniczenia                                |
| ----------------- | ------------- | ------------------------------------------- |
| id                | INT IDENTITY  | PK                                          |
| zamowienie_id     | INT           | NOT NULL, FK → `zamowienia(id)` **CASCADE** |
| material_id       | INT           | NOT NULL                                    |
| grubosc_mm        | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                       |
| nazwa_czesci      | NVARCHAR(200) | NULL (opisowa, do karty zlecenia PDF)       |
| szerokosc_mm      | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                       |
| wysokosc_mm       | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                       |
| dlugosc_ciecia_mm | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                       |
| liczba_przebic    | INT           | NOT NULL, CHECK (>= 0)                      |
| ilosc             | INT           | NOT NULL, CHECK (> 0)                       |
| cena_jednostkowa  | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                       |

FK złożony: `(material_id, grubosc_mm)` → `grubosci_materialow(material_id, grubosc_mm)`. Zamienia pytanie "czy grubość jest dostępna dla materiału" z reguły walidacji w gwarancję bazy — można to wymusić deklaratywnie, więc jest wymuszone. Reguły walidacji (pełna lista w `quality-tools.md` §3.1): cena/wymiary/ilość/grubość > 0; część mieści się w największym dostępnym arkuszu; grubość dostępna dla materiału.

### `arkusze`

Katalog dostępnych rozmiarów, nie fizyczne egzemplarze ze statusem — zgodnie z uproszczonym modelem rozkroju "półkami" (śledzenie zużycia konkretnego egzemplarza arkusza byłoby już inventory management, poza zakresem).

| Kolumna      | Typ           | Ograniczenia          |
| ------------ | ------------- | --------------------- |
| id           | INT IDENTITY  | PK                    |
| material_id  | INT           | NOT NULL              |
| grubosc_mm   | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |
| szerokosc_mm | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |
| wysokosc_mm  | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |

FK złożony: `(material_id, grubosc_mm)` → `grubosci_materialow(material_id, grubosc_mm)`, jak w `pozycje_zamowienia`. `UNIQUE(material_id, grubosc_mm, szerokosc_mm, wysokosc_mm)` — bez duplikatów tego samego rozmiaru w katalogu.

### `zlecenia_ciecia`

| Kolumna          | Typ          | Ograniczenia                                                                                        |
| ---------------- | ------------ | --------------------------------------------------------------------------------------------------- |
| id               | INT IDENTITY | PK                                                                                                  |
| zamowienie_id    | INT          | NOT NULL, FK → `zamowienia(id)` NO ACTION                                                           |
| maszyna_id       | INT          | NOT NULL, FK → `maszyny(id)` NO ACTION                                                              |
| status           | NVARCHAR(20) | NOT NULL, DEFAULT `'zaplanowane'`, CHECK IN (`zaplanowane`, `w_trakcie`, `zakonczone`, `anulowane`) |
| data_planowana   | DATE         | NOT NULL                                                                                            |
| data_zakonczenia | DATE         | NULL (wypełniane po zakończeniu)                                                                    |

Bez `operator`/`uwagi` — nic z `description.md` tego nie wymaga.

### `rozkroj`

Tabela łącząca, z własnym surogatowym `id` (nie kluczem złożonym) — prostszy, zgodny ze wzorcem reszty tabel.

| Kolumna          | Typ          | Ograniczenia                                      |
| ---------------- | ------------ | ------------------------------------------------- |
| id               | INT IDENTITY | PK                                                |
| zlecenie_id      | INT          | NOT NULL, FK → `zlecenia_ciecia(id)` NO ACTION    |
| arkusz_id        | INT          | NOT NULL, FK → `arkusze(id)` NO ACTION            |
| pozycja_id       | INT          | NOT NULL, FK → `pozycje_zamowienia(id)` NO ACTION |
| ilosc_na_arkuszu | INT          | NOT NULL, CHECK (> 0)                             |

`UNIQUE(zlecenie_id, arkusz_id, pozycja_id)` — bez duplikatu tej samej kombinacji. Bez współrzędnych x/y — to już byłby prawdziwy nesting 2D (poza zakresem). Na tej tabeli liczone jest `wykorzystanie_arkusza` i `odpad` (patrz "Wzory obliczeniowe" niżej) — koszt materiału pozycji jest liczony proporcjonalnie do udziału w powierzchni zużytego arkusza, nie tylko z własnej powierzchni części (`research/process.md` §4).

### `pomiary_jakosci`

| Kolumna          | Typ           | Ograniczenia                                      |
| ---------------- | ------------- | ------------------------------------------------- |
| id               | INT IDENTITY  | PK                                                |
| pozycja_id       | INT           | NOT NULL, FK → `pozycje_zamowienia(id)` NO ACTION |
| wymiar_nominalny | DECIMAL(10,2) | NOT NULL, CHECK (> 0)                             |
| wymiar_zmierzony | DECIMAL(10,2) | NOT NULL                                          |
| tolerancja       | DECIMAL(10,3) | NOT NULL, CHECK (>= 0)                            |
| wynik            | NVARCHAR(20)  | NOT NULL, CHECK IN (`OK`, `odrzut`)               |

`tolerancja` jest zapisana w pomiarze (nie liczona na żywo z `grubosci_materialow` w momencie odczytu) — świadoma denormalizacja: tolerancja obowiązująca w chwili pomiaru zostaje zamrożona, nawet jeśli norma się później zmieni (`research/03-pliki-maszynowe-i-normy-jakosci.md` §4). Bez trzeciej wartości `do_przegladu` i bez `kto_mierzyl` — YAGNI. Reguła walidacji: zmierzony wymiar poza tolerancją bez oznaczenia "odrzut" (patrz `quality-tools.md` §3.1).

### `pliki_maszynowe`

| Kolumna            | Typ           | Ograniczenia                                   |
| ------------------ | ------------- | ---------------------------------------------- |
| id                 | INT IDENTITY  | PK                                             |
| zlecenie_id        | INT           | NOT NULL, FK → `zlecenia_ciecia(id)` NO ACTION |
| nazwa_pliku        | NVARCHAR(255) | NOT NULL                                       |
| data_wygenerowania | DATETIME2     | NOT NULL                                       |
| suma_kontrolna     | CHAR(64)      | NOT NULL (SHA-256)                             |

Tylko metadane + suma kontrolna, bez treści pliku w bazie — plik żyje w systemie plików/eksporcie, baza tylko go śledzi.

### `audyt_zmian`

| Kolumna       | Typ             | Ograniczenia                                                    |
| ------------- | --------------- | --------------------------------------------------------------- |
| id            | BIGINT IDENTITY | PK                                                              |
| tabela        | NVARCHAR(100)   | NOT NULL                                                        |
| klucz         | NVARCHAR(100)   | NOT NULL (wartość PK jako tekst — generyczne dla każdej tabeli) |
| pole          | NVARCHAR(100)   | NOT NULL                                                        |
| wartosc_stara | NVARCHAR(MAX)   | NULL                                                            |
| wartosc_nowa  | NVARCHAR(MAX)   | NULL                                                            |
| data          | DATETIME2       | NOT NULL, DEFAULT `SYSDATETIME()`                               |
| uzytkownik    | NVARCHAR(100)   | NOT NULL                                                        |

Logowane `UPDATE`/`DELETE` (korekty), nie `INSERT` — `architecture.md` §1 opisuje audyt jako ścieżkę korekty, nie jako "kto stworzył rekord" (`research/process.md` §4). Bez FK do danych źródłowych — audyt jest obserwatorem, nie uczestnikiem (nie może blokować logowania, nawet jeśli dane źródłowe już nie istnieją).

## Tabele zależne od decyzji Fazy B

Zgodne z wybranymi opcjami: staging → jedna uniwersalna tabela ([`05-struktura-stagingu.md`](../research/architecture/05-struktura-stagingu.md), Opcja A); walidacja → typ reguły + stałe procedury, nie dynamiczny SQL ([`04-silnik-walidacji.md`](../research/architecture/04-silnik-walidacji.md), Opcja B).

### `staging_import`

Świadomie **bez** `NOT NULL`/`CHECK`/`FK` — musi przyjąć wszystko, łącznie z błędnymi danymi (reguły walidacji mają co wykryć). Pola liczbowe/daty jako `NVARCHAR`, nie `DECIMAL`/`DATE` — inaczej silnik bazy odrzuciłby błędny wiersz na wejściu, zanim reguła walidacji zdąży go zgłosić (reguła "wartości tekstowe, których nie da się zamienić na liczbę" z `quality-tools.md` §3.1 — wymaga, żeby wartość w ogóle dało się tam wpisać).

| Kolumna           | Typ           | Uwaga                                           |
| ----------------- | ------------- | ----------------------------------------------- |
| id                | INT IDENTITY  | PK (własny, nie ma sensu biznesowego)           |
| nazwa_pliku       | NVARCHAR(255) | NULL — źródło paczki                            |
| numer_wiersza     | INT           | NULL — numer wiersza w pliku, do raportu błędów |
| data_importu      | DATETIME2     | NULL                                            |
| klient_nazwa      | NVARCHAR(500) | NULL                                            |
| klient_miasto     | NVARCHAR(500) | NULL                                            |
| klient_region     | NVARCHAR(500) | NULL                                            |
| zamowienie_data   | NVARCHAR(50)  | NULL (tekst — może nie być prawdziwą datą)      |
| zamowienie_status | NVARCHAR(50)  | NULL                                            |
| material_nazwa    | NVARCHAR(200) | NULL                                            |
| nazwa_czesci      | NVARCHAR(500) | NULL                                            |
| grubosc_mm        | NVARCHAR(50)  | NULL (tekst — może nie być liczbą)              |
| szerokosc_mm      | NVARCHAR(50)  | NULL                                            |
| wysokosc_mm       | NVARCHAR(50)  | NULL                                            |
| dlugosc_ciecia_mm | NVARCHAR(50)  | NULL                                            |
| liczba_przebic    | NVARCHAR(50)  | NULL                                            |
| ilosc             | NVARCHAR(50)  | NULL                                            |
| cena_jednostkowa  | NVARCHAR(50)  | NULL                                            |

### `reguly_walidacji`

| Kolumna             | Typ           | Ograniczenia                                                                                    |
| ------------------- | ------------- | ----------------------------------------------------------------------------------------------- |
| id                  | INT IDENTITY  | PK                                                                                              |
| typ_reguly          | NVARCHAR(50)  | NOT NULL — np. `wartosc_dodatnia`, `brak_sieroty`, `duplikat`, `suma_zgodna`, `poza_tolerancja` |
| tabela              | NVARCHAR(100) | NOT NULL — tabela docelowa, której dotyczy reguła                                               |
| kolumna             | NVARCHAR(100) | NULL — kolumna sprawdzana (gdy reguła dotyczy jednej kolumny)                                   |
| tabela_referencyjna | NVARCHAR(100) | NULL — używana przez `brak_sieroty`                                                             |
| parametry           | NVARCHAR(500) | NULL — dodatkowe parametry specyficzne dla `typ_reguly`                                         |
| aktywna             | BIT           | NOT NULL, DEFAULT 1                                                                             |
| opis                | NVARCHAR(500) | NULL                                                                                            |

Każdy `typ_reguly` ma własną, raz napisaną procedurę generyczną (`db/procedures/walidacja/`) — nowy **rodzaj** reguły wymaga kodu, nowy **przypadek** istniejącego rodzaju to tylko `INSERT` tutaj.

### `wyniki_walidacji`

| Kolumna           | Typ           | Ograniczenia                                              |
| ----------------- | ------------- | --------------------------------------------------------- |
| id                | INT IDENTITY  | PK                                                        |
| regula_id         | INT           | NOT NULL, FK → `reguly_walidacji(id)` NO ACTION           |
| data_uruchomienia | DATETIME2     | NOT NULL, DEFAULT `SYSDATETIME()`                         |
| liczba_bledow     | INT           | NOT NULL, CHECK (>= 0)                                    |
| szczegoly         | NVARCHAR(MAX) | NULL — np. lista `id`/numerów wierszy, które nie przeszły |

## Wzory obliczeniowe

- **Powierzchnia części:** `szerokosc_mm × wysokosc_mm / 1 000 000` (m²)
- **Masa części:** `powierzchnia × grubosc_mm / 1000 × gestosc_kg_m3` (kg)
- **Czas maszyny:** `dlugosc_ciecia_mm / predkosc_ciecia_mm_min + liczba_przebic × czas_przebicia_s / 60` (min)
- **Wykorzystanie arkusza:** `suma_powierzchni_czesci / suma_powierzchni_uzytych_arkuszy` (%)
- **Odpad:** `1 − wykorzystanie`
- **Cena pozycji:** `koszt_materialu + czas_maszyny × stawka_godzinowa + narzut`, gdzie koszt materiału liczony proporcjonalnie od masy **całego zużytego arkusza** (`rozkroj`), nie tylko z powierzchni samej części — patrz `research/04-cennik-i-kalkulacja-kosztow.md`.

Rozkrój jest **uproszczony** (rozmieszczanie "półkami" po wysokości części, nie prawdziwy nesting 2D) — świadome ograniczenie opisane w README i w [`../research/architecture/06-model-rozkroju.md`](../research/architecture/06-model-rozkroju.md).

## Normalizacja

- Dane referencyjne (`materialy`, `grubosci_materialow`, `maszyny`) nie są kopiowane do tabel pozycji — zawsze FK, nigdy duplikat nazwy/ceny/stawki.
- Jedyna świadoma denormalizacja: `tolerancja` zamrożona w `pomiary_jakosci` (udokumentowana wyżej).
