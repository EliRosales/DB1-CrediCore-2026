USE CrediCoreDB;
GO

-- ESTRUCTURA FASE 4

-- Esquema de Auditoría y Vista de Abstracción
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Auditoria')
BEGIN
    EXEC('CREATE SCHEMA Auditoria;');
END
GO

CREATE OR ALTER VIEW Operaciones.vw_AtencionAlCliente AS
SELECT 
    CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCliente,
    cr.IdCredito AS NumeroCredito,
    v.Marca AS MarcaVehiculo,
    cr.Estado AS EstadoCredito,
    cr.MontoCapital AS SaldoActual
FROM Operaciones.Clientes c
INNER JOIN Operaciones.Creditos cr ON c.IdCliente = cr.IdCliente
INNER JOIN Garantias.Vehiculos v ON cr.IdVehiculo = v.IdVehiculo;
GO

-- Tabla de Historial y Stored Procedure Transaccional
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HistorialPagos' AND schema_id = SCHEMA_ID('Operaciones'))
BEGIN
    CREATE TABLE Operaciones.HistorialPagos (
        IdPago INT IDENTITY(1,1) PRIMARY KEY,
        IdCredito INT NOT NULL,
        MontoAbono DECIMAL(12,2) NOT NULL,
        FechaPago DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_HistorialPagos_Creditos FOREIGN KEY (IdCredito) REFERENCES Operaciones.Creditos(IdCredito)
    );
END
GO

CREATE OR ALTER PROCEDURE Operaciones.SP_ProcesarPago    
    @IdCredito INT,
    @MontoAbono DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        DECLARE @SaldoActual DECIMAL(12,2);
        
        SELECT @SaldoActual = MontoCapital 
        FROM Operaciones.Creditos 
        WHERE IdCredito = @IdCredito;
        
        IF @SaldoActual IS NULL
        BEGIN
            RAISERROR('El crédito especificado no existe.', 16, 1);
        END
        
        IF @MontoAbono > @SaldoActual
        BEGIN
            RAISERROR('El monto del abono excede el saldo actual del crédito.', 16, 1);
        END
        
        INSERT INTO Operaciones.HistorialPagos (IdCredito, MontoAbono, FechaPago)
        VALUES (@IdCredito, @MontoAbono, GETDATE());
        
        UPDATE Operaciones.Creditos
        SET MontoCapital = MontoCapital - @MontoAbono
        WHERE IdCredito = @IdCredito;
        
        COMMIT TRANSACTION;
        PRINT 'Pago procesado exitosamente.';
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Bitácora de Auditoría y Trigger
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Logs_Creditos' AND schema_id = SCHEMA_ID('Auditoria'))
BEGIN
    CREATE TABLE Auditoria.Logs_Creditos (
        IdLog INT IDENTITY(1,1) PRIMARY KEY,
        Accion VARCHAR(100) NOT NULL,
        ValorAnterior DECIMAL(12,2),
        ValorNuevo DECIMAL(12,2),
        FechaHora DATETIME DEFAULT GETDATE()
    );
END
GO

CREATE OR ALTER TRIGGER Operaciones.TR_Auditoría_TasaInteres
ON Operaciones.Creditos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(MontoCapital)
    BEGIN
        INSERT INTO Auditoria.Logs_Creditos (Accion, ValorAnterior, ValorNuevo, FechaHora)
        SELECT 
            'Modificación de Crédito ID ' + CAST(i.IdCredito AS VARCHAR),
            d.MontoCapital,
            i.MontoCapital,
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.IdCredito = d.IdCredito
        WHERE i.MontoCapital <> d.MontoCapital;
    END
END;
GO


-- CONSULTAS

-- Capa de Abstracción
SELECT * FROM Operaciones.vw_AtencionAlCliente;


-- Stored Procedure Transaccional
EXEC Operaciones.SP_ProcesarPago @IdCredito = 488, @MontoAbono = 500.00;


-- Trigger de Auditoría 
UPDATE Operaciones.Creditos 
SET MontoCapital = 15000.00 
WHERE IdCredito = 488;

SELECT * FROM Auditoria.Logs_Creditos;