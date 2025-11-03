/* =========================================================
   SCRIPT DEFINITIVO: LIMPIEZA Y CARGA MASIVA (v3)
   
   1. Limpia todas las tablas
   2. Inserta datos maestros (Socios, 21 Horarios, etc.)
   3. DESACTIVA el trigger de inscripciones
   4. Inserta 20,000 inscripciones (respetando el día de la semana)
   5. REACTIVA el trigger
=========================================================
*/

-- =========================================================
-- PASO 1: LIMPIEZA TOTAL
-- =========================================================
USE GimnasioDB;
GO

PRINT 'PASO 1: Limpiando todas las tablas...';

-- 1. Tablas con dependencias
DELETE FROM Inscripciones;
DELETE FROM Pagos;
DELETE FROM Horarios;

-- 2. Tablas de reglas
DELETE FROM Espacio_ClasesPermitidas;

-- 3. Tablas Maestras
DELETE FROM Socios;
DELETE FROM Entrenadores;
DELETE FROM Clases_Catalogo;
DELETE FROM Espacios;

PRINT '...Tablas limpiadas.';
GO

-- 4. Reiniciar los contadores IDENTITY
DBCC CHECKIDENT ('Inscripciones', RESEED, 0);
DBCC CHECKIDENT ('Pagos', RESEED, 0);
DBCC CHECKIDENT ('Horarios', RESEED, 0);
DBCC CHECKIDENT ('Socios', RESEED, 0);
DBCC CHECKIDENT ('Entrenadores', RESEED, 0);
DBCC CHECKIDENT ('Clases_Catalogo', RESEED, 0);
DBCC CHECKIDENT ('Espacios', RESEED, 0);

PRINT '...Contadores IDENTITY reiniciados.';
GO

-- =========================================================
-- PASO 2: INSERCIÓN DE DATOS MAESTROS Y HORARIOS
-- =========================================================
USE GimnasioDB;
GO
SET NOCOUNT ON;
SET DATEFIRST 1; -- Lunes = 1
PRINT 'PASO 2: Insertando datos maestros...';

-- 2.1 DATOS MAESTROS
INSERT INTO Entrenadores (Nombre, Apellido, Especialidad, Email, Genero) VALUES
('Ana', 'González', 'Yoga', 'ana.gonzalez@gym.com', 'F'),
('Carlos', 'Ruiz', 'CrossFit', 'carlos.ruiz@gym.com', 'M'),
('Sofía', 'Martínez', 'Spinning', 'sofia.martinez@gym.com', 'F'),
('David', 'López', 'Pesas', 'david.lopez@gym.com', 'M');

INSERT INTO Espacios (NombreEspacio, Descripcion) VALUES
('Sala Yoga', 'Sala tranquila'),
('Sala Spinning', 'Equipada con 20 bicicletas'),
('Box CrossFit', 'Área de alta intensidad'),
('Área Musculación', 'Piso principal con máquinas');

INSERT INTO Clases_Catalogo (NombreClase, Descripcion) VALUES
('Yoga', 'Clases de Yoga'), ('Pilates', 'Fortalecimiento de core'), ('Spinning', 'Clases de ciclismo'),
('CrossFit', 'Entrenamiento de alta intensidad'), ('Funcional', 'Circuitos de entrenamiento'), ('Pesas', 'Entrenamiento de musculación');

INSERT INTO Espacio_ClasesPermitidas (EspacioID, CatalogoID) VALUES
(1, 1), (1, 2), (2, 3), (3, 4), (3, 5), (4, 5), (4, 6);

-- 2.2 HORARIOS (21 horarios, 7am-10am)
PRINT '...Creando 21 horarios maestros...';
DECLARE @Capacidad INT = 20;
-- Día 1 (Lunes)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(1, 1, 1, 1, '07:00:00', '08:00:00', @Capacidad), (1, 1, 2, 1, '08:00:00', '09:00:00', @Capacidad), (1, 1, 1, 1, '09:00:00', '10:00:00', @Capacidad);
-- Día 2 (Martes)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(3, 2, 3, 2, '07:00:00', '08:00:00', @Capacidad), (3, 2, 3, 2, '08:00:00', '09:00:00', @Capacidad), (2, 3, 5, 2, '09:00:00', '10:00:00', @Capacidad);
-- Día 3 (Miércoles)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(4, 4, 6, 3, '07:00:00', '08:00:00', @Capacidad), (4, 4, 5, 3, '08:00:00', '09:00:00', @Capacidad), (1, 1, 1, 3, '09:00:00', '10:00:00', @Capacidad);
-- Día 4 (Jueves)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(2, 3, 4, 4, '07:00:00', '08:00:00', @Capacidad), (2, 3, 4, 4, '08:00:00', '09:00:00', @Capacidad), (3, 2, 3, 4, '09:00:00', '10:00:00', @Capacidad);
-- Día 5 (Viernes)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(1, 1, 1, 5, '07:00:00', '08:00:00', @Capacidad), (4, 4, 6, 5, '08:00:00', '09:00:00', @Capacidad), (2, 3, 5, 5, '09:00:00', '10:00:00', @Capacidad);
-- Día 6 (Sábado)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(3, 2, 3, 6, '07:00:00', '08:00:00', @Capacidad), (2, 3, 4, 6, '08:00:00', '09:00:00', @Capacidad), (1, 1, 2, 6, '09:00:00', '10:00:00', @Capacidad);
-- Día 7 (Domingo)
INSERT INTO Horarios (EntrenadorID, EspacioID, CatalogoID, DiaDeLaSemana, HoraInicio, HoraFin, CapacidadMaxima) VALUES
(4, 4, 5, 7, '07:00:00', '08:00:00', @Capacidad), (1, 1, 1, 7, '08:00:00', '09:00:00', @Capacidad), (3, 2, 3, 7, '09:00:00', '10:00:00', @Capacidad);

