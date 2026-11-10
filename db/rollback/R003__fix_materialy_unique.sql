USE NestBase;
GO

ALTER TABLE dbo.materialy
    DROP CONSTRAINT UQ_materialy_nazwa;
GO

DELETE FROM dbo.db_migrations_log
WHERE nazwa_migracji = N'V003__fix_materialy_unique';
GO
