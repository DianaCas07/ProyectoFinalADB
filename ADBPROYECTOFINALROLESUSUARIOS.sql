use master;
go

--Poner en modo parcial la base de datos
alter database Biblioteca set containment = partial;

--CREANDO USUARIOS
Use biblioteca;
GO

create user ING_JAMES with password = 'Admin123!';
create user USUARIO_Inventario_Lector with password = 'Admin123!';
create user USUARIO_Catalogo_Lector with password = 'Admin123!';
create user USUARIO_Analista_Total with password = 'Admin123!';
create user USUARIO_RRHH with password = 'Admin123!';
create user USUARIO_Circulacion with password = 'Admin123!';
create user USUARIO_Finanzas with password = 'Admin123!';
create user USUARIO_Auditor with password = 'Admin123!';
create user USUARIO_Backer with password = 'Admin123!';
create user USUARIO_GestorBiblioteca with password = 'Admin123!';
create user USUARIO_AuditorBiblioteca with password = 'Admin123!';
create user USUARIO_Recepcionista with password = 'Admin123!';
create user Dueno_catalogo with password = 'Admin123!';
create user Dueno_inventario with password = 'Admin123!';
create user Dueno_personas with password = 'Admin123!';
create user Dueno_circulacion with password = 'Admin123!';
create user Dueno_finanzas with password = 'Admin123!';
GO


--CREANDO ESQUEMAS
CREATE SCHEMA catalogo   AUTHORIZATION Dueno_catalogo;  -- autores, editoriales, categorias, libros, libro_autor
GO
CREATE SCHEMA inventario AUTHORIZATION Dueno_inventario;  -- ejemplares físicos
GO
CREATE SCHEMA personas   AUTHORIZATION Dueno_personas;  -- socios, empleados (datos personales)
GO
CREATE SCHEMA circulacion AUTHORIZATION Dueno_circulacion; -- prestamos, devoluciones
GO
CREATE SCHEMA finanzas   AUTHORIZATION Dueno_finanzas;  -- multas
GO

Select name as esquema, user_name(principal_id) propiertario
from sys.schemas;

--CREANDO ROLES
create role	Rol_ADB_CATEDRATICO;
create role	Rol_Lector_Inventario;
create role	Rol_Lector_Catalogo;
create role	Rol_Analista_Biblioteca;
create role	Rol_Recursos_Humanos;
create role	Rol_circulacion_trans;
create role	Rol_finanzas_trans;
create role	Rol_Backup_Manager;
create role	Rol_Gestor_Cata_Inv;
create role	Rol_Auditor_Biblioteca;
create role	Rol_Recepcion;
create role	Rol_dueno_catalogo;
create role	Rol_dueno_inventario;
create role	Rol_dueno_personas;
create role	Rol_dueno_circulacion;
create role	Rol_dueno_finanzas;


--ASIGNANDO ROLES
alter role	Rol_ADB_CATEDRATICO	add member	ING_JAMES;
alter role	Rol_Lector_Inventario	add member	USUARIO_Inventario_Lector;
alter role	Rol_Lector_Catalogo	add member	USUARIO_Catalogo_Lector;
alter role	Rol_Analista_Biblioteca	add member	USUARIO_Analista_Total;
alter role	Rol_Recursos_Humanos	add member	USUARIO_RRHH;
alter role	Rol_circulacion_trans	add member	USUARIO_Circulacion;
alter role	Rol_finanzas_trans	add member	USUARIO_Finanzas;
alter role	Rol_Backup_Manager	add member	USUARIO_Backer;
alter role	Rol_Gestor_Cata_Inv	add member	USUARIO_GestorBiblioteca;
alter role	Rol_Auditor_Biblioteca	add member	USUARIO_AuditorBiblioteca;
alter role	Rol_Recepcion	add member	USUARIO_Recepcionista;
alter role	Rol_dueno_catalogo	add member	Dueno_catalogo;
alter role	Rol_dueno_inventario	add member	Dueno_inventario;
alter role	Rol_dueno_personas	add member	Dueno_personas;
alter role	Rol_dueno_circulacion	add member	Dueno_circulacion;
alter role	Rol_dueno_finanzas	add member	Dueno_finanzas;

--ASIGNANDO PERMISOS A ROLES 

