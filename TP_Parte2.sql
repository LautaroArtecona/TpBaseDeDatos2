-- ESTE TRABAJO LO HICE SOLO, NO TENGO GRUPO


-- Trigger de actualizacion de devolucion de prestamo

CREATE TRIGGER TRG_DEVOLUCION_LIBRO
ON PRESTAMO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(F_DEVOL)
    BEGIN

        UPDATE C
        SET ESTADO = 'D' 
        FROM COPIAS C
        INNER JOIN INSERTED I ON C.NRO_LIBRO = I.NRO_LIBRO AND C.NRO_COPIA = I.NRO_COPIA
        INNER JOIN DELETED D ON D.NRO_LECTOR = I.NRO_LECTOR 
                             AND D.NRO_LIBRO = I.NRO_LIBRO 
                             AND D.NRO_COPIA = I.NRO_COPIA 
                             AND D.F_PREST = I.F_PREST
        
        WHERE D.F_DEVOL IS NULL AND I.F_DEVOL IS NOT NULL;
    END
END;
GO



-- Funcion que devuelva la cantidad de libros no devueltos por un lector

CREATE FUNCTION FN_CANTIDAD_L_PENDIENTES (@NroLector INT)
RETURNS INT
AS
BEGIN
    DECLARE @Cantidad INT;

    SELECT @Cantidad = COUNT(*)
    FROM PRESTAMO
    WHERE NRO_LECTOR = @NroLector
      AND F_DEVOL IS NULL; 

    RETURN @Cantidad;
END;
GO


-- Vista de inconsistencias

CREATE VIEW V_INCONS_PRESTAMOS AS
SELECT 
    C.NRO_LIBRO,
    C.NRO_COPIA,
    C.ESTADO AS Estado_Copia,
    CASE 
        WHEN C.ESTADO = 'D' THEN 'ERROR: Figura Disponible pero tiene préstamo activo'
        ELSE 'ERROR: Figura Prestada pero no existe préstamo activo'
    END AS Descripcion_Inconsistencia
FROM COPIAS C
-- Buscamos si existe un préstamo activo para esta copia
LEFT JOIN PRESTAMO P ON C.NRO_LIBRO = P.NRO_LIBRO 
                     AND C.NRO_COPIA = P.NRO_COPIA 
                     AND P.F_DEVOL IS NULL
WHERE 
    -- Dice D pero encontro un préstamo
    (C.ESTADO = 'D' AND P.NRO_LECTOR IS NOT NULL)
    OR
    -- Dice P pero el No encontro préstamo
    (C.ESTADO = 'P' AND P.NRO_LECTOR IS NULL);
GO

-- SP y Transaccion TRY/CATCH

CREATE PROCEDURE SP_REGISTRAR_PRESTAMO
    @NroLector INT,
    @NroLibro INT,
    @NroCopia SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar si la copia existe y está disponible 
        DECLARE @EstadoCopia CHAR(1);
        
        SELECT @EstadoCopia = ESTADO 
        FROM COPIAS 
        WHERE NRO_LIBRO = @NroLibro AND NRO_COPIA = @NroCopia;

        IF @EstadoCopia IS NULL
        BEGIN;
            THROW 51000, 'La copia especificada no existe.', 1;
        END;

        IF @EstadoCopia <> 'D'
        BEGIN;
            THROW 51001, 'La copia no está disponible para préstamo (Está Prestada o No disponible).', 1;
        END;

        -- Valida si el lector está habilitado
        IF EXISTS (SELECT 1 FROM LECTOR WHERE NRO_LECTOR = @NroLector AND ESTADO <> 'H')
        BEGIN;
             THROW 51002, 'El lector no está habilitado para pedir préstamos.', 1;
        END;

        -- Inserta el préstamo 
        INSERT INTO PRESTAMO (NRO_LECTOR, NRO_LIBRO, NRO_COPIA, F_PREST, F_DEVOL)
        VALUES (@NroLector, @NroLibro, @NroCopia, GETDATE(), NULL);

        -- Actualiza el estado de la copia a 'P' 
        UPDATE COPIAS
        SET ESTADO = 'P'
        WHERE NRO_LIBRO = @NroLibro AND NRO_COPIA = @NroCopia;

        COMMIT TRANSACTION; 
        PRINT 'Préstamo registrado exitosamente.';
    END TRY
    BEGIN CATCH
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Muestra el error
        DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@MensajeError, 16, 1);
    END CATCH
END;
GO





/*
===================================================
                       Testeo
===================================================
*/


-- EJECUCION DE LA TRANSACCION y SP
-- Prestamos libro 5078912 (Las mil y una noches), Copia 1 a Gomez Arnoldo

DECLARE @Lector INT = 123456;
DECLARE @Libro INT = 5078912;
DECLARE @Copia SMALLINT = 1;

-- Llamamos al SP
EXEC SP_REGISTRAR_PRESTAMO @Lector, @Libro, @Copia;


-- VERIFICACION POST-PRESTAMO: La copia dice que esta prestada
SELECT * FROM COPIAS WHERE NRO_LIBRO = 5078912 AND NRO_COPIA = 1;

-- Dice que el lector tiene libros pendientes
SELECT dbo.FN_CANTIDAD_L_PENDIENTES(123456) AS Cantidad_Libros_Tomados;
GO

-- PRUEBA DEL TRIGGER: Simulamos que el lector devuelve el libro hoy
UPDATE PRESTAMO 
SET F_DEVOL = GETDATE()
WHERE NRO_LECTOR = 123456 AND NRO_LIBRO = 5078912 AND NRO_COPIA = 1 AND F_DEVOL IS NULL;

PRINT ' PRUEBA 2: Devolución registrada (Trigger disparado).';
GO

-- La copia debe haber vuelto a Disponible
SELECT * FROM COPIAS WHERE NRO_LIBRO = 5078912 AND NRO_COPIA = 1;

-- Consulta de inconsistencias, mueestra las inconsistencias del dml
SELECT * FROM V_INCONS_PRESTAMOS; 
GO
