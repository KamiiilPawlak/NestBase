-- V004__seed_validation_rules.sql
USE NestBase;
GO

INSERT INTO dbo.reguly_walidacji (
    typ_reguly,
    tabela,
    kolumna,
    tabela_referencyjna,
    parametry,
    aktywna,
    opis
)
VALUES
    (N'wartosc_dodatnia', N'staging_import', N'cena_jednostkowa', NULL, NULL, 1,
        N'Cena jednostkowa musi być większa od zera'),
    (N'brak_sieroty', N'staging_import', N'material_nazwa', N'materialy', NULL, 1,
        N'Materiał musi istnieć w tabeli materialy'),
    (N'duplikat', N'staging_import', NULL, NULL, N'klient_nazwa,klient_miasto', 1,
        N'Duplikat klienta - ta sama nazwa i miasto'),
    (N'tekst_w_liczbie', N'staging_import', N'grubosc_mm', NULL, NULL, 1,
        N'Wartość w polu liczbowym musi być konwertowalna na liczbę (TRY_CONVERT)');
GO

INSERT INTO dbo.db_migrations_log (nazwa_migracji)
VALUES (N'V004__seed_validation_rules');
GO
