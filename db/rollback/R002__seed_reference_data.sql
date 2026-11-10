USE NestBase;
GO

DELETE FROM dbo.grubosci_materialow;
GO
DELETE FROM dbo.maszyny;
GO
DELETE FROM dbo.materialy;
GO

DELETE FROM dbo.db_migrations_log
WHERE nazwa_migracji = N'V002__seed_reference_data';
GO