-- ING_JAMES -> Rol_ADB_CATEDRATICO | TODOS | SELECT
GRANT SELECT ON SCHEMA::catalogo     TO Rol_ADB_CATEDRATICO;
GRANT SELECT ON SCHEMA::inventario   TO Rol_ADB_CATEDRATICO;
GRANT SELECT ON SCHEMA::personas     TO Rol_ADB_CATEDRATICO;
GRANT SELECT ON SCHEMA::circulacion  TO Rol_ADB_CATEDRATICO;
GRANT SELECT ON SCHEMA::finanzas     TO Rol_ADB_CATEDRATICO;

-- USUARIO_Inventario_Lector -> Rol_Lector_Inventario | Inventario | SELECT
GRANT SELECT ON SCHEMA::inventario TO Rol_Lector_Inventario;

-- USUARIO_Catalogo_Lector -> Rol_Lector_Catalogo | Catalogo | SELECT
GRANT SELECT ON SCHEMA::catalogo TO Rol_Lector_Catalogo;

-- USUARIO_Analista_Total -> Rol_Analista_Biblioteca | TODOS | SELECT
GRANT SELECT ON SCHEMA::catalogo     TO Rol_Analista_Biblioteca;
GRANT SELECT ON SCHEMA::inventario   TO Rol_Analista_Biblioteca;
GRANT SELECT ON SCHEMA::personas     TO Rol_Analista_Biblioteca;
GRANT SELECT ON SCHEMA::circulacion  TO Rol_Analista_Biblioteca;
GRANT SELECT ON SCHEMA::finanzas     TO Rol_Analista_Biblioteca;

-- USUARIO_RRHH -> Rol_Recursos_Humanos | Personas | SELECT, INSERT, UPDATE, DELETE
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::personas TO Rol_Recursos_Humanos;

-- USUARIO_Circulacion -> Rol_circulacion_trans | Circulacion | EXEC
GRANT EXECUTE ON SCHEMA::circulacion TO Rol_circulacion_trans;

-- USUARIO_Finanzas -> Rol_finanzas_trans | Finanzas | EXEC
GRANT EXECUTE ON SCHEMA::finanzas TO Rol_finanzas_trans;

-- USUARIO_Backer -> Rol_Backup_Manager | TODOS | SELECT, BACKUP, RESTORE
GRANT SELECT ON SCHEMA::catalogo     TO Rol_Backup_Manager;
GRANT SELECT ON SCHEMA::inventario   TO Rol_Backup_Manager;
GRANT SELECT ON SCHEMA::personas     TO Rol_Backup_Manager;
GRANT SELECT ON SCHEMA::circulacion  TO Rol_Backup_Manager;
GRANT SELECT ON SCHEMA::finanzas     TO Rol_Backup_Manager;
GRANT BACKUP DATABASE TO Rol_Backup_Manager;

-- USUARIO_GestorBiblioteca -> Rol_Gestor_Cata_Inv | Inventario y Catalogo
GRANT INSERT, UPDATE, DELETE ON SCHEMA::inventario TO Rol_Gestor_Cata_Inv;
GRANT INSERT, UPDATE, DELETE ON SCHEMA::catalogo   TO Rol_Gestor_Cata_Inv;

-- USUARIO_AuditorBiblioteca -> Rol_Auditor_Biblioteca | TODOS | SELECT
GRANT SELECT ON SCHEMA::catalogo     TO Rol_Auditor_Biblioteca;
GRANT SELECT ON SCHEMA::inventario   TO Rol_Auditor_Biblioteca;
GRANT SELECT ON SCHEMA::personas     TO Rol_Auditor_Biblioteca;
GRANT SELECT ON SCHEMA::circulacion  TO Rol_Auditor_Biblioteca;
GRANT SELECT ON SCHEMA::finanzas     TO Rol_Auditor_Biblioteca;

-- USUARIO_Recepcionista -> Rol_Recepcion | TODOS | SELECT
GRANT SELECT ON SCHEMA::catalogo     TO Rol_Recepcion;
GRANT SELECT ON SCHEMA::inventario   TO Rol_Recepcion;
GRANT SELECT ON SCHEMA::personas     TO Rol_Recepcion;
GRANT SELECT ON SCHEMA::circulacion  TO Rol_Recepcion;
GRANT SELECT ON SCHEMA::finanzas     TO Rol_Recepcion;
DENY  SELECT ON OBJECT::personas.empleados TO Rol_Recepcion;

