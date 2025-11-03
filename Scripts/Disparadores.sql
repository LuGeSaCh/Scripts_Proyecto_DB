USE GimnasioDB;
GO

-- VALIDACIONES DE FECHAS DE HORARIO
PRINT 'Creando Trigger para control de conflictos de horarios...';

IF OBJECT_ID('TR_Horarios_Conflictos', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER TR_Horarios_Conflictos;
    PRINT 'Trigger existente TR_Horarios_Conflictos eliminado.';
END
GO

CREATE TRIGGER TR_Horarios_Conflictos
ON Horarios -- Se ejecuta sobre la tabla 'Horarios'
AFTER INSERT, UPDATE -- Se dispara después de insertar o actualizar un registro
AS
BEGIN
    SET NOCOUNT ON;

    -- Declaramos variables para los mensajes de error
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ConflictoID INT;

    -- ==========================================================
    -- 1. VERIFICACIÓN DE CONFLICTO DE ESPACIO (SALA)
    -- ==========================================================
    -- Comprobamos si existe algún registro en 'Horarios' (h) que se solape
    -- con el nuevo registro que se está insertando ('inserted' i).

    IF EXISTS (
        SELECT 1
        FROM Horarios h
        JOIN inserted i ON 
            h.EspacioID = i.EspacioID         -- Misma sala
            AND h.DiaDeLaSemana = i.DiaDeLaSemana -- Mismo día de la semana
            AND h.HorarioID <> i.HorarioID    -- Que no sea el mismo registro (en caso de UPDATE)
        WHERE
            -- Lógica de solapamiento de tiempo:
            -- (La nueva clase empieza ANTES de que termine la existente)
            (i.HoraInicio < h.HoraFin) 
            AND 
            -- (La nueva clase termina DESPUÉS de que empiece la existente)
            (i.HoraFin > h.HoraInicio)
    )
    BEGIN
        -- Si entramos aquí, hay un conflicto de ESPACIO.
        -- Obtenemos el ID del horario con el que choca para mostrar un mejor error.
        SELECT TOP 1 @ConflictoID = h.HorarioID
        FROM Horarios h
        JOIN inserted i ON h.EspacioID = i.EspacioID AND h.DiaDeLaSemana = i.DiaDeLaSemana AND h.HorarioID <> i.HorarioID
        WHERE (i.HoraInicio < h.HoraFin) AND (i.HoraFin > h.HoraInicio);
        
        SET @ErrorMessage = FORMATMESSAGE('Error de Conflicto de Horario: El ESPACIO ya está reservado en ese día y hora por el HorarioID: %d.', @ConflictoID);
        
        -- RAISERROR genera un error personalizado
        RAISERROR (@ErrorMessage, 16, 1);
        -- ROLLBACK TRANSACTION cancela la operación (INSERT/UPDATE)
        ROLLBACK TRANSACTION;
        RETURN; -- Salimos del trigger
    END

    -- ==========================================================
    -- 2. VERIFICACIÓN DE CONFLICTO DE ENTRENADOR
    -- ==========================================================
    -- Misma lógica, pero ahora comparamos el EntrenadorID

    IF EXISTS (
        SELECT 1
        FROM Horarios h
        JOIN inserted i ON 
            h.EntrenadorID = i.EntrenadorID   -- Mismo entrenador
            AND h.DiaDeLaSemana = i.DiaDeLaSemana -- Mismo día de la semana
            AND h.HorarioID <> i.HorarioID    -- Que no sea el mismo registro
        WHERE
            -- Lógica de solapamiento de tiempo:
            (i.HoraInicio < h.HoraFin) 
            AND 
            (i.HoraFin > h.HoraInicio)
    )
    BEGIN
        -- Si entramos aquí, hay un conflicto de ENTRENADOR.
        SELECT TOP 1 @ConflictoID = h.HorarioID
        FROM Horarios h
        JOIN inserted i ON h.EntrenadorID = i.EntrenadorID AND h.DiaDeLaSemana = i.DiaDeLaSemana AND h.HorarioID <> i.HorarioID
        WHERE (i.HoraInicio < h.HoraFin) AND (i.HoraFin > h.HoraInicio);

        SET @ErrorMessage = FORMATMESSAGE('Error de Conflicto de Horario: El ENTRENADOR ya está asignado a otra clase en ese día y hora (HorarioID: %d).', @ConflictoID);
        
        RAISERROR (@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

END;
GO


-- VALIDACIONES DE INSCRIPCION DE HORARIO

IF OBJECT_ID('TR_Inscripciones_Validaciones', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER TR_Inscripciones_Validaciones;
    PRINT 'Trigger existente TR_Inscripciones_Validaciones eliminado.';
END
GO

CREATE TRIGGER TR_Inscripciones_Validaciones
ON Inscripciones -- Se ejecuta sobre la tabla 'Inscripciones'
AFTER INSERT, UPDATE
AS
BEGIN
    -- Configuración para que Lunes sea el día 1 (igual que nuestro CHECK)
    SET DATEFIRST 1;
    SET NOCOUNT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);
    
    -- Variables para la nueva inscripción
    DECLARE @SocioID INT, @HorarioID INT, @FechaInscripcion DATE;
    -- Variables del Horario
    DECLARE @DiaSemanaHorario INT, @CapacidadMaxima INT;
    DECLARE @HoraInicioNueva TIME, @HoraFinNueva TIME;

    -- Obtenemos los datos de la fila que se está insertando/actualizando
    SELECT 
        @SocioID = i.SocioID,
        @HorarioID = i.HorarioID,
        @FechaInscripcion = i.FechaInscripcion
    FROM 
        inserted i;

    -- Obtenemos los detalles del Horario correspondiente
    SELECT
        @DiaSemanaHorario = h.DiaDeLaSemana,
        @CapacidadMaxima = h.CapacidadMaxima,
        @HoraInicioNueva = h.HoraInicio,
        @HoraFinNueva = h.HoraFin
    FROM
        Horarios h
    WHERE
        h.HorarioID = @HorarioID;

    -- ==========================================================
    -- REGLA 1: VALIDACIÓN DEL DÍA DE LA SEMANA
    -- ==========================================================
    IF (DATEPART(weekday, @FechaInscripcion) <> @DiaSemanaHorario)
    BEGIN
        SET @ErrorMessage = FORMATMESSAGE('Error de Regla: La fecha de inscripción (%s) no es un día %d (Día de la semana del horario).', 
                                          CONVERT(VARCHAR, @FechaInscripcion, 103), 
                                          @DiaSemanaHorario);
        RAISERROR (@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- ==========================================================
    -- REGLA 2: CONTROL DE CAPACIDAD (CLASE LLENA)
    -- ==========================================================
    DECLARE @InscritosActuales INT;
    
    -- Contamos cuántos hay para ESTE horario en ESTA fecha
    SELECT 
        @InscritosActuales = COUNT(*)
    FROM 
        Inscripciones
    WHERE 
        HorarioID = @HorarioID 
        AND FechaInscripcion = @FechaInscripcion;
    
    IF (@InscritosActuales > @CapacidadMaxima) -- Se usa > porque el INSERT/UPDATE ya ocurrió
    BEGIN
        SET @ErrorMessage = FORMATMESSAGE('Error de Capacidad: La clase (HorarioID: %d) ya está llena para la fecha %s. Capacidad: %d.', 
                                          @HorarioID, 
                                          CONVERT(VARCHAR, @FechaInscripcion, 103), 
                                          @CapacidadMaxima);
        RAISERROR (@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- ==========================================================
    -- REGLA 3: CONFLICTO DE HORARIO DEL SOCIO
    -- ==========================================================
    IF EXISTS (
        SELECT 1
        FROM 
            Inscripciones i
        JOIN 
            Horarios h_otro ON i.HorarioID = h_otro.HorarioID -- El horario de la clase YA inscrita
        WHERE 
            i.SocioID = @SocioID -- Mismo socio
            AND i.FechaInscripcion = @FechaInscripcion -- Mismo día
            AND i.HorarioID <> @HorarioID -- Clases diferentes
            AND
            -- Lógica de solapamiento de tiempo
            (h_otro.HoraInicio < @HoraFinNueva) AND (h_otro.HoraFin > @HoraInicioNueva)
    )
    BEGIN
        SET @ErrorMessage = FORMATMESSAGE('Error de Conflicto: El socio (SocioID: %d) ya está inscrito en otra clase que se solapa en ese horario el día %s.', 
                                          @SocioID, 
                                          CONVERT(VARCHAR, @FechaInscripcion, 103));
        RAISERROR (@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

END;
GO

PRINT 'Trigger TR_Inscripciones_Validaciones creado exitosamente.';