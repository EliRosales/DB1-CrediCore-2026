--1. LIMPIEZA Y CREACIÓN DE LA BASE DE DATOS
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

-- 3. CREACIÓN DE TABLAS

-- Tabla Clientes
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

-- Tabla Vehículos
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

-- Tabla Créditos
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

-- 4. INSERCIÓN DE DATOS VÁLIDOS
INSERT INTO Operaciones.Clientes (DPI, Nombre, Apellido, Telefono, Correo)
VALUES ('1234567890123', 'Juan', 'Pérez', '55551234', 'juan@email.com');

INSERT INTO Garantias.Vehiculos (Marca, Modelo, Anio, Color, Placa, NumeroTituloPropiedad, NumeroChasis)
VALUES ('Toyota', 'Yaris', 2018, 'Gris', 'P123ABC', 'TIT123456', 'CHASIS987654');

INSERT INTO Operaciones.Creditos (IdCliente, IdVehiculo, MontoCapital, TasaInteresMensual)
VALUES (1, 1, 15000.00, 2.50);
GO

-- 5. CONSULTAS DE VERIFICACIÓN
SELECT * FROM Operaciones.Clientes;
SELECT * FROM Garantias.Vehiculos;
SELECT * FROM Operaciones.Creditos;
GO