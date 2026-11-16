SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;


GO
IF DB_ID(N'ANCEPRACTICA') IS NULL
    CREATE DATABASE ANCEPRACTICA;


GO
USE ANCEPRACTICA;

DROP TABLE IF EXISTS dbo.HistorialSolicitud;
DROP TABLE IF EXISTS dbo.Solicitud;
DROP TABLE IF EXISTS dbo.TransicionEstado;
DROP TABLE IF EXISTS dbo.TipoAccion;
DROP TABLE IF EXISTS dbo.Responsable;
DROP TABLE IF EXISTS dbo.TipoSolicitud;
DROP TABLE IF EXISTS dbo.Prioridad;
DROP TABLE IF EXISTS dbo.EstadoSolicitud;
DROP SEQUENCE IF EXISTS dbo.SeqFolioSolicitud;
GO

CREATE TABLE dbo.EstadoSolicitud (
    EstadoId TINYINT       NOT NULL CONSTRAINT PK_EstadoSolicitud PRIMARY KEY,
    Nombre   NVARCHAR (30) NOT NULL CONSTRAINT UQ_EstadoSolicitud_Nombre UNIQUE,
    EsFinal  BIT           CONSTRAINT DF_EstadoSolicitud_EsFinal DEFAULT (0) NOT NULL
);

CREATE TABLE dbo.TransicionEstado (
    EstadoOrigenId  TINYINT NOT NULL CONSTRAINT FK_TransicionEstado_EstadoOrigenId FOREIGN KEY REFERENCES dbo.EstadoSolicitud (EstadoId),
    EstadoDestinoId TINYINT NOT NULL CONSTRAINT FK_TransicionEstado_EstadoDestinoId FOREIGN KEY REFERENCES dbo.EstadoSolicitud (EstadoId),
    CONSTRAINT PK_TransicionEstado PRIMARY KEY (EstadoOrigenId, EstadoDestinoId),
    CONSTRAINT CK_TransicionEstado_Distintos CHECK (EstadoOrigenId <> EstadoDestinoId)
);

CREATE TABLE dbo.Prioridad (
    PrioridadId TINYINT       NOT NULL CONSTRAINT PK_Prioridad_PrioridadId PRIMARY KEY,
    Nombre      NVARCHAR (20) NOT NULL CONSTRAINT UQ_Prioridad_Nombre UNIQUE,
    Activo      BIT           CONSTRAINT DF_Prioridad_Activo DEFAULT (1) NOT NULL
);

CREATE TABLE dbo.TipoSolicitud (
    TipoSolicitudId TINYINT       NOT NULL CONSTRAINT PK_TipoSolicitud_TipoSolicitudId PRIMARY KEY,
    Nombre          NVARCHAR (50) NOT NULL CONSTRAINT UQ_TipoSolicitud_Nombre UNIQUE,
    Activo          BIT           CONSTRAINT DF_TipoSolicitud_Activo DEFAULT (1) NOT NULL
);

CREATE TABLE dbo.Responsable (
    ResponsableId INT            IDENTITY NOT NULL CONSTRAINT PK_Responsable_ResponsableId PRIMARY KEY,
    Nombre        NVARCHAR (100) NOT NULL CONSTRAINT UQ_Responsable_Nombre UNIQUE,
    Activo        BIT            CONSTRAINT DF_Responsable_Activo DEFAULT (1) NOT NULL
);

