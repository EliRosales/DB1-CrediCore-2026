USE CrediCoreDB;
GO

-- ============================================================================
-- PARTE A: INTEGRIDAD RELACIONAL Y PRUEBA DE DESTRUCCIÓN
-- ============================================================================

-- A.1 Activación de Restricciones Foráneas (FK)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Creditos_Clientes')
BEGIN
    ALTER TABLE Operaciones.Creditos 
    ADD CONSTRAINT FK_Creditos_Clientes 
    FOREIGN KEY (IdCliente) REFERENCES Operaciones.Clientes(IdCliente);
END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Creditos_Vehiculos')
BEGIN
    ALTER TABLE Operaciones.Creditos 
    ADD CONSTRAINT FK_Creditos_Vehiculos 
    FOREIGN KEY (IdVehiculo) REFERENCES Garantias.Vehiculos(IdVehiculo);
END
GO

-- A.2 Prueba de Destrucción (Demostración de Error de FK) pal video 
DELETE FROM Operaciones.Clientes 
WHERE IdCliente = 70;
GO


-- ============================================================================
-- PARTE B: CONSULTAS DE UNIÓN (JOINS)
-- ============================================================================

-- B.1 Reporte Maestro (INNER JOIN)
SELECT 
    CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCliente,
    c.Telefono,
    v.Marca AS MarcaVehiculo,
    v.Placa,
    cr.MontoCapital AS MontoCredito,
    cr.Estado AS EstadoActual
FROM Operaciones.Creditos cr
INNER JOIN Operaciones.Clientes c ON cr.IdCliente = c.IdCliente
INNER JOIN Garantias.Vehiculos v ON cr.IdVehiculo = v.IdVehiculo;
GO

-- B.2 Minería de Potenciales Clientes (LEFT JOIN) pal video 
SELECT 
    CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCliente,
    c.Telefono,
    cr.IdCredito
FROM Operaciones.Clientes c
LEFT JOIN Operaciones.Creditos cr ON c.IdCliente = cr.IdCliente
WHERE cr.IdCredito IS NULL;
GO


-- ============================================================================
-- PARTE C: SUBCONSULTAS AVANZADAS
-- ============================================================================

-- C.1 Filtro Dinámico (Subconsulta con Promedio) pal video 
SELECT 
    CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCliente,
    cr.MontoCapital
FROM Operaciones.Creditos cr
INNER JOIN Operaciones.Clientes c ON cr.IdCliente = c.IdCliente
WHERE cr.MontoCapital > (
    SELECT AVG(MontoCapital) 
    FROM Operaciones.Creditos
);
GO

-- C.2 Patrones Anidados (Subconsulta con IN)
SELECT 
    CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCliente,
    cr.IdCredito
FROM Operaciones.Creditos cr
INNER JOIN Operaciones.Clientes c ON cr.IdCliente = c.IdCliente
WHERE cr.IdVehiculo IN (
    SELECT IdVehiculo 
    FROM Garantias.Vehiculos 
    WHERE Anio <= 2026
);
GO