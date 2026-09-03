-- 1. LIMPIEZA Y CREACIÓN DE LA BASE DE DATOS
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CrediCoreDB')
BEGIN
    ALTER DATABASE CrediCoreDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CrediCoreDB;
END
GO

CREATE DATABASE CrediCoreDB;
GO

USE CrediCoreDB;
GO

-- 2. CREACIÓN DE ESQUEMAS
CREATE SCHEMA Operaciones;
GO

CREATE SCHEMA Garantias;
GO

-- 3. CREACIÓN DE TABLAS Y RESTRICCIONES

-- Tabla: Clientes
CREATE TABLE Operaciones.Clientes (
    IdCliente INT IDENTITY(1,1) NOT NULL,
    DPI VARCHAR(13) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    Telefono VARCHAR(15) NULL,
    Correo VARCHAR(120) NULL,

    CONSTRAINT PK_Clientes PRIMARY KEY (IdCliente),
    CONSTRAINT UQ_Clientes_DPI UNIQUE (DPI),
    CONSTRAINT CK_Clientes_DPI_Formato CHECK (DPI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);
GO

-- Tabla: Vehículos
CREATE TABLE Garantias.Vehiculos (
    IdVehiculo INT IDENTITY(1,1) NOT NULL,
    Marca VARCHAR(50) NOT NULL,
    Modelo VARCHAR(50) NOT NULL,
    Anio INT NOT NULL,
    Color VARCHAR(30) NOT NULL,
    Placa VARCHAR(15) NOT NULL,
    NumeroTituloPropiedad VARCHAR(50) NOT NULL,
    NumeroChasis VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Vehiculos PRIMARY KEY (IdVehiculo),
    CONSTRAINT UQ_Vehiculos_Placa UNIQUE (Placa),
    CONSTRAINT UQ_Vehiculos_Chasis UNIQUE (NumeroChasis),
    CONSTRAINT UQ_Vehiculos_Titulo UNIQUE (NumeroTituloPropiedad),
    CONSTRAINT CK_Vehiculos_AnioMinimo CHECK (Anio >= 2011)
);
GO

-- Tabla: Créditos
CREATE TABLE Operaciones.Creditos (
    IdCredito INT IDENTITY(1,1) NOT NULL,
    IdCliente INT NOT NULL,
    IdVehiculo INT NOT NULL,
    MontoCapital DECIMAL(18,2) NOT NULL,
    TasaInteresMensual DECIMAL(5,2) NOT NULL,
    Estado VARCHAR(20) NOT NULL CONSTRAINT DF_Creditos_Estado DEFAULT 'Activo',
    FechaDesembolso DATETIME2(0) NOT NULL CONSTRAINT DF_Creditos_Fecha DEFAULT GETDATE(),

    CONSTRAINT PK_Creditos PRIMARY KEY (IdCredito),
    CONSTRAINT CK_Creditos_MontoMinimo CHECK (MontoCapital > 1000.00),
    CONSTRAINT CK_Creditos_TasaNoNegativa CHECK (TasaInteresMensual >= 0.00),
    CONSTRAINT FK_Creditos_Clientes FOREIGN KEY (IdCliente) REFERENCES Operaciones.Clientes(IdCliente),
    CONSTRAINT FK_Creditos_Vehiculos FOREIGN KEY (IdVehiculo) REFERENCES Garantias.Vehiculos(IdVehiculo)
);
GO

-- 4. INGESTA Y POBLAMIENTO DE DATOS

-- 4.1 Inserción de Clientes
INSERT INTO Operaciones.Clientes (DPI, Nombre, Apellido, Telefono, Correo) VALUES
('1234567890123', 'Juan', 'Pérez', '55551234', 'juan@email.com'),
('1000000000001', 'Carlos', 'Gómez', '55550001', 'carlos1@email.com'),
('1000000000002', 'María', 'López', '55550002', 'maria2@email.com'),
('1000000000003', 'Pedro', 'Martínez', '55550003', 'pedro3@email.com'),
('1000000000004', 'Ana', 'Rodríguez', '55550004', 'ana4@email.com');
GO

-- 4.2 Ingesta Masiva desde archivo plano (BULK INSERT)
BULK INSERT Garantias.Vehiculos
FROM '/var/opt/mssql/data/vehiculos.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- 4.3 Inserción masiva de Vehículos adicionales
INSERT INTO Garantias.Vehiculos (Marca, Modelo, Anio, Color, Placa, NumeroTituloPropiedad, NumeroChasis)
SELECT TOP (1500)
    CASE (ABS(CHECKSUM(NEWID())) % 5)
        WHEN 0 THEN 'Toyota'
        WHEN 1 THEN 'Honda'
        WHEN 2 THEN 'Ford'
        WHEN 3 THEN 'Nissan'
        ELSE 'Chevrolet'
    END AS Marca,
    'Sedan' AS Modelo,
    2018 + (ABS(CHECKSUM(NEWID())) % 6) AS Anio,
    'Negro' AS Color,
    'P-' + UPPER(LEFT(REPLACE(NEWID(), '-', ''), 6)) AS Placa,
    'TIT-' + UPPER(LEFT(REPLACE(NEWID(), '-', ''), 8)) AS NumeroTituloPropiedad,
    'VIN-' + UPPER(LEFT(REPLACE(NEWID(), '-', ''), 10)) AS NumeroChasis
FROM sys.all_columns a 
CROSS JOIN sys.all_columns b;
GO

-- 4.4 Inserción de Créditos
ALTER TABLE Operaciones.Creditos NOCHECK CONSTRAINT ALL;
GO

INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual, Estado, FechaDesembolso)
SELECT TOP (2000)
    (ABS(CHECKSUM(NEWID())) % 5) + 1 AS IdCliente,
    1 AS IdVehiculo,
    ROUND(CAST(RAND(CHECKSUM(NEWID())) * 45000 + 5000 AS DECIMAL(10,2)), 2) AS MontoCapital,
    1.50 AS TasaInteresMensual,
    CASE (ABS(CHECKSUM(NEWID())) % 3)
        WHEN 0 THEN 'Activo'
        WHEN 1 THEN 'Moroso'
        ELSE 'Saldado'
    END AS Estado,
    GETDATE() AS FechaDesembolso
