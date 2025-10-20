/* =========================================================
   DB: Progra3_TPFinal_19B_DB  (SQL Server)
   Esquema: Call Center (Usuarios, Clientes, Incidencias)
   Con PasswordHash en dbo.Users (SHA-256)
   ========================================================= */

-- Crear DB (opcional)
IF DB_ID('Progra3_TPFinal_19B_DB') IS NULL
    CREATE DATABASE Progra3_TPFinal_19B_DB;
GO
USE Progra3_TPFinal_19B_DB;
GO

/* =================== Limpieza previa (idempotente) =================== */
IF OBJECT_ID('dbo.IncidentStateHistory','U') IS NOT NULL DROP TABLE dbo.IncidentStateHistory;
IF OBJECT_ID('dbo.IncidentAssignments','U')   IS NOT NULL DROP TABLE dbo.IncidentAssignments;
IF OBJECT_ID('dbo.IncidentComments','U')      IS NOT NULL DROP TABLE dbo.IncidentComments;
IF OBJECT_ID('dbo.Incidents','U')             IS NOT NULL DROP TABLE dbo.Incidents;
IF OBJECT_ID('dbo.Priorities','U')            IS NOT NULL DROP TABLE dbo.Priorities;
IF OBJECT_ID('dbo.IncidentTypes','U')         IS NOT NULL DROP TABLE dbo.IncidentTypes;
IF OBJECT_ID('dbo.Customers','U')             IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Users','U')                 IS NOT NULL DROP TABLE dbo.Users;
GO

/* =================== Tablas =================== */

-- Usuarios
CREATE TABLE dbo.Users (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Users_Id DEFAULT (NEWID()),
    Username          NVARCHAR(100)    NOT NULL,
    FullName          NVARCHAR(200)    NOT NULL,
    Role              NVARCHAR(20)     NOT NULL, -- Administrador | Telefonista | Supervisor
    PasswordHash      VARBINARY(64)    NOT NULL, -- SHA-256
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_Users_IsDeleted DEFAULT (0),
    CONSTRAINT PK_Users PRIMARY KEY (Id),
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT CK_Users_Role CHECK (Role IN (N'Administrador', N'Telefonista', N'Supervisor'))
);
-- self-FK del creador
ALTER TABLE dbo.Users
  ADD CONSTRAINT FK_Users_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(Id);
GO

-- Clientes
CREATE TABLE dbo.Customers (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Customers_Id DEFAULT (NEWID()),
    DocumentNumber    NVARCHAR(50)     NOT NULL,
    Name              NVARCHAR(200)    NOT NULL,
    Email             NVARCHAR(200)    NOT NULL,
    Phone             NVARCHAR(50)     NULL,
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_Customers_IsDeleted DEFAULT (0),
    CONSTRAINT PK_Customers PRIMARY KEY (Id),
    CONSTRAINT UQ_Customers_Document UNIQUE (DocumentNumber),
    CONSTRAINT FK_Customers_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(Id)
);
GO

-- Tipos de Incidencia
CREATE TABLE dbo.IncidentTypes (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_IncidentTypes_Id DEFAULT (NEWID()),
    Name              NVARCHAR(100)    NOT NULL,
    Description       NVARCHAR(500)    NULL,
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_IncidentTypes_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_IncidentTypes_IsDeleted DEFAULT (0),
    CONSTRAINT PK_IncidentTypes PRIMARY KEY (Id),
    CONSTRAINT UQ_IncidentTypes_Name UNIQUE (Name),
    CONSTRAINT FK_IncidentTypes_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(Id)
);
GO

-- Prioridades
CREATE TABLE dbo.Priorities (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Priorities_Id DEFAULT (NEWID()),
    Name              NVARCHAR(50)     NOT NULL,  -- Alta / Media / Baja
    Weight            INT              NOT NULL,  -- 3/2/1
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_Priorities_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_Priorities_IsDeleted DEFAULT (0),
    CONSTRAINT PK_Priorities PRIMARY KEY (Id),
    CONSTRAINT UQ_Priorities_Name UNIQUE (Name),
    CONSTRAINT FK_Priorities_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(Id)
);
GO