--Duenos de esquemas
GRANT ALTER ON SCHEMA::catalogo TO Rol_dueno_catalogo;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO Rol_dueno_catalogo;
-- Inventario
GRANT ALTER ON SCHEMA::inventario TO Rol_dueno_inventario;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO Rol_dueno_inventario;
-- Personas
GRANT ALTER ON SCHEMA::personas TO Rol_dueno_personas;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO Rol_dueno_personas;
-- Circulacion
GRANT ALTER ON SCHEMA::circulacion TO Rol_dueno_circulacion;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO Rol_dueno_circulacion;
-- Finanzas
GRANT ALTER ON SCHEMA::finanzas TO Rol_dueno_finanzas;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO Rol_dueno_finanzas;
GO

--Verificando permisos otorgados por rol
SELECT  pr.name                       AS rol,
        pe.state_desc                 AS estado,
        pe.permission_name            AS permiso,
        pe.class_desc                 AS nivel,
        CASE pe.class
             WHEN 0 THEN DB_NAME()
             WHEN 3 THEN SCHEMA_NAME(pe.major_id)
             WHEN 1 THEN OBJECT_SCHEMA_NAME(pe.major_id) + '.' + OBJECT_NAME(pe.major_id)
        END                           AS objeto
FROM    sys.database_permissions pe
JOIN    sys.database_principals  pr ON pr.principal_id = pe.grantee_principal_id
WHERE   pr.name LIKE 'Rol[_]%'
ORDER BY pr.name, objeto, pe.permission_name;
GO

--NO OLVIDAR CAMBIAR CONTEXTO
--Consultas de ejemplo para probar
-- Recepcionista: puede ver socios, NO empleados
execute as user = 'USUARIO_Recepcionista';
    select * from personas.socios;     
    select * from personas.empleados;   
    delete from personas.socios;        
revert;

-- RRHH: CRUD completo en personas, nada en finanzas
execute as user = 'USUARIO_RRHH';
    select * from personas.empleados;   
    select * from finanzas.multas;      
revert;

-- Gestor: INSERT/UPDATE/DELETE en catalogo e inventario
execute as user = 'USUARIO_GestorBiblioteca';
    select * from catalogo.libros;      
revert;

-- Dueno: puede crear/alterar/eliminar en su esquema, solo en el suyo
execute as user = 'Dueno_catalogo';
    create table catalogo.prueba (id int);   
    drop table catalogo.prueba;              
    create table finanzas.prueba (id int);  
revert;

--Cambiar el contexto temporalmente
--Contexto(usuario y bd)
execute as user = 'nombre_usuario';
--Regresar al contexto original
revert;
GO

execute as user = 'ING_JAMES';
drop database biblioteca;
revert;

--Revisar que usuario esta conectado de momento
SELECT 
    ORIGINAL_LOGIN() AS LoginOriginal,
    SUSER_SNAME() AS ContextoLoginActual,
    USER_NAME() AS UsuarioBaseDatosActual;

--sql agent
USE master;
GO

-- Crear la auditoría de servidor
CREATE SERVER AUDIT AuditoriaBasicaADB
TO FILE ( FILEPATH = '/audit/', MAXSIZE = 100 MB )
WITH ( QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE );
GO

-- Activar la auditoría
ALTER SERVER AUDIT AuditoriaBasicaADB WITH (STATE = ON);
GO

--Revisar si existe
SELECT * FROM sys.server_audits WHERE name = 'AuditoriaBasicaADB';


USE biblioteca;
GO
CREATE DATABASE AUDIT SPECIFICATION AuditoriaBasicaDB
FOR SERVER AUDIT AuditoriaBasicaADB
ADD (SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::catalogo    BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::inventario  BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::personas    BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::circulacion BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::finanzas    BY PUBLIC),
ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = ON);
GO

-- Backup y Restore (eventos de servidor)
USE master;
GO
CREATE SERVER AUDIT SPECIFICATION AuditoriaBackups
FOR SERVER AUDIT AuditoriaBasicaADB
ADD (BACKUP_RESTORE_GROUP)
WITH (STATE = ON);
GO

--CON ESTA REVISAMOS LOS LOGS DEL SISTEMA 
SELECT event_time, server_principal_name, database_principal_name,
       schema_name, object_name, action_id, succeeded, statement
FROM sys.fn_get_audit_file('/audit/*', DEFAULT, DEFAULT)
ORDER BY event_time DESC;


--Extra: para ver los usuario existentes
SELECT 
    name AS NombreUsuario,
    type_desc AS TipoUsuario,
    create_date AS FechaCreacion,
    modify_date AS FechaModificacion
FROM 
    sys.database_principals
WHERE 
    type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP')
ORDER BY 
    name;
