# NestBase — plan projektu

## 1. Cel projektu

Zbudować bazę danych **Microsoft SQL Server / T-SQL** symulującą system wspierający sprzedaż i produkcję w małym zakładzie cięcia blach (laser/CNC). Projekt pokazuje pracę z danymi w kontekście biznesowym: projektowanie schematu, logikę w T-SQL, walidację i naprawę danych, audyt zmian, testy automatyczne i raportowanie — a nie zbudować realny system produkcyjny.

**Zakres kompetencji technicznych:** czytanie wymagań biznesowych, projektowanie poprawnego schematu, pisanie poprawnego SQL i dokumentowanie podjętych decyzji.

**Zasada prowadząca: prostota i czytelność ważniejsze niż egzotyczne mechanizmy.** To determinuje wszystkie decyzje w projekcie, nie tylko ten dokument. Oznacza to konkretnie:

- domyślnie wybierać prostsze, bardziej "podstawowe" opcje tam, gdzie jest wybór (patrz `research/architecture/` — każda opcja ma tam adnotację "Poziom złożoności"),
- zaawansowane mechanizmy SQL Server (temporal tables, CDC, dynamiczny SQL jako silnik reguł, SSDT) są w porządku do **wspomnienia** jako "wiem, że istnieją i do czego służą", ale nie powinny być wdrażane tylko po to, żeby "zrobić wrażenie" — źle wdrożony zaawansowany mechanizm wypada gorzej niż dobrze wdrożony prosty,
- ambicja projektu powinna być w **zakresie i kompletności** (wszystkie etapy z `ROADMAP.md`, dobre testy, dobra dokumentacja), nie w używaniu najbardziej skomplikowanych narzędzi.

## 2. Zakres kompetencji

| #   | Umiejętność                                         | Dowód w projekcie                                                    |
| --- | --------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | Projektowanie relacyjnego schematu z integralnością | `db/migrations`, ERD, klucze/ograniczenia/indeksy                    |
| 2   | Logika biznesowa w T-SQL                            | procedury, funkcje, widoki policzone wg wzorów z `slownik-danych.md` |
| 3   | Walidacja danych przed załadowaniem                 | staging + `reguly_walidacji` + raport błędów                         |
| 4   | Testowanie automatyczne                             | tSQLt, scenariusze PASS/FAIL, regresja                               |
| 5   | Bezpieczne korekty danych                           | transakcje z `OUTPUT`, `@@ROWCOUNT`, audyt                           |
| 6   | Aktualizacja danych powiązanych po korekcie         | ponowny eksport pliku maszynowego/PDF, raport przed/po               |
| 7   | Dokumentacja pracy                                  | README, słownik danych, runbook                                      |
