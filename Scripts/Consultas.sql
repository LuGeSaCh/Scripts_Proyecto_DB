USE GimnasioDB;

GO

/* 
=======================================================
1. Consultas de ingreso
=======================================================
*/

-- 1.1 COMPARACION POR MES

WITH IngresosMensuales AS (
    SELECT 
        FORMAT(FechaPago, 'yyyy-MM') AS AnioMes,
        SUM(Monto) AS IngresoTotalMensual
    FROM 
        Pagos
    GROUP BY 
        FORMAT(FechaPago, 'yyyy-MM')
),

-- CTE 2: Aplicamos la Función Ventana LAG()
IngresosConMesAnterior AS (
    SELECT
        AnioMes,
        IngresoTotalMensual, -- <-- ARREGLO 1: Era COUNT(IngresoTotalMensual)
        
        -- Aquí está la Función Ventana:
        LAG(IngresoTotalMensual, 1, 0) OVER (ORDER BY AnioMes ASC) AS IngresoMesAnterior
    FROM
        IngresosMensuales
)
-- Paso Final: Calculamos la diferencia y el porcentaje de crecimiento
SELECT 
    AnioMes,
    IngresoTotalMensual, -- <-- ARREGLO 2: Esto ahora funciona
    IngresoMesAnterior,
    (IngresoTotalMensual - IngresoMesAnterior) AS Diferencia_Vs_MesAnterior,
    
    CAST(
        ( (IngresoTotalMensual - IngresoMesAnterior) * 100.0 / NULLIF(IngresoMesAnterior, 0) ) 
        AS DECIMAL(10, 2)
    ) AS Crecimiento_Porcentual_MoM
FROM 
    IngresosConMesAnterior
ORDER BY 
    AnioMes DESC;

-- 1.2 COMPARATIVA POR ANNIO

-- CTE 1: Obtenemos los ingresos totales por AÑO
WITH IngresosAnuales AS (
    SELECT 
        YEAR(FechaPago) AS Anio,
        SUM(Monto) AS IngresoTotalAnual
    FROM 
        Pagos
    GROUP BY 
        YEAR(FechaPago)
),

-- CTE 2: Aplicamos la Función Ventana LAG()
IngresosConAnioAnterior AS (
    SELECT
        Anio,
        IngresoTotalAnual,
        
        -- Función Ventana:
        -- Obtiene el 'IngresoTotalAnual' de la fila anterior (1),
        -- ordenado por 'Anio'. Si no hay año anterior, usa 0.
        LAG(IngresoTotalAnual, 1, 0) OVER (ORDER BY Anio ASC) AS IngresoAnioAnterior
    FROM
        IngresosAnuales
)
-- Paso Final: Calculamos la diferencia y el porcentaje de crecimiento
SELECT 
    Anio,
    IngresoTotalAnual,
    IngresoAnioAnterior,
    (IngresoTotalAnual - IngresoAnioAnterior) AS Diferencia_Vs_AnioAnterior,
    
    -- Usamos NULLIF para evitar un error de división por cero
    CAST(
        ( (IngresoTotalAnual - IngresoAnioAnterior) * 100.0 / NULLIF(IngresoAnioAnterior, 0) ) 
        AS DECIMAL(10, 2)
    ) AS Crecimiento_Porcentual_YoY
FROM 
    IngresosConAnioAnterior
ORDER BY 
    Anio DESC; -- Mostramos los años más recientes primero


/* 
=======================================================
2. Consultas de inscripciones
=======================================================
*/

-- 2.1 INSCRIPCIONES POR AnioMES
WITH ConteoAnualMes AS (
    SELECT 
        FORMAT(FechaInscripcion, 'yyyy-MM') AS AnioMes,
        COUNT(InscripcionID) AS TotalInscripciones
    FROM 
        Inscripciones
    GROUP BY 
        FORMAT(FechaInscripcion, 'yyyy-MM')
),

