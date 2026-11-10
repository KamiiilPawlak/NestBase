# NestBase — scenariusz biznesowy

## Scenariusz, który system symuluje

Droga od zamówienia klienta do wysyłki wyciętych części, w małym zakładzie cięcia blach laserem/CNC

1. **Klient składa zamówienie** na konkretne części do wycięcia — materiał, grubość, wymiary, ilość.
2. **System liczy wycenę** — powierzchnię części, masę, czas cięcia na maszynie, cenę (koszt materiału + czas maszyny + narzut).
3. **Rozkrój (nesting)** — rozmieszcza zamówione części na arkuszach blachy; liczy wykorzystanie materiału i odpad (model uproszczony, patrz zastrzeżenie niżej).
4. **Powstaje zlecenie produkcyjne** — przypisane do maszyny, z planowaną i rzeczywistą datą wykonania.
5. **Kontrola jakości po cięciu** — pomiar wymiarów, sprawdzenie tolerancji, oznaczenie odrzutów.
6. **Generowane są artefakty wyjściowe** — plik maszynowy (lista cięcia CSV/XML) i wydruk (karta zlecenia PDF).
7. **Korekta błędnych danych** — jeśli ktoś znajdzie błąd (zła cena, zła ilość), poprawia go bezpiecznie w transakcji; system loguje kto/kiedy/co zmienił (audyt) i automatycznie przelicza/odtwarza powiązane raporty, plik maszynowy i wydruk, żeby nic się nie rozjechało.
8. **Import danych z zewnątrz** — dane z CSV trafiają najpierw do strefy buforowej (staging), gdzie system automatycznie wykrywa błędy (duplikaty klientów, sieroty, ujemne ceny, braki), zanim coś trafi do tabel docelowych.

## Kto realnie korzystałby z takiego systemu

| Rola                  | Co robi w systemie                                                                       |
| --------------------- | ---------------------------------------------------------------------------------------- |
| Sprzedawca/handlowiec | widzi wycenę i status zamówienia                                                         |
| Planista produkcji    | widzi zlecenia, rozkrój, wykorzystanie arkusza                                           |
| Kontroler jakości     | wpisuje pomiary, widzi odrzuty                                                           |
| Osoba od danych/BI    | odpytuje raporty (wartość zamówień per klient/miesiąc, odpad itd.), naprawia błędne dane |

## Ważne zastrzeżenie

To **nie jest** system przeznaczony do faktycznego prowadzenia zakładu cięcia blach. Pełna lista świadomych ograniczeń zakresu: [`../ROADMAP.md`](../ROADMAP.md) "Poza zakresem".
