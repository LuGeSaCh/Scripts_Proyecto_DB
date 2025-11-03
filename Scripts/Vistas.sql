-- 5. VISTA (Lógica de Negocio de Pagos)
----------------------------------------------------------
PRINT 'Creando Vista V_EstadoSocios...';

USE GimnasioDB;
GO

CREATE VIEW V_EstadoSocios
AS
SELECT 
    s.SocioID,
    s.Nombre,
    s.Apellido,
    s.Email,
    s.TipoMembresia,
    ISNULL(p.UltimoPago, '1900-01-01') AS UltimoPago,
    
    -- Lógica de negocio para el estado de pago:
    CASE 
        WHEN p.UltimoPago IS NULL THEN 'Pendiente (Sin Pagos)'
        WHEN s.TipoMembresia = 'Mensual' AND DATEDIFF(day, p.UltimoPago, GETDATE()) > 30 THEN 'Pendiente'
        WHEN s.TipoMembresia = 'Trimestral' AND DATEDIFF(day, p.UltimoPago, GETDATE()) > 90 THEN 'Pendiente'
        WHEN s.TipoMembresia = 'Anual' AND DATEDIFF(day, p.UltimoPago, GETDATE()) > 365 THEN 'Pendiente'
        ELSE 'Al Dia'
    END AS EstadoPago
FROM 
    Socios s
LEFT JOIN (
    -- Subconsulta para obtener solo la fecha del último pago por socio
    SELECT SocioID, MAX(FechaPago) AS UltimoPago
    FROM Pagos
    GROUP BY SocioID
) p ON s.SocioID = p.SocioID;

-- Segunda view --

CREATE VIEW V_Socios_Basico
AS
SELECT Nombre, Apellido
FROM Socios;