FROM sys.all_columns a 
CROSS JOIN sys.all_columns b;
GO

-- Asignación de vehículos a la cartera de créditos
UPDATE Operaciones.Creditos
SET IdVehiculo = (
    SELECT TOP 1 IdVehiculo 
    FROM Garantias.Vehiculos 
    ORDER BY NEWID()
);
GO

ALTER TABLE Operaciones.Creditos CHECK CONSTRAINT ALL;
GO

-- 5. REPORTES DE INTELIGENCIA FINANCIERA

-- 5.1 Reporte B1: Riesgo Acumulado por Estado de Crédito
SELECT 
    Estado, 
    SUM(MontoCapital) AS MontoTotal, 
    AVG(TasaInteresMensual) AS TasaPromedio
FROM Operaciones.Creditos
GROUP BY Estado;
GO

-- 5.2 Reporte B2: Concentración Vehicular en Garantías (Filtrado con HAVING)
SELECT 
    v.Marca, 
    COUNT(c.IdCredito) AS TotalPrestamos
FROM Operaciones.Creditos c
INNER JOIN Garantias.Vehiculos v ON c.IdVehiculo = v.IdVehiculo
GROUP BY v.Marca
HAVING COUNT(c.IdCredito) > 50;
GO

-- 5.3 Reporte B3: Análisis de Extremos (Préstamo Máximo y Mínimo)
SELECT 
    MAX(MontoCapital) AS PrestamoMayorValor, 
    MIN(MontoCapital) AS PrestamoMenorValor
FROM Operaciones.Creditos;
GO