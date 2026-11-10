-- V003__fix_materialy_unique.sql
-- Naprawia brak UNIQUE na materialy.nazwa (udokumentowane w slownik-danych.md,
-- omyłkowo nie wdrożone w V001).
USE NestBase;
GO

ALTER TABLE dbo.materialy
    ADD CONSTRAINT UQ_materialy_nazwa UNIQUE (nazwa);
GO

INSERT INTO dbo.db_migrations_log (nazwa_migracji)
VALUES (N'V003__fix_materialy_unique');
GO