-- Incidencias
CREATE TABLE dbo.Incidents (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Incidents_Id DEFAULT (NEWID()),
    Number            NVARCHAR(30)     NOT NULL, -- INC-YYYY-#####
    CustomerId        UNIQUEIDENTIFIER NOT NULL,
    TypeId            UNIQUEIDENTIFIER NOT NULL,
    PriorityId        UNIQUEIDENTIFIER NOT NULL,
    Problem           NVARCHAR(2000)   NOT NULL,
    State             NVARCHAR(20)     NOT NULL, -- Abierto | Asignado | EnAnalisis | Resuelto | Cerrado | Reabierto
    OwnerUserId       UNIQUEIDENTIFIER NOT NULL,
    AssignedToUserId  UNIQUEIDENTIFIER NOT NULL,
    ResolutionNote    NVARCHAR(2000)   NULL,
    CloseComment      NVARCHAR(2000)   NULL,
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_Incidents_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_Incidents_IsDeleted DEFAULT (0),
    CONSTRAINT PK_Incidents PRIMARY KEY (Id),
    CONSTRAINT UQ_Incidents_Number UNIQUE (Number),
    CONSTRAINT CK_Incidents_State CHECK (State IN (N'Abierto',N'Asignado',N'EnAnalisis',N'Resuelto',N'Cerrado',N'Reabierto')),
    CONSTRAINT FK_Incidents_Customer  FOREIGN KEY (CustomerId)       REFERENCES dbo.Customers(Id),
    CONSTRAINT FK_Incidents_Type      FOREIGN KEY (TypeId)           REFERENCES dbo.IncidentTypes(Id),
    CONSTRAINT FK_Incidents_Priority  FOREIGN KEY (PriorityId)       REFERENCES dbo.Priorities(Id),
    CONSTRAINT FK_Incidents_Assignee  FOREIGN KEY (AssignedToUserId) REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Incidents_Owner     FOREIGN KEY (OwnerUserId)      REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Incidents_CreatedBy FOREIGN KEY (CreatedByUserId)  REFERENCES dbo.Users(Id)
);
CREATE INDEX IX_Incidents_State      ON dbo.Incidents(State);
CREATE INDEX IX_Incidents_PriorityId ON dbo.Incidents(PriorityId);
CREATE INDEX IX_Incidents_AssignedTo ON dbo.Incidents(AssignedToUserId);
CREATE INDEX IX_Incidents_CreatedAt  ON dbo.Incidents(CreatedAt);
GO

-- Comentarios
CREATE TABLE dbo.IncidentComments (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_IncidentComments_Id DEFAULT (NEWID()),
    IncidentId        UNIQUEIDENTIFIER NOT NULL,
    AuthorUserId      UNIQUEIDENTIFIER NOT NULL,
    Text              NVARCHAR(2000)   NOT NULL,
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_IncidentComments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_IncidentComments_IsDeleted DEFAULT (0),
    CONSTRAINT PK_IncidentComments PRIMARY KEY (Id),
    CONSTRAINT FK_IncidentComments_Incident  FOREIGN KEY (IncidentId)     REFERENCES dbo.Incidents(Id),
    CONSTRAINT FK_IncidentComments_Author    FOREIGN KEY (AuthorUserId)   REFERENCES dbo.Users(Id),
    CONSTRAINT FK_IncidentComments_CreatedBy FOREIGN KEY (CreatedByUserId)REFERENCES dbo.Users(Id)
);
CREATE INDEX IX_IncidentComments_Inc_Created ON dbo.IncidentComments(IncidentId, CreatedAt);
GO

