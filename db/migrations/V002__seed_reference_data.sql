-- V002__seed_reference_data.sql
USE NestBase;
GO

INSERT INTO dbo.materialy (nazwa, gestosc_kg_m3, cena_za_kg)
VALUES
    (N'Stal S235', 7850.00, 4.50),
    (N'Stal nierdzewna 304', 7900.00, 12.00),
    (N'Aluminium 5754', 2700.00, 9.00);
GO

INSERT INTO dbo.grubosci_materialow (
    material_id,
    grubosc_mm,
    predkosc_ciecia_mm_min,
    czas_przebicia_s
)
SELECT
    m.id,
    g.grubosc_mm,
    g.predkosc,
    g.czas
FROM dbo.materialy m
    CROSS APPLY (
        VALUES (3.0, 4000.0, 0.4), (5.0, 2500.0, 0.7)
    ) AS g(grubosc_mm, predkosc, czas)
WHERE m.nazwa = N'Stal S235';
GO

INSERT INTO dbo.grubosci_materialow (
    material_id,
    grubosc_mm,
    predkosc_ciecia_mm_min,
    czas_przebicia_s
)
SELECT
    m.id,
    g.grubosc_mm,
    g.predkosc,
    g.czas
FROM dbo.materialy m
    CROSS APPLY (
        VALUES (3.0, 3200.0, 0.5), (5.0, 2000.0, 0.9)
    ) AS g(grubosc_mm, predkosc, czas)
WHERE m.nazwa = N'Stal nierdzewna 304';
GO

INSERT INTO dbo.grubosci_materialow (
    material_id,
    grubosc_mm,
    predkosc_ciecia_mm_min,
    czas_przebicia_s
)
SELECT
    m.id,
    g.grubosc_mm,
    g.predkosc,
    g.czas
FROM dbo.materialy m
    CROSS APPLY (
        VALUES (3.0, 4500.0, 0.3), (5.0, 2800.0, 0.6)
    ) AS g(grubosc_mm, predkosc, czas)
WHERE m.nazwa = N'Aluminium 5754';
GO

INSERT INTO dbo.maszyny (nazwa, stawka_godzinowa)
VALUES
    (N'Laser fiber 4kW', 180.00),
    (N'Plazma CNC', 140.00);
GO

INSERT INTO dbo.db_migrations_log (nazwa_migracji)
VALUES (N'V002__seed_reference_data');
GO
