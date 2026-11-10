USE NestBase;
GO

IF OBJECT_ID(N'dbo.wyniki_walidacji', N'U') IS NOT NULL
    DROP TABLE dbo.wyniki_walidacji;
GO
IF OBJECT_ID(N'dbo.reguly_walidacji', N'U') IS NOT NULL
    DROP TABLE dbo.reguly_walidacji;
GO
IF OBJECT_ID(N'dbo.staging_import', N'U') IS NOT NULL
    DROP TABLE dbo.staging_import;
GO
IF OBJECT_ID(N'dbo.pliki_maszynowe', N'U') IS NOT NULL
    DROP TABLE dbo.pliki_maszynowe;
GO
IF OBJECT_ID(N'dbo.pomiary_jakosci', N'U') IS NOT NULL
    DROP TABLE dbo.pomiary_jakosci;
GO
IF OBJECT_ID(N'dbo.rozkroj', N'U') IS NOT NULL
    DROP TABLE dbo.rozkroj;
GO
IF OBJECT_ID(N'dbo.zlecenia_ciecia', N'U') IS NOT NULL
    DROP TABLE dbo.zlecenia_ciecia;
GO
IF OBJECT_ID(N'dbo.arkusze', N'U') IS NOT NULL
    DROP TABLE dbo.arkusze;
GO
IF OBJECT_ID(N'dbo.pozycje_zamowienia', N'U') IS NOT NULL
    DROP TABLE dbo.pozycje_zamowienia;
GO
IF OBJECT_ID(N'dbo.zamowienia', N'U') IS NOT NULL
    DROP TABLE dbo.zamowienia;
GO
IF OBJECT_ID(N'dbo.maszyny', N'U') IS NOT NULL
    DROP TABLE dbo.maszyny;
GO
IF OBJECT_ID(N'dbo.grubosci_materialow', N'U') IS NOT NULL
    DROP TABLE dbo.grubosci_materialow;
GO
IF OBJECT_ID(N'dbo.materialy', N'U') IS NOT NULL
    DROP TABLE dbo.materialy;
GO
IF OBJECT_ID(N'dbo.klienci', N'U') IS NOT NULL
    DROP TABLE dbo.klienci;
GO

DELETE FROM dbo.db_migrations_log
WHERE nazwa_migracji = N'V001__initial_schema';
GO
