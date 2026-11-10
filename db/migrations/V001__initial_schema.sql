-- V001_initial_schema.sql
IF DB_ID(N'NestBase') IS NULL
BEGIN
    CREATE DATABASE NestBase;
END
GO

USE NestBase;
GO

IF OBJECT_ID(N'dbo.db_migrations_log', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.db_migrations_log (
        id INT IDENTITY(1, 1) CONSTRAINT PK_db_migrations_log PRIMARY KEY,
        nazwa_migracji NVARCHAR(200) NOT NULL,
        data_wykonania DATETIME2 NOT NULL CONSTRAINT DF_db_migrations_log_data DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_db_migrations_log_nazwa UNIQUE (nazwa_migracji)
    );
END
GO

CREATE TABLE dbo.klienci (
    id INT IDENTITY(1, 1),
    nazwa NVARCHAR(200) NOT NULL,
    miasto NVARCHAR(200) NOT NULL,
    region NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_klienci PRIMARY KEY (id)
);
GO

CREATE TABLE dbo.materialy (
    id INT IDENTITY(1, 1),
    nazwa NVARCHAR(100) NOT NULL,
    gestosc_kg_m3 DECIMAL(10, 2) NOT NULL,
    cena_za_kg DECIMAL(12, 4) NULL,
    CONSTRAINT PK_materialy PRIMARY KEY (id)
);
GO

CREATE TABLE dbo.grubosci_materialow (
    id INT IDENTITY(1, 1),
    material_id INT NOT NULL,
    grubosc_mm DECIMAL(10, 2) NOT NULL,
    predkosc_ciecia_mm_min DECIMAL(10, 2) NOT NULL,
    czas_przebicia_s DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_grubosci_materialow PRIMARY KEY (id),
    CONSTRAINT FK_grubosci_materialow_material FOREIGN KEY (material_id) REFERENCES dbo.materialy(id) ON DELETE CASCADE,
    CONSTRAINT UQ_grubosci_materialow_material_grubosc UNIQUE (material_id, grubosc_mm),
    CONSTRAINT CK_grubosci_materialow_grubosc CHECK (grubosc_mm > 0),
    CONSTRAINT CK_grubosci_materialow_predkosc CHECK (predkosc_ciecia_mm_min > 0),
    CONSTRAINT CK_grubosci_materialow_czas CHECK (czas_przebicia_s > 0)
);
GO

CREATE TABLE dbo.maszyny (
    id INT IDENTITY(1, 1),
    nazwa NVARCHAR(100) NOT NULL,
    stawka_godzinowa DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_maszyny PRIMARY KEY (id),
    CONSTRAINT UQ_maszyny_nazwa UNIQUE (nazwa),
    CONSTRAINT CK_maszyny_stawka CHECK (stawka_godzinowa > 0)
);
GO

CREATE TABLE dbo.zamowienia(
    id INT IDENTITY(1, 1),
    klient_id INT NOT NULL,
    data DATE NOT NULL,
    status NVARCHAR(20) NOT NULL CONSTRAINT DF_zamowienia_status DEFAULT ('nowe'),
    CONSTRAINT PK_zamowienia PRIMARY KEY (id),
    CONSTRAINT FK_zamowienia_klienta FOREIGN KEY (klient_id) REFERENCES dbo.klienci (id),
    CONSTRAINT CK_zamowienia_status CHECK (status IN ('nowe', 'potwierdzone', 'w_realizacji', 'zakonczone', 'anulowane'))
);
GO

CREATE TABLE dbo.pozycje_zamowienia (
    id INT IDENTITY(1, 1) CONSTRAINT PK_pozycje_zamowienia PRIMARY KEY,
    zamowienie_id INT NOT NULL,
    material_id INT NOT NULL,
    grubosc_mm DECIMAL(10, 2) NOT NULL,
    nazwa_czesci NVARCHAR(200) NULL,
    szerokosc_mm DECIMAL(10, 2) NOT NULL,
    wysokosc_mm DECIMAL(10, 2) NOT NULL,
    dlugosc_ciecia_mm DECIMAL(10, 2) NOT NULL,
    liczba_przebic INT NOT NULL,
    ilosc INT NOT NULL,
    cena_jednostkowa DECIMAL(10, 2) NOT NULL,
    CONSTRAINT FK_pozycje_zamowienia_zamowienie FOREIGN KEY (zamowienie_id) REFERENCES dbo.zamowienia (id) ON DELETE CASCADE,
    CONSTRAINT FK_pozycje_zamowienia_grubosc FOREIGN KEY (material_id, grubosc_mm) REFERENCES dbo.grubosci_materialow (material_id, grubosc_mm),
    CONSTRAINT CK_pozycje_zamowienia_grubosc CHECK (grubosc_mm > 0),
    CONSTRAINT CK_pozycje_zamowienia_szerokosc CHECK (szerokosc_mm > 0),
    CONSTRAINT CK_pozycje_zamowienia_wysokosc CHECK (wysokosc_mm > 0),
    CONSTRAINT CK_pozycje_zamowienia_dlugosc CHECK (dlugosc_ciecia_mm > 0),
    CONSTRAINT CK_pozycje_zamowienia_przebicia CHECK (liczba_przebic >= 0),
    CONSTRAINT CK_pozycje_zamowienia_ilosc CHECK (ilosc > 0),
    CONSTRAINT CK_pozycje_zamowienia_cena CHECK (cena_jednostkowa > 0)
);
GO

CREATE TABLE dbo.arkusze (
    id INT IDENTITY(1, 1),
    material_id INT NOT NULL,
    grubosc_mm DECIMAL(10, 2) NOT NULL,
    szerokosc_mm DECIMAL(10, 2) NOT NULL,
    wysokosc_mm DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_arkusze PRIMARY KEY (id),
    CONSTRAINT FK_arkusze_grubosc FOREIGN KEY (material_id, grubosc_mm) REFERENCES dbo.grubosci_materialow (material_id, grubosc_mm),
    CONSTRAINT UQ_arkusze_rozmiar UNIQUE (material_id, grubosc_mm, szerokosc_mm, wysokosc_mm),
    CONSTRAINT CK_arkusze_grubosc CHECK (grubosc_mm > 0),
    CONSTRAINT CK_arkusze_szerokosc CHECK (szerokosc_mm > 0),
    CONSTRAINT CK_arkusze_wysokosc CHECK (wysokosc_mm > 0)
);
GO

CREATE TABLE dbo.zlecenia_ciecia (
    id INT IDENTITY(1, 1),
    zamowienie_id INT NOT NULL,
    maszyna_id INT NOT NULL,
    status NVARCHAR(20) NOT NULL CONSTRAINT DF_zlecenia_ciecia_status DEFAULT ('zaplanowane'),
    data_planowana DATE NOT NULL,
    data_zakonczenia DATE NULL,
    CONSTRAINT PK_zlecenia_ciecia PRIMARY KEY (id),
    CONSTRAINT FK_zlecenia_ciecia_zamowienie FOREIGN KEY (zamowienie_id) REFERENCES dbo.zamowienia (id),
    CONSTRAINT FK_zlecenia_ciecia_maszyna FOREIGN KEY (maszyna_id) REFERENCES dbo.maszyny (id),
    CONSTRAINT CK_zlecenia_ciecia_status CHECK (status IN ('zaplanowane', 'w_trakcie', 'zakonczone', 'anulowane'))
);
GO

CREATE TABLE dbo.rozkroj (
    id INT IDENTITY(1, 1) CONSTRAINT PK_rozkroj PRIMARY KEY,
    zlecenie_id INT NOT NULL,
    arkusz_id INT NOT NULL,
    pozycja_id INT NOT NULL,
    ilosc_na_arkuszu INT NOT NULL,
    CONSTRAINT FK_rozkroj_zlecenie FOREIGN KEY (zlecenie_id) REFERENCES dbo.zlecenia_ciecia (id),
    CONSTRAINT FK_rozkroj_arkusz FOREIGN KEY (arkusz_id) REFERENCES dbo.arkusze (id),
    CONSTRAINT FK_rozkroj_pozycja FOREIGN KEY (pozycja_id) REFERENCES dbo.pozycje_zamowienia (id),
    CONSTRAINT UQ_rozkroj_kombinacja UNIQUE (zlecenie_id, arkusz_id, pozycja_id),
    CONSTRAINT CK_rozkroj_ilosc CHECK (ilosc_na_arkuszu > 0)
);
GO

CREATE TABLE dbo.pomiary_jakosci (
    id INT IDENTITY(1, 1) CONSTRAINT PK_pomiary_jakosci PRIMARY KEY,
    pozycja_id INT NOT NULL,
    wymiar_nominalny DECIMAL(10, 2) NOT NULL,
    wymiar_zmierzony DECIMAL(10, 2) NOT NULL,
    tolerancja DECIMAL(10, 3) NOT NULL,
    wynik NVARCHAR(20) NOT NULL,
    CONSTRAINT FK_pomiary_jakosci_pozycja FOREIGN KEY (pozycja_id) REFERENCES dbo.pozycje_zamowienia (id),
    CONSTRAINT CK_pomiary_jakosci_nominalny CHECK (wymiar_nominalny > 0),
    CONSTRAINT CK_pomiary_jakosci_tolerancja CHECK (tolerancja >= 0),
    CONSTRAINT CK_pomiary_jakosci_wynik CHECK (wynik IN ('OK', 'odrzut'))
);
GO

CREATE TABLE dbo.pliki_maszynowe (
    id INT IDENTITY(1, 1) CONSTRAINT PK_pliki_maszynowe PRIMARY KEY,
    zlecenie_id INT NOT NULL,
    nazwa_pliku NVARCHAR(255) NOT NULL,
    data_wygenerowania DATETIME2 NOT NULL,
    suma_kontrolna CHAR(64) NOT NULL,
    CONSTRAINT FK_pliki_maszynowe_zlecenie FOREIGN KEY (zlecenie_id) REFERENCES dbo.zlecenia_ciecia (id)
);
GO

CREATE TABLE dbo.staging_import (
    id INT IDENTITY(1, 1) CONSTRAINT PK_staging_import PRIMARY KEY,
    nazwa_pliku NVARCHAR(255) NULL,
    numer_wiersza INT NULL,
    data_importu DATETIME2 NULL,
    klient_nazwa NVARCHAR(500) NULL,
    klient_miasto NVARCHAR(500) NULL,
    klient_region NVARCHAR(500) NULL,
    zamowienie_data NVARCHAR(50) NULL,
    zamowienie_status NVARCHAR(50) NULL,
    material_nazwa NVARCHAR(200) NULL,
    nazwa_czesci NVARCHAR(500) NULL,
    grubosc_mm NVARCHAR(50) NULL,
    szerokosc_mm NVARCHAR(50) NULL,
    wysokosc_mm NVARCHAR(50) NULL,
    dlugosc_ciecia_mm NVARCHAR(50) NULL,
    liczba_przebic NVARCHAR(50) NULL,
    ilosc NVARCHAR(50) NULL,
    cena_jednostkowa NVARCHAR(50) NULL
);
GO

CREATE TABLE dbo.reguly_walidacji (
    id INT IDENTITY(1, 1) CONSTRAINT PK_reguly_walidacji PRIMARY KEY,
    typ_reguly NVARCHAR(50) NOT NULL,
    tabela NVARCHAR(100) NOT NULL,
    kolumna NVARCHAR(100) NULL,
    tabela_referencyjna NVARCHAR(100) NULL,
    parametry NVARCHAR(500) NULL,
    aktywna BIT NOT NULL CONSTRAINT DF_reguly_walidacji_aktywna DEFAULT (1),
    opis NVARCHAR(500) NULL
);
GO

CREATE TABLE dbo.wyniki_walidacji (
    id INT IDENTITY(1, 1) CONSTRAINT PK_wyniki_walidacji PRIMARY KEY,
    regula_id INT NOT NULL,
    data_uruchomienia DATETIME2 NOT NULL CONSTRAINT DF_wyniki_walidacji_data DEFAULT (SYSDATETIME()),
    liczba_bledow INT NOT NULL,
    szczegoly NVARCHAR(MAX) NULL,
    CONSTRAINT FK_wyniki_walidacji_regula FOREIGN KEY (regula_id) REFERENCES dbo.reguly_walidacji (id),
    CONSTRAINT CK_wyniki_walidacji_liczba CHECK (liczba_bledow >= 0)
);
GO

INSERT INTO dbo.db_migrations_log (nazwa_migracji)
VALUES (N'V001__initial_schema');
GO