CREATE TABLE dbo.TipoAccion (
    TipoAccionId TINYINT       NOT NULL CONSTRAINT PK_TipoAccion_TipoAccionId PRIMARY KEY,
    Nombre       NVARCHAR (30) NOT NULL CONSTRAINT UQ_TipoAccion_Nombre UNIQUE
);
CREATE SEQUENCE dbo.SeqFolioSolicitud AS INT START WITH 1 INCREMENT BY 1;
CREATE TABLE dbo.Solicitud (
    SolicitudId          INT             IDENTITY NOT NULL CONSTRAINT PK_Solicitud_SolicitudId PRIMARY KEY,
    Folio                VARCHAR (20)    NOT NULL CONSTRAINT UQ_Solicitud_Folio UNIQUE,
    Solicitante          NVARCHAR (150)  NOT NULL,
    Correo               NVARCHAR (254)  NOT NULL,
    TipoSolicitudId      TINYINT         NOT NULL CONSTRAINT FK_Solicitud_TipoSolicitudId FOREIGN KEY REFERENCES dbo.TipoSolicitud (TipoSolicitudId),
    Titulo               NVARCHAR (150)  NOT NULL,
    Descripcion          NVARCHAR (4000) NOT NULL,
    PrioridadId            TINYINT         NOT NULL CONSTRAINT FK_Solicitud_Prioridad FOREIGN KEY REFERENCES dbo.Prioridad (PrioridadId),
    ResponsableId        INT             NULL CONSTRAINT FK_Solicitud_ResponsableId FOREIGN KEY REFERENCES dbo.Responsable (ResponsableId),
    EstadoId             TINYINT         NOT NULL CONSTRAINT FK_Solicitud_EstadoId FOREIGN KEY REFERENCES dbo.EstadoSolicitud (EstadoId),
    ComentarioResolucion NVARCHAR (2000) NULL,
    FechaCreacion        DATETIME2       CONSTRAINT DF_Solicitud_FechaCreacion DEFAULT (SYSUTCDATETIME()) NOT NULL,
    FechaActualizacion   DATETIME2       NULL,
    CONSTRAINT CK_Solicitud_EnProcesoConResponsable CHECK (EstadoId <> 2
                                                           OR ResponsableId IS NOT NULL),
    CONSTRAINT CK_Solicitud_ResueltaConComentario CHECK (EstadoId NOT IN (3, 4)
                                                         OR ComentarioResolucion IS NOT NULL),
    CONSTRAINT CK_Solicitud_TituloNoVacio CHECK (LEN(LTRIM(RTRIM(Titulo))) > 0)
);

CREATE TABLE dbo.HistorialSolicitud (
    HistorialId           BIGINT          IDENTITY NOT NULL CONSTRAINT PK_HistorialSolicitud_HistorialId PRIMARY KEY,
    SolicitudId           INT             NOT NULL CONSTRAINT FK_HistorialSolicitud_SolicitudId FOREIGN KEY REFERENCES dbo.Solicitud (SolicitudId),
    TipoAccionId          TINYINT         NOT NULL CONSTRAINT FK_HistorialSolicitud_TipoAccionId FOREIGN KEY REFERENCES dbo.TipoAccion (TipoAccionId),
    EstadoAnteriorId      TINYINT         NULL CONSTRAINT FK_HistorialSolicitud_EstadoAnteriorId FOREIGN KEY REFERENCES dbo.EstadoSolicitud (EstadoId),
    EstadoNuevoId         TINYINT         NULL CONSTRAINT FK_HistorialSolicitud_EstadoNuevoId FOREIGN KEY REFERENCES dbo.EstadoSolicitud (EstadoId),
    ResponsableAnteriorId INT             NULL CONSTRAINT FK_HistorialSolicitud_ResponsableAnteriorId FOREIGN KEY REFERENCES dbo.Responsable (ResponsableId),
    ResponsableNuevoId    INT             NULL CONSTRAINT FK_HistorialSolicitud_ResponsableNuevoId FOREIGN KEY REFERENCES dbo.Responsable (ResponsableId),
    Detalle               NVARCHAR (2500) NOT NULL,
    Fecha                 DATETIME2       CONSTRAINT DF_HistorialSolicitud_Fecha DEFAULT (SYSUTCDATETIME()) NOT NULL
);

CREATE INDEX IX_Solicitud_Estado
    ON dbo.Solicitud(EstadoId);

CREATE INDEX IX_Solicitud_FechaCreacion
    ON dbo.Solicitud(FechaCreacion DESC);

CREATE INDEX IX_Historial_Solicitud_Fecha
    ON dbo.HistorialSolicitud(SolicitudId, Fecha);