-- Asignaciones
CREATE TABLE dbo.IncidentAssignments (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_IncidentAssignments_Id DEFAULT (NEWID()),
    IncidentId        UNIQUEIDENTIFIER NOT NULL,
    AssignedByUserId  UNIQUEIDENTIFIER NOT NULL,
    AssignedToUserId  UNIQUEIDENTIFIER NOT NULL,
    Note              NVARCHAR(1000)   NULL,
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_IncidentAssignments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_IncidentAssignments_IsDeleted DEFAULT (0),
    CONSTRAINT PK_IncidentAssignments PRIMARY KEY (Id),
    CONSTRAINT FK_Assignments_Incident    FOREIGN KEY (IncidentId)       REFERENCES dbo.Incidents(Id),
    CONSTRAINT FK_Assignments_AssignedBy  FOREIGN KEY (AssignedByUserId) REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Assignments_AssignedTo  FOREIGN KEY (AssignedToUserId) REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Assignments_CreatedBy   FOREIGN KEY (CreatedByUserId)  REFERENCES dbo.Users(Id)
);
CREATE INDEX IX_IncidentAssignments_Inc_Created ON dbo.IncidentAssignments(IncidentId, CreatedAt);
GO

-- Historial de estados
CREATE TABLE dbo.IncidentStateHistory (
    Id                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_IncidentStateHistory_Id DEFAULT (NEWID()),
    IncidentId        UNIQUEIDENTIFIER NOT NULL,
    State             NVARCHAR(20)     NOT NULL, -- mismos valores que Incidents.State
    ActorUserId       UNIQUEIDENTIFIER NOT NULL,
    Note              NVARCHAR(1000)   NULL,
    CreatedAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_IncidentStateHistory_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    UpdatedAt         DATETIME2(0)     NULL,
    UpdatedByUserId   UNIQUEIDENTIFIER NULL,
    IsDeleted         BIT              NOT NULL CONSTRAINT DF_IncidentStateHistory_IsDeleted DEFAULT (0),
    CONSTRAINT PK_IncidentStateHistory PRIMARY KEY (Id),
    CONSTRAINT CK_StateHistory_State CHECK (State IN (N'Abierto',N'Asignado',N'EnAnalisis',N'Resuelto',N'Cerrado',N'Reabierto')),
    CONSTRAINT FK_StateHistory_Incident  FOREIGN KEY (IncidentId)   REFERENCES dbo.Incidents(Id),
    CONSTRAINT FK_StateHistory_Actor     FOREIGN KEY (ActorUserId)  REFERENCES dbo.Users(Id),
    CONSTRAINT FK_StateHistory_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users(Id)
);
CREATE INDEX IX_IncidentStateHistory_Inc_Created ON dbo.IncidentStateHistory(IncidentId, CreatedAt);
GO

/* =================== Seeds (con PasswordHash) =================== */

-- GUIDs fijos
DECLARE @admin  UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @superv UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @tel1   UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @tel2   UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';

-- 1) Insertar admin primero (self-FK CreatedByUserId = su propio Id)
INSERT INTO dbo.Users (Id, Username, FullName, Role, PasswordHash, CreatedAt, CreatedByUserId, IsDeleted)
VALUES
(@admin , N'admin', N'Administrador del Sistema', N'Administrador',
 HASHBYTES('SHA2_256', N'Admin123$'), SYSUTCDATETIME(), @admin, 0);

-- 2) Resto de usuarios
INSERT INTO dbo.Users (Id, Username, FullName, Role, PasswordHash, CreatedAt, CreatedByUserId, IsDeleted)
VALUES
(@superv, N'supervisor', N'Supervisor General', N'Supervisor',
 HASHBYTES('SHA2_256', N'Supervisor123$'), SYSUTCDATETIME(), @admin, 0),
(@tel1  , N'tel1', N'Telefonista 1', N'Telefonista',
 HASHBYTES('SHA2_256', N'Tel1_123$'), SYSUTCDATETIME(), @admin, 0),
(@tel2  , N'tel2', N'Telefonista 2', N'Telefonista',
 HASHBYTES('SHA2_256', N'Tel2_123$'), SYSUTCDATETIME(), @admin, 0);

