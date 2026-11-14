USE msdb;
GO
IF NOT EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name=N'Backup_Biblioteca_FULL')
BEGIN
EXEC dbo.sp_add_job @job_name=N'Backup_Biblioteca_FULL',
@enabled=1, @description=N'Biblioteca - Full semanal con CHECKSUM/VERIFYONLY',
@notify_level_eventlog=2;
EXEC dbo.sp_add_jobstep @job_name=N'Backup_Biblioteca_FULL', @step_name=N'Crear FULL',
@subsystem=N'TSQL', @database_name=N'Biblioteca',
@command=N'EXEC dbo.usp_RealizarBackup @Tipo = ''FULL'';', @on_success_action=1, @on_fail_action=2;
EXEC dbo.sp_add_jobschedule @job_name=N'Backup_Biblioteca_FULL',
@name=N'Horario_Biblioteca_FULL_Domingo_1600',
@freq_type=8, @freq_interval=1, @freq_recurrence_factor=1,
@active_start_time=160000;
EXEC dbo.sp_add_jobserver @job_name=N'Backup_Biblioteca_FULL';
END;
GO
IF NOT EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name=N'Backup_Biblioteca_DIFF')
BEGIN
EXEC dbo.sp_add_job @job_name=N'Backup_Biblioteca_DIFF',
@enabled=1, @description=N'Biblioteca - Diferencial lunes a sabado con verificacion',
@notify_level_eventlog=2;
EXEC dbo.sp_add_jobstep @job_name=N'Backup_Biblioteca_DIFF', @step_name=N'Crear DIFF',
@subsystem=N'TSQL', @database_name=N'Biblioteca',
@command=N'EXEC dbo.usp_RealizarBackup @Tipo = ''DIFF'';', @on_success_action=1, @on_fail_action=2;
EXEC dbo.sp_add_jobschedule @job_name=N'Backup_Biblioteca_DIFF',
@name=N'Horario_Biblioteca_DIFF_LunSab_1600',
@freq_type=8, @freq_interval=126, @freq_recurrence_factor=1,
@active_start_time=160000;
EXEC dbo.sp_add_jobserver @job_name=N'Backup_Biblioteca_DIFF';
END;
GO
IF NOT EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name=N'Backup_Biblioteca_LOG')
BEGIN
EXEC dbo.sp_add_job @job_name=N'Backup_Biblioteca_LOG',
@enabled=1, @description=N'Biblioteca - Backup de transacciones cada 30 minutos',
@notify_level_eventlog=2;
EXEC dbo.sp_add_jobstep @job_name=N'Backup_Biblioteca_LOG', @step_name=N'Crear LOG',
@subsystem=N'TSQL', @database_name=N'Biblioteca',
@command=N'EXEC dbo.usp_RealizarBackup @Tipo = ''LOG'';', @on_success_action=1, @on_fail_action=2;
EXEC dbo.sp_add_jobschedule @job_name=N'Backup_Biblioteca_LOG',
@name=N'Horario_Biblioteca_LOG_30min',
@freq_type=4, @freq_interval=1,
@freq_subday_type=4, @freq_subday_interval=30,
@active_start_time=000000, @active_end_time=233000;
EXEC dbo.sp_add_jobserver @job_name=N'Backup_Biblioteca_LOG';
END;
GO
SELECT j.name AS job, j.enabled,
s.name AS horario, s.freq_type, s.freq_interval,
s.freq_subday_type, s.freq_subday_interval, s.active_start_time
FROM dbo.sysjobs j
JOIN dbo.sysjobschedules js ON js.job_id = j.job_id
JOIN dbo.sysschedules s ON s.schedule_id = js.schedule_id
WHERE j.name LIKE N'Backup_Biblioteca_%'
ORDER BY j.name;
GO

-- EXEC msdb.dbo.sp_start_job @job_name = N'Backup_Biblioteca_LOG';