INSERT  INTO dbo.EstadoSolicitud (
    EstadoId,
    Nombre,
    EsFinal
)
VALUES (1, N'Nueva', 0),
(2, N'En proceso', 0),
(3, N'Resuelta', 0),
(4, N'Cerrada', 1),
(5, N'Cancelada', 1);


INSERT  INTO dbo.TransicionEstado (
    EstadoOrigenId,
    EstadoDestinoId
)
VALUES(1, 2),
(1, 5),
(2, 3),
(2, 5),
(3, 2),
(3, 4);

INSERT  INTO dbo.Prioridad (
    PrioridadId,
    Nombre
)
VALUES(1, 'Baja'),
(2, 'Media'),
(3, 'Alta'),
(4, 'Critica');

INSERT  INTO dbo.TipoSolicitud (
    TipoSolicitudId,
    Nombre
)
VALUES (1, 'Incidencia'),
(2, 'Acceso'),
(3, 'Requerimiento'),
(4, 'Consulta');
                               
INSERT  INTO dbo.Responsable (
    Nombre
)
VALUES(N'Developer 1'),
(N'Developer 2'),
(N'Developer 3');

INSERT INTO TipoAccion (TipoAccionId, Nombre)
VALUES  (1,'Creación'),
        (2, 'Asignación'),
        (3, 'Cambio de estado'),
        (4, 'Resolución');
GO


