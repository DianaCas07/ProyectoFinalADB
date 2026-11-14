ALTER DATABASE Biblioteca SET RECOVERY FULL;
GO
USE Biblioteca;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RealizarBackup
@Tipo VARCHAR(4)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @Carpeta NVARCHAR(4000) = N'/var/opt/mssql/backups/';
DECLARE @Archivo NVARCHAR(4000);
DECLARE @Estampa NVARCHAR(40) = CONVERT(VARCHAR(8), GETDATE(), 112) + N'_'
+ REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), N':', N'')
+ N'_' + LEFT(CONVERT(VARCHAR(36), NEWID()), 8);
IF @Tipo NOT IN ('FULL', 'DIFF', 'LOG')
THROW 50002, 'Tipo invalido. Usar FULL, DIFF o LOG.', 1;
SET @Archivo = @Carpeta + @Tipo + N'_' + @Estampa
+ CASE WHEN @Tipo = 'LOG' THEN N'.trn' ELSE N'.bak' END;
BEGIN TRY
IF @Tipo = 'FULL'
BACKUP DATABASE Biblioteca TO DISK = @Archivo
WITH INIT, CHECKSUM, STATS = 10;
ELSE IF @Tipo = 'DIFF'
BACKUP DATABASE Biblioteca TO DISK = @Archivo
WITH DIFFERENTIAL, INIT, CHECKSUM, STATS = 10;
ELSE
BACKUP LOG Biblioteca TO DISK = @Archivo
WITH INIT, CHECKSUM, STATS = 10;

RESTORE VERIFYONLY FROM DISK = @Archivo WITH CHECKSUM;
PRINT N'Respaldo y verificacion completados: ' + @Archivo;
END TRY
BEGIN CATCH
PRINT N'ERROR al respaldar Biblioteca: ' + ERROR_MESSAGE();
THROW; 
END CATCH
END;
GO

EXEC dbo.usp_RealizarBackup @Tipo = 'FULL';
GO
EXEC dbo.usp_RealizarBackup @Tipo = 'DIFF';
GO
EXEC dbo.usp_RealizarBackup @Tipo = 'LOG';
GO