-- CTE 2: Aplicamos la Función Ventana LAG()
InscripcionesConAnioMesAnterior AS (
    SELECT
        AnioMes,
        TotalInscripciones,
        
        -- Función Ventana:
        LAG(TotalInscripciones, 1, 0) OVER (ORDER BY AnioMes ASC) AS InscripcionesAnioMesAnterior
    FROM
        ConteoAnualMes
)
-- Paso Final: Calculamos la diferencia y el porcentaje de crecimiento
SELECT 
    AnioMes,
    TotalInscripciones,
    InscripcionesAnioMesAnterior,
    (TotalInscripciones - InscripcionesAnioMesAnterior) AS Diferencia_Vs_AnioMesAnterior,
    
    -- Usamos NULLIF para evitar un error de división por cero
    CAST(
        ( (TotalInscripciones - InscripcionesAnioMesAnterior) * 100.0 / NULLIF(InscripcionesAnioMesAnterior, 0) ) 
        AS DECIMAL(10, 2)
    ) AS Crecimiento_Porcentual_MoM -- <-- Alias corregido
FROM 
    InscripcionesConAnioMesAnterior
ORDER BY 
    AnioMes DESC;

-- 2.2 INSCRIPCIONES POR ANIO

WITH ConteoAnual AS (
    SELECT 
        YEAR(FechaInscripcion) AS Anio,
        COUNT(InscripcionID) AS TotalInscripciones
    FROM 
        Inscripciones
    GROUP BY 
        YEAR(FechaInscripcion)
),

-- CTE 2: Aplicamos la Función Ventana LAG()
InscripcionesConAnioAnterior AS (
    SELECT
        Anio,
        TotalInscripciones,
        
        -- Función Ventana:
        -- Obtiene el 'TotalInscripciones' de la fila anterior (1),
        -- ordenado por 'Anio'. Si no hay año anterior, usa 0.
        LAG(TotalInscripciones, 1, 0) OVER (ORDER BY Anio ASC) AS InscripcionesAnioAnterior
    FROM
        ConteoAnual
)
-- Paso Final: Calculamos la diferencia y el porcentaje de crecimiento
SELECT 
    Anio,
    TotalInscripciones,
    InscripcionesAnioAnterior,
    (TotalInscripciones - InscripcionesAnioAnterior) AS Diferencia_Vs_AnioAnterior,
    
    -- Usamos NULLIF para evitar un error de división por cero
    CAST(
        ( (TotalInscripciones - InscripcionesAnioAnterior) * 100.0 / NULLIF(InscripcionesAnioAnterior, 0) ) 
        AS DECIMAL(10, 2)
    ) AS Crecimiento_Porcentual_YoY
FROM 
    InscripcionesConAnioAnterior
ORDER BY 
    Anio DESC; -- Mostramos los años más recientes primero


-- 2.3 DIFERENCIA POR GENERO DE INSCRIPCIONES AL ANIO
WITH ConteoPorGeneroAnio AS (
    SELECT 
        YEAR(i.FechaInscripcion) AS Anio,
        
        -- Contamos Hombres (M)
        SUM(CASE 
                WHEN s.Genero = 'M' THEN 1 
                ELSE 0 
            END) AS Inscripciones_Hombres,
        
        -- Contamos Mujeres (F)
        SUM(CASE 
                WHEN s.Genero = 'F' THEN 1 
                ELSE 0 
            END) AS Inscripciones_Mujeres,

        -- (Opcional) Contamos 'Otros'
        SUM(CASE 
                WHEN s.Genero = 'O' THEN 1 
                ELSE 0 
            END) AS Inscripciones_Otro
            
    FROM 
        Inscripciones i
    JOIN 
        Socios s ON i.SocioID = s.SocioID -- Unimos con Socios para obtener el Género
    GROUP BY 
        YEAR(i.FechaInscripcion)
)
-- Paso Final: Seleccionamos los conteos y calculamos la diferencia
SELECT 
    Anio,
    Inscripciones_Hombres,
    Inscripciones_Mujeres,
    Inscripciones_Otro,
    (Inscripciones_Hombres - Inscripciones_Mujeres) AS Diferencia_Hombres_vs_Mujeres,
	(Inscripciones_Hombres - Inscripciones_Otro) AS Diferencia_Hombres_vs_Otro,
	(Inscripciones_Mujeres - Inscripciones_Otro) AS Diferencia_Mujeres_vs_Otro
FROM 
    ConteoPorGeneroAnio
ORDER BY 
    Anio DESC;


