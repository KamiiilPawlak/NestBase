-- sp_ValidateWartoscDodatnia.sql
-- Sprawdza, czy wartość w kolumnie wskazanej przez regułę @regula_id jest > 0.
-- Generyczna dla typu reguły 'wartosc_dodatnia' - kolumna/tabela z dbo.reguly_walidacji, nie zahardkodowane (sql/nauka/11).
USE NestBase;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ValidateWartoscDodatnia
    @regula_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tabela NVARCHAR(100);
    DECLARE @kolumna NVARCHAR(100);

    SELECT
        @tabela = tabela,
        @kolumna = kolumna
    FROM dbo.reguly_walidacji
    WHERE id = @regula_id
        AND typ_reguly = N'wartosc_dodatnia';

    IF @tabela IS NULL OR @kolumna IS NULL
    BEGIN
        RAISERROR (N'Reguła %d nie istnieje albo nie jest typu wartosc_dodatnia.', 16, 1, @regula_id);
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @liczba_bledow INT;

    SET @sql = N'SELECT @liczba_bledow_out = COUNT(*) FROM ' + QUOTENAME(@tabela) + N' WHERE TRY_CONVERT(DECIMAL(18, 2), ' + QUOTENAME(@kolumna) + N') <= 0';

    EXEC
        sp_executesql @sql,
        N'@liczba_bledow_out INT OUTPUT',
        @liczba_bledow_out = @liczba_bledow OUTPUT;

    INSERT INTO dbo.wyniki_walidacji (regula_id, liczba_bledow, szczegoly)
    VALUES (@regula_id, @liczba_bledow, N'Kolumna ' + @kolumna + N' w tabeli ' + @tabela + N' <= 0 lub niekonwertowalna');
END
GO