-- Clientes
DECLARE @c1 UNIQUEIDENTIFIER = NEWID();
DECLARE @c2 UNIQUEIDENTIFIER = NEWID();
DECLARE @c3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Customers (Id, DocumentNumber, Name, Email, Phone, CreatedByUserId)
VALUES
(@c1, N'30-70901234-9', N'Acme S.A.',      N'contacto@acme.com',    N'11-4000-1000', @admin),
(@c2, N'30-65439876-5', N'Globex SRL',     N'soporte@globex.com',   N'11-4555-2222', @admin),
(@c3, N'20-28765432-1', N'Juan Pérez',     N'juan.perez@email.com', N'11-4777-3333', @admin);

-- Catálogos
DECLARE @tSoporte UNIQUEIDENTIFIER = NEWID();
DECLARE @tAdmin   UNIQUEIDENTIFIER = NEWID();
DECLARE @tCom     UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.IncidentTypes (Id, Name, Description, CreatedByUserId)
VALUES
(@tSoporte, N'Soporte',       N'Incidencias técnicas',   @admin),
(@tAdmin,   N'Administrativo',N'Trámites y cuentas',     @admin),
(@tCom,     N'Comercial',     N'Ventas y cotizaciones',  @admin);

DECLARE @pAlta UNIQUEIDENTIFIER = NEWID();
DECLARE @pMedia UNIQUEIDENTIFIER = NEWID();
DECLARE @pBaja UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Priorities (Id, Name, Weight, CreatedByUserId)
VALUES
(@pAlta,  N'Alta',  3, @admin),
(@pMedia, N'Media', 2, @admin),
(@pBaja,  N'Baja',  1, @admin);

-- Incidencias
DECLARE @i1 UNIQUEIDENTIFIER = NEWID();
DECLARE @i2 UNIQUEIDENTIFIER = NEWID();
DECLARE @i3 UNIQUEIDENTIFIER = NEWID();
DECLARE @i4 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.Incidents (Id, Number, CustomerId, TypeId, PriorityId, Problem, State, OwnerUserId, AssignedToUserId, CreatedAt, CreatedByUserId)
VALUES
(@i1, N'INC-2025-0001', @c1, @tSoporte, @pAlta , N'No puede ingresar al sistema.',              N'Abierto'  , @tel1, @tel1, DATEADD(DAY,-2,SYSUTCDATETIME()), @tel1),
(@i2, N'INC-2025-0002', @c2, @tAdmin,   @pMedia, N'Error en la facturación mensual.',           N'Asignado' , @tel1, @tel2, DATEADD(DAY,-3,SYSUTCDATETIME()), @tel1),
(@i3, N'INC-2025-0003', @c1, @tSoporte, @pAlta , N'Reporte mensual se cierra inesperadamente.', N'Resuelto' , @tel1, @tel1, DATEADD(DAY,-4,SYSUTCDATETIME()), @tel1),
(@i4, N'INC-2025-0004', @c3, @tCom,     @pBaja , N'Consulta por plan corporativo.',             N'Cerrado'  , @tel2, @tel2, DATEADD(DAY,-10,SYSUTCDATETIME()), @tel2);

UPDATE dbo.Incidents SET ResolutionNote = N'Se reinició IIS y se corrigieron permisos.', UpdatedAt=SYSUTCDATETIME(), UpdatedByUserId=@tel1 WHERE Id=@i3;
UPDATE dbo.Incidents SET CloseComment  = N'Cierre por falta de respuesta del cliente.',  UpdatedAt=SYSUTCDATETIME(), UpdatedByUserId=@tel2 WHERE Id=@i4;

-- Historial de estados
INSERT INTO dbo.IncidentStateHistory (IncidentId, State, ActorUserId, Note, CreatedAt, CreatedByUserId)
VALUES
(@i1, N'Abierto',    @tel1,  N'Incidente creado por telefonista.',           DATEADD(DAY,-2,SYSUTCDATETIME()), @tel1),

(@i2, N'Abierto',    @tel1,  N'Incidente creado.',                           DATEADD(DAY,-3,SYSUTCDATETIME()), @tel1),
(@i2, N'Asignado',   @superv,N'Reasignado a Telefonista 2.',                  DATEADD(DAY,-2,SYSUTCDATETIME()), @superv),

(@i3, N'Abierto',    @tel1,  N'Incidente creado.',                           DATEADD(DAY,-4,SYSUTCDATETIME()), @tel1),
(@i3, N'EnAnalisis', @tel1,  N'Se reproduce el error y se investiga.',        DATEADD(DAY,-4,SYSUTCDATETIME()), @tel1),
(@i3, N'Resuelto',   @tel1,  N'Solución aplicada y validada.',                DATEADD(DAY,-3,SYSUTCDATETIME()), @tel1),

(@i4, N'Abierto',    @tel2,  N'Incidente creado.',                           DATEADD(DAY,-10,SYSUTCDATETIME()), @tel2),
(@i4, N'EnAnalisis', @tel2,  N'Se solicitó información adicional.',           DATEADD(DAY,-9,SYSUTCDATETIME()),  @tel2),
(@i4, N'Cerrado',    @tel2,  N'Cierre por inactividad del cliente.',          DATEADD(DAY,-7,SYSUTCDATETIME()),  @tel2);

-- Asignaciones
INSERT INTO dbo.IncidentAssignments (IncidentId, AssignedByUserId, AssignedToUserId, Note, CreatedAt, CreatedByUserId)
VALUES
(@i1, @tel1,  @tel1,  N'Asignación inicial al creador.',      DATEADD(DAY,-2,SYSUTCDATETIME()), @tel1),
(@i2, @tel1,  @tel1,  N'Asignación inicial al creador.',      DATEADD(DAY,-3,SYSUTCDATETIME()), @tel1),
(@i2, @superv,@tel2,  N'Reasignación por carga de trabajo.',  DATEADD(DAY,-2,SYSUTCDATETIME()), @superv),
(@i3, @tel1,  @tel1,  N'Asignación inicial al creador.',      DATEADD(DAY,-4,SYSUTCDATETIME()), @tel1),
(@i4, @tel2,  @tel2,  N'Asignación inicial al creador.',      DATEADD(DAY,-10,SYSUTCDATETIME()), @tel2);

-- Comentarios
INSERT INTO dbo.IncidentComments (IncidentId, AuthorUserId, Text, CreatedAt, CreatedByUserId)
VALUES
(@i1, @tel1,  N'Se solicitó reset de contraseña al cliente.', DATEADD(DAY,-2,SYSUTCDATETIME()), @tel1),

(@i2, @tel1,  N'Validando comprobantes adjuntos.',            DATEADD(DAY,-3,SYSUTCDATETIME()), @tel1),
(@i2, @superv,N'Se reasigna a Tel2 por especialidad.',        DATEADD(DAY,-2,SYSUTCDATETIME()), @superv),

(@i3, @tel1,  N'Se aplicó hotfix en servidor de reportes.',   DATEADD(DAY,-3,SYSUTCDATETIME()), @tel1),

(@i4, @tel2,  N'Se intenta contactar sin respuesta.',         DATEADD(DAY,-8,SYSUTCDATETIME()), @tel2);
GO

/* =================== Verificación rápida =================== */
-- SELECT Username, Role FROM dbo.Users;
-- SELECT * FROM dbo.Customers;
-- SELECT * FROM dbo.IncidentTypes;
-- SELECT * FROM dbo.Priorities;
-- SELECT Number, State, ResolutionNote, CloseComment FROM dbo.Incidents;
-- SELECT * FROM dbo.IncidentStateHistory ORDER BY CreatedAt;
-- SELECT * FROM dbo.IncidentAssignments ORDER BY CreatedAt;
-- SELECT * FROM dbo.IncidentComments ORDER BY CreatedAt;

/* Credenciales demo (hash SHA-256):
   admin / Admin123$
   supervisor / Supervisor123$
   tel1 / Tel1_123$
   tel2 / Tel2_123$
*/