-- 2.4 RANKING DE ENTRENADORES MAS INSCRITOS

WITH ConteoPorEntrenador AS (
    SELECT 
        e.EntrenadorID,
        e.Nombre,
        e.Apellido,
        e.Especialidad,
        e.Genero,
        -- Contamos cuántas filas de 'Inscripciones' están asociadas a cada entrenador
        COUNT(i.InscripcionID) AS TotalInscritos
    FROM 
        Inscripciones i
    JOIN 
        Horarios h ON i.HorarioID = h.HorarioID
    JOIN 
        Entrenadores e ON h.EntrenadorID = e.EntrenadorID
    GROUP BY 
        e.EntrenadorID, e.Nombre, e.Apellido, e.Especialidad, e.Genero
)
-- Paso Final: Aplicamos la función ventana DENSE_RANK() a los conteos
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalInscritos DESC) AS Ranking,
    Nombre,
    Apellido,
    Especialidad,
    Genero,
    TotalInscritos
FROM 
    ConteoPorEntrenador
ORDER BY 
    Ranking ASC; 

/* 
=======================================================
4. Consultas de catalogo 
=======================================================
*/

-- 4.1 RANKING DE INSCRIPCIONES POR CLASES
WITH ConteoMensualPorClase AS (
    SELECT 
        FORMAT(i.FechaInscripcion, 'yyyy-MM') AS AnioMes,
        cc.NombreClase,
        COUNT(i.InscripcionID) AS TotalInscripciones
    FROM 
        Inscripciones i
    JOIN 
        Horarios h ON i.HorarioID = h.HorarioID
    JOIN 
        Clases_Catalogo cc ON h.CatalogoID = cc.CatalogoID
    GROUP BY 
        FORMAT(i.FechaInscripcion, 'yyyy-MM'), cc.NombreClase
)
-- CTE 2: Aplicamos la Función Ventana DENSE_RANK()
SELECT 
    AnioMes,
    
    -- Se particiona por AnioMes para que el ranking (1, 2, 3...)
    -- se reinicie cada mes.
    DENSE_RANK() OVER (
        PARTITION BY AnioMes 
        ORDER BY TotalInscripciones DESC
    ) AS Ranking,
    
    NombreClase,
    TotalInscripciones
FROM 
    ConteoMensualPorClase
ORDER BY 
    AnioMes DESC, Ranking ASC;



/* 
=======================================================
5. Consultas de horarios 
=======================================================
*/


-- 5.1 CONSULTA DE HORARIOS E INSCRITOS DE LOS LOS ULTIMOS DIAS 7 antes y 6 adelante de hoy 
SET DATEFIRST 1;

SELECT 
    i.FechaInscripcion AS Dia_Evento,
    CASE DATEPART(weekday, i.FechaInscripcion)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS Dia_Semana,

    -- Columnas de Horarios
    h.HoraInicio,
    h.HoraFin,
    
    -- Detalles de las tablas unidas
    cc.NombreClase,
    e.Nombre + ' ' + e.Apellido AS Entrenador,
    esp.NombreEspacio AS Espacio,

    -- Conteo
    COUNT(i.InscripcionID) AS TotalInscritos,
    h.CapacidadMaxima,
    (h.CapacidadMaxima - COUNT(i.InscripcionID)) AS CuposDisponibles

FROM 
    Inscripciones i
JOIN 
    Horarios h ON i.HorarioID = h.HorarioID
JOIN 
    Clases_Catalogo cc ON h.CatalogoID = cc.CatalogoID
JOIN 
    Entrenadores e ON h.EntrenadorID = e.EntrenadorID
JOIN 
    Espacios esp ON h.EspacioID = esp.EspacioID
WHERE 
    -- Filtramos por el rango de 14 días (7 antes, 6 después)
    i.FechaInscripcion BETWEEN DATEADD(day, -7, GETDATE()) AND DATEADD(day, 6, GETDATE())
GROUP BY 
    i.FechaInscripcion,
    h.HoraInicio,
    h.HoraFin,
    cc.NombreClase,
    e.Nombre,
    e.Apellido,
    esp.NombreEspacio,
    h.CapacidadMaxima
ORDER BY 
    i.FechaInscripcion ASC, 
    h.HoraInicio ASC;