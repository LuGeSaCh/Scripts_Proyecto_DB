-- ===========================================
-- ROLES Y PERMISOS
-- ===========================================
PRINT 'Creando roles de seguridad...';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Gerente' AND type = 'R')
    CREATE ROLE Rol_Gerente;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Recepcion' AND type = 'R')
    CREATE ROLE Rol_Recepcion;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Entrenador' AND type = 'R')
    CREATE ROLE Rol_Entrenador;
GO

-- ===========================================
-- ASIGNACIÓN DE PERMISOS
-- ===========================================

-- Rol Gerente (Control total)
GRANT SELECT, INSERT, UPDATE, DELETE ON Socios TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Entrenadores TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Pagos TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Espacios TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Clases_Catalogo TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Espacio_ClasesPermitidas TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Horarios TO Rol_Gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON Inscripciones TO Rol_Gerente;
GRANT SELECT ON V_EstadoSocios TO Rol_Gerente;
GRANT VIEW DEFINITION TO Rol_Gerente;
GO

-- Rol Recepción (Gestión diaria)
GRANT SELECT, INSERT, UPDATE ON Socios TO Rol_Recepcion;
GRANT SELECT, INSERT ON Pagos TO Rol_Recepcion;
GRANT SELECT, INSERT, DELETE ON Inscripciones TO Rol_Recepcion;
GRANT SELECT ON V_EstadoSocios TO Rol_Recepcion;
GRANT SELECT ON Horarios TO Rol_Recepcion;
GRANT SELECT ON Clases_Catalogo TO Rol_Recepcion;
GRANT SELECT ON Espacios TO Rol_Recepcion;
GRANT SELECT ON Entrenadores TO Rol_Recepcion;
GO

-- Rol Entrenador (Solo consulta)
GRANT SELECT ON Entrenadores TO Rol_Entrenador;
GRANT SELECT ON Horarios TO Rol_Entrenador;
GRANT SELECT ON Inscripciones TO Rol_Entrenador;
GRANT SELECT ON Clases_Catalogo TO Rol_Entrenador;
GRANT SELECT ON Espacios TO Rol_Entrenador;
GRANT SELECT ON V_Socios_Basico TO Rol_Entrenador;
GO

PRINT 'Creacion completa';