CREATE OR ALTER PROCEDURE dbo.sp_Catalogos_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT EstadoId Id, Nombre, EsFinal FROM dbo.EstadoSolicitud ORDER BY EstadoId;
    SELECT PrioridadId Id, Nombre FROM dbo.Prioridad ORDER BY PrioridadId;
    SELECT TipoSolicitudId Id, Nombre FROM dbo.TipoSolicitud ORDER BY Nombre;
    SELECT ResponsableId Id, Nombre FROM dbo.Responsable ORDER BY Nombre;
    SELECT EstadoOrigenId, EstadoDestinoId FROM dbo.TransicionEstado;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Solicitud_ObtenerPorId
    @SolicitudId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SolicitudId, s.Folio, s.Solicitante, s.Correo, s.Titulo, s.Descripcion,
           s.TipoSolicitudId,  t.Nombre AS TipoSolicitud,
           s.PrioridadId, p.Nombre NombrePrioridad,
           s.EstadoId, es.Nombre NombreSolicitudEstado ,
           s.ResponsableId, r.Nombre NombreResponsable ,
           s.ComentarioResolucion, s.FechaCreacion, s.FechaActualizacion
    FROM dbo.Solicitud s
        INNER JOIN dbo.TipoSolicitud t ON t.TipoSolicitudId = s.TipoSolicitudId
        INNER JOIN dbo.Prioridad p ON p.PrioridadId = s.PrioridadId
        INNER JOIN dbo.EstadoSolicitud es ON es.EstadoId = s.EstadoId
        LEFT JOIN dbo.Responsable r ON r.ResponsableId = s.ResponsableId
    WHERE s.SolicitudId = @SolicitudId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialSolicitud_Listar
    @SolicitudId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT h.HistorialId,
           h.Fecha,
           h.TipoAccionId,
           ta.Nombre Accion,
           ea.Nombre EstadoAnterior,
           en.Nombre EstadoNuevo,
           ra.Nombre ResponsableAnterior,
           rn.Nombre ResponsableNuevo,
           h.Detalle
    FROM dbo.HistorialSolicitud h
        INNER JOIN dbo.TipoAccion ta ON ta.TipoAccionId = h.TipoAccionId
        LEFT JOIN dbo.EstadoSolicitud ea ON ea.EstadoId = h.EstadoAnteriorId
        LEFT JOIN dbo.EstadoSolicitud en ON en.EstadoId = h.EstadoNuevoId
        LEFT JOIN dbo.Responsable ra ON ra.ResponsableId = h.ResponsableAnteriorId
        LEFT JOIN dbo.Responsable rn ON rn.ResponsableId = h.ResponsableNuevoId
    WHERE h.SolicitudId = @SolicitudId
    ORDER BY h.Fecha ASC, h.HistorialId ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Solicitud_Crear
    @Solicitante     NVARCHAR(150),
    @Correo          NVARCHAR(254),
    @TipoSolicitudId TINYINT,
    @Titulo          NVARCHAR(150),
    @Descripcion     NVARCHAR(4000),
    @PrioridadId     TINYINT = 2,
    @ResponsableId   INT     = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Solicitante IS NULL OR LEN(LTRIM(RTRIM(@Solicitante))) = 0
        THROW 50400, N'El solicitante es obligatorio.', 1;

    IF @Correo IS NULL OR LEN(LTRIM(RTRIM(@Correo))) = 0
        THROW 50400, N'El correo es obligatorio.', 2;

    IF @Titulo IS NULL OR LEN(LTRIM(RTRIM(@Titulo))) = 0
        THROW 50400, N'El título es obligatorio.', 3;

    IF @Descripcion IS NULL OR LEN(LTRIM(RTRIM(@Descripcion))) = 0
        THROW 50400, N'La descripción es obligatoria.', 4;

    IF @TipoSolicitudId IS NULL
        THROW 50400, N'El tipo de solicitud es obligatorio.', 5;

    IF NOT EXISTS (SELECT 1 FROM dbo.TipoSolicitud WHERE TipoSolicitudId = @TipoSolicitudId)
        THROW 50422, N'El tipo de solicitud no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Prioridad WHERE PrioridadId = @PrioridadId)
        THROW 50422, N'La prioridad no existe.', 2;

    DECLARE @Ahora DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @Folio VARCHAR(20) = CONCAT('SOL-', YEAR(@Ahora), '-', FORMAT(NEXT VALUE FOR dbo.SeqFolioSolicitud, 'D6'));
    DECLARE @SolicitudId INT;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Solicitud (Folio, Solicitante, Correo, TipoSolicitudId, Titulo, Descripcion, PrioridadId, ResponsableId, EstadoId)
    VALUES (@Folio, @Solicitante, @Correo, @TipoSolicitudId, @Titulo, @Descripcion, @PrioridadId, @ResponsableId, 1);

    SET @SolicitudId = SCOPE_IDENTITY();

    INSERT INTO dbo.HistorialSolicitud (SolicitudId, TipoAccionId, EstadoNuevoId, Detalle)
    VALUES (@SolicitudId, 1, 1, CONCAT(N'Solicitud', @Folio, N' registrada'));

    COMMIT TRANSACTION;

    EXEC dbo.sp_Solicitud_ObtenerPorId @SolicitudId = @SolicitudId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Solicitud_AsignarResponsable
    @SolicitudId   INT,
    @ResponsableId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoId TINYINT, @EsFinal BIT, @ResponsableAnteriorId INT;
    DECLARE @NombreAnterior NVARCHAR(100), @NombreNuevo NVARCHAR(100);

    BEGIN TRANSACTION;

    SELECT @EstadoId = s.EstadoId,
           @EsFinal = e.EsFinal,
           @ResponsableAnteriorId = s.ResponsableId
    FROM dbo.Solicitud s WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.EstadoSolicitud e ON e.EstadoId = s.EstadoId
    WHERE s.SolicitudId = @SolicitudId;

    IF @EstadoId IS NULL
        THROW 50404, N'La solicitud no existe.', 1;

    IF @EsFinal = 1
        THROW 50409, N'No se puede reasignar una solicitud cerrada o cancelada.', 1;

    SELECT @NombreNuevo = Nombre FROM dbo.Responsable WHERE ResponsableId = @ResponsableId;

    IF @NombreNuevo IS NULL
        THROW 50422, N'El responsable no existe.', 1;

    IF @ResponsableId = @ResponsableAnteriorId
        THROW 50409, N'La solicitud ya está asignada a ese responsable.', 2;

    SELECT @NombreAnterior = Nombre FROM dbo.Responsable WHERE ResponsableId = @ResponsableAnteriorId;

    UPDATE dbo.Solicitud
    SET ResponsableId = @ResponsableId,
        FechaActualizacion = SYSUTCDATETIME()
    WHERE SolicitudId = @SolicitudId;

    INSERT INTO dbo.HistorialSolicitud (SolicitudId, TipoAccionId, ResponsableAnteriorId, ResponsableNuevoId, Detalle)
    VALUES (@SolicitudId, 2, @ResponsableAnteriorId, @ResponsableId,
            CASE WHEN @NombreAnterior IS NULL
                 THEN CONCAT(N'Asignada a ', @NombreNuevo, N'.')
                 ELSE CONCAT(N'Reasignada de ', @NombreAnterior, N' a ', @NombreNuevo, N'.')
            END);

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Solicitud_CambiarEstado
    @SolicitudId   INT,
    @EstadoNuevoId TINYINT,
    @Comentario    NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActualId TINYINT, @ResponsableId INT;
    DECLARE @NombreActual NVARCHAR(30), @NombreNuevo NVARCHAR(30);

    SELECT @NombreNuevo = Nombre FROM dbo.EstadoSolicitud WHERE EstadoId = @EstadoNuevoId;

    IF @NombreNuevo IS NULL
        THROW 50400, N'El estado indicado no existe.', 1;

    BEGIN TRANSACTION;

    SELECT @EstadoActualId = s.EstadoId,
           @NombreActual = e.Nombre,
           @ResponsableId = s.ResponsableId
    FROM dbo.Solicitud s WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.EstadoSolicitud e ON e.EstadoId = s.EstadoId
    WHERE s.SolicitudId = @SolicitudId;

    IF @EstadoActualId IS NULL
        THROW 50404, N'La solicitud no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.TransicionEstado
                   WHERE EstadoOrigenId = @EstadoActualId AND EstadoDestinoId = @EstadoNuevoId)
        THROW 50409, N'Transición de estado no permitida.', 1;

    IF @EstadoNuevoId = 2 AND @ResponsableId IS NULL
        THROW 50422, N'Para pasar a En proceso se requiere un responsable asignado.', 1;

    IF @EstadoNuevoId = 3 AND (@Comentario IS NULL OR LEN(LTRIM(RTRIM(@Comentario))) = 0)
        THROW 50422, N'Para pasar a Resuelta se requiere un comentario de resolución.', 2;

    UPDATE dbo.Solicitud
    SET EstadoId = @EstadoNuevoId,
        ComentarioResolucion = CASE WHEN @EstadoNuevoId = 3 THEN @Comentario ELSE ComentarioResolucion END,
        FechaActualizacion = SYSUTCDATETIME()
    WHERE SolicitudId = @SolicitudId;

    INSERT INTO dbo.HistorialSolicitud (SolicitudId, TipoAccionId, EstadoAnteriorId, EstadoNuevoId, Detalle)
    VALUES (@SolicitudId,
            CASE WHEN @EstadoNuevoId = 3 THEN 4 ELSE 3 END,
            @EstadoActualId,
            @EstadoNuevoId,
            CONCAT(N'Estado cambiado de ', @NombreActual, N' a ', @NombreNuevo, N'.',
                   CASE WHEN @Comentario IS NOT NULL THEN CONCAT(N' Comentario: ', @Comentario) END));

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Solicitud_Listar
    @EstadoId TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SolicitudId,
           s.Folio,
           s.Titulo,
           s.Solicitante,
           s.PrioridadId,   p.Nombre NombrePrioridad ,
           s.ResponsableId, r.Nombre NombreResponsable ,
           s.EstadoId,      es.Nombre NombreSolicitudEstado ,
           s.FechaCreacion
    FROM dbo.Solicitud s
        INNER JOIN Prioridad p ON p.PrioridadId = s.PrioridadId
        INNER JOIN EstadoSolicitud es ON es.EstadoId = s.EstadoId
        LEFT JOIN Responsable r ON r.ResponsableId = s.ResponsableId
    WHERE (@EstadoId IS NULL OR s.EstadoId = @EstadoId)
    ORDER BY s.FechaCreacion DESC, s.SolicitudId DESC;
END;
GO