PRINT '...Datos maestros y horarios creados.';
GO

-- =========================================================
-- PASO 3: GENERACIÓN MASIVA DE SOCIOS Y PAGOS
-- =========================================================
PRINT 'PASO 3: Generando 500 Socios y 5000 Pagos...';
DECLARE @TotalSocios INT = 500;
DECLARE @TotalPagos INT = 5000;
DECLARE @FechaInicio DATE = '2023-08-01';
DECLARE @FechaFin DATE = '2025-11-02';
DECLARE @RangoDias INT = DATEDIFF(day, @FechaInicio, @FechaFin);

-- 3.1 Socios
DECLARE @i INT = 1;
WHILE @i <= @TotalSocios
BEGIN
    INSERT INTO Socios (Nombre, Apellido, Email, TipoMembresia, FechaInscripcion, Genero)
    VALUES (
        'Socio_N_' + CAST(@i AS VARCHAR), 'Socio_A_' + CAST(@i AS VARCHAR), 'socio' + CAST(@i AS VARCHAR) + '@mail.com',
        CASE CAST(RAND() * 3 AS INT) WHEN 0 THEN 'Mensual' WHEN 1 THEN 'Trimestral' ELSE 'Anual' END,
        DATEADD(day, CAST(RAND() * @RangoDias AS INT), @FechaInicio),
        CASE CAST(RAND() * 2 AS INT) WHEN 0 THEN 'M' ELSE 'F' END
    );
    SET @i = @i + 1;
END;
PRINT '...500 Socios generados.';

-- 3.2 Pagos
DECLARE @MinSocioID INT = (SELECT MIN(SocioID) FROM Socios);
DECLARE @MaxSocioID INT = (SELECT MAX(SocioID) FROM Socios);
SET @i = 1;
WHILE @i <= @TotalPagos
BEGIN
    INSERT INTO Pagos (SocioID, Monto, FechaPago, Concepto)
    VALUES (
        (SELECT CAST(((@MaxSocioID - @MinSocioID) * RAND() + @MinSocioID) AS INT)),
        CAST(RAND() * 500 + 50 AS DECIMAL(10, 2)),
        DATEADD(day, CAST(RAND() * @RangoDias AS INT), @FechaInicio),
        'Pago membresía/servicio'
    );
    SET @i = @i + 1;
END;
PRINT '...5000 Pagos generados.';
GO

-- =========================================================
-- PASO 4: DESACTIVAR TRIGGER Y CARGAR INSCRIPCIONES
-- =========================================================
PRINT 'PASO 4: Desactivando trigger TR_Inscripciones_Validaciones...';
DISABLE TRIGGER TR_Inscripciones_Validaciones ON Inscripciones;
GO

PRINT '...Iniciando carga masiva de 20,000 inscripciones (esto puede tardar)...';
DECLARE @TotalInscripciones INT = 20000;
DECLARE @FechaInicio DATE = '2023-08-01';
DECLARE @FechaFin DATE = '2025-11-02';
DECLARE @RangoDias INT = DATEDIFF(day, @FechaInicio, @FechaFin);
DECLARE @MinSocioID INT = (SELECT MIN(SocioID) FROM Socios);
DECLARE @MaxSocioID INT = (SELECT MAX(SocioID) FROM Socios);
DECLARE @i INT = 1;

WHILE @i <= @TotalInscripciones
BEGIN
    -- 1. Seleccionar una Fecha Aleatoria
    DECLARE @FechaInsc_Insc DATE = DATEADD(day, CAST(RAND() * @RangoDias AS INT), @FechaInicio);
    
    -- 2. Encontrar el día de la semana de esa fecha
    DECLARE @DiaDeLaSemanaDeFecha INT = DATEPART(weekday, @FechaInsc_Insc);
    
    -- 3. Seleccionar un Socio Aleatorio
    DECLARE @SocioID_Insc INT = (SELECT CAST(((@MaxSocioID - @MinSocioID) * RAND() + @MinSocioID) AS INT));
    
    -- 4. Seleccionar un Horario Aleatorio *que coincida con ese día de la semana*
    DECLARE @HorarioID_Insc INT;
    SELECT TOP 1 @HorarioID_Insc = HorarioID 
    FROM Horarios 
    WHERE DiaDeLaSemana = @DiaDeLaSemanaDeFecha 
    ORDER BY NEWID(); -- Tomar uno al azar de ese día

    -- 5. Insertar (El trigger está apagado, pero los datos respetan la Regla 1)
    IF @HorarioID_Insc IS NOT NULL
    BEGIN
        INSERT INTO Inscripciones (SocioID, HorarioID, FechaInscripcion)
        VALUES (@SocioID_Insc, @HorarioID_Insc, @FechaInsc_Insc);
        
        SET @i = @i + 1;
    END
    -- (Si no hay horario para ese día, el bucle simplemente itera de nuevo)
END;
PRINT '...Carga masiva de inscripciones completada.';
GO

-- =========================================================
-- PASO 5: REACTIVAR EL TRIGGER
-- =========================================================
PRINT 'PASO 5: Reactivando trigger TR_Inscripciones_Validaciones...';
ENABLE TRIGGER TR_Inscripciones_Validaciones ON Inscripciones;
GO