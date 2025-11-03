/* =========================================================
   PROYECTO DE CÁTEDRA: ADMINISTRACIÓN DE BASES DE DATOS
   ESCENARIO: 1. SISTEMA DE RESERVAS DE GIMNASIO (Script v5 - Solo Tablas/Índices)
   
   CONTENIDO:
   1. Tablas Maestras
   2. Tabla de Pagos
   3. Tablas de Gestión de Clases
   4. Tabla Inscripciones (Modificada, sin UQ)
   5. Índices de Optimización
=========================================================
*/

USE GimnasioDB;
GO

-- 2. TABLAS MAESTRAS
----------------------------------------------------------
CREATE TABLE Entrenadores (
    EntrenadorID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Especialidad NVARCHAR(100),
    Email NVARCHAR(100) UNIQUE NOT NULL,
    FechaContratacion DATE DEFAULT GETDATE(),
    Genero CHAR(1) NOT NULL,
    CONSTRAINT CHK_Entrenadores_Genero CHECK (Genero IN ('M', 'F', 'O'))
);

CREATE TABLE Socios (
    SocioID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    FechaInscripcion DATE DEFAULT GETDATE(),
    TipoMembresia NVARCHAR(50) CHECK (TipoMembresia IN ('Mensual', 'Trimestral', 'Anual')) NOT NULL,
    Genero CHAR(1) NOT NULL,
    CONSTRAINT CHK_Socios_Genero CHECK (Genero IN ('M', 'F', 'O'))
);


-- 3. TABLA DE PAGOS
----------------------------------------------------------
CREATE TABLE Pagos (
    PagoID INT PRIMARY KEY IDENTITY(1,1),
    SocioID INT FOREIGN KEY REFERENCES Socios(SocioID) ON DELETE CASCADE NOT NULL,
    Monto DECIMAL(10, 2) NOT NULL,
    FechaPago DATETIME DEFAULT GETDATE(),
    Concepto NVARCHAR(200)
);


-- 4. GESTIÓN DE CLASES
----------------------------------------------------------
CREATE TABLE Espacios (
    EspacioID INT PRIMARY KEY IDENTITY(1,1),
    NombreEspacio NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(250)
);

CREATE TABLE Clases_Catalogo (
    CatalogoID INT PRIMARY KEY IDENTITY(1,1),
    NombreClase NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(500)
);

CREATE TABLE Espacio_ClasesPermitidas (
    EspacioID INT NOT NULL,
    CatalogoID INT NOT NULL,
    CONSTRAINT FK_EspacioClase_Espacio FOREIGN KEY (EspacioID) REFERENCES Espacios(EspacioID) ON DELETE CASCADE,
    CONSTRAINT FK_EspacioClase_Catalogo FOREIGN KEY (CatalogoID) REFERENCES Clases_Catalogo(CatalogoID) ON DELETE CASCADE,
    CONSTRAINT PK_Espacio_ClasesPermitidas PRIMARY KEY (EspacioID, CatalogoID)
);

CREATE TABLE Horarios (
    HorarioID INT PRIMARY KEY IDENTITY(1,1),
    EntrenadorID INT FOREIGN KEY REFERENCES Entrenadores(EntrenadorID),
    EspacioID INT NOT NULL,
    CatalogoID INT NOT NULL,
    DiaDeLaSemana INT NOT NULL CHECK (DiaDeLaSemana BETWEEN 1 AND 7),
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL,
    CapacidadMaxima INT NOT NULL,
    CONSTRAINT FK_Horario_ReglaPermitida 
        FOREIGN KEY (EspacioID, CatalogoID) 
        REFERENCES Espacio_ClasesPermitidas (EspacioID, CatalogoID)
);


-- 5. TABLA INSCRIPCIONES (MODIFICADA)
----------------------------------------------------------
CREATE TABLE Inscripciones (
    InscripcionID INT PRIMARY KEY IDENTITY(1,1),
    SocioID INT FOREIGN KEY REFERENCES Socios(SocioID) ON DELETE CASCADE NOT NULL,
    HorarioID INT FOREIGN KEY REFERENCES Horarios(HorarioID) ON DELETE CASCADE NOT NULL,
    FechaInscripcion DATE DEFAULT GETDATE()
    -- Se eliminó la restricción UQ_Socio_Horario
);


-- 7. ÍNDICES DE OPTIMIZACIÓN
----------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Socios_Apellido' AND object_id = OBJECT_ID('Socios'))
    CREATE NONCLUSTERED INDEX IX_Socios_Apellido ON Socios (Apellido ASC);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Socios_Analitico')
    CREATE NONCLUSTERED INDEX IX_Socios_Analitico ON Socios (Genero, TipoMembresia);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Horarios_CatalogoID')
    CREATE NONCLUSTERED INDEX IX_Horarios_CatalogoID ON Horarios (CatalogoID) INCLUDE (EntrenadorID, EspacioID);