-- =============================================
-- SQL Server Automated Backup Solution
-- Purpose: Full, Differential, and Log backup automation
-- =============================================

USE [master]
GO

-- Variables for backup configuration
DECLARE @BackupPath NVARCHAR(500) = 'C:\DatabaseBackups\'
DECLARE @DatabaseName NVARCHAR(128) = 'CompanyDB'
DECLARE @BackupFileName NVARCHAR(500)
DECLARE @BackupDescription NVARCHAR(255)
DECLARE @CompressionOption BIT = 1

-- Create backup directory if it doesn't exist (requires xp_cmdshell enabled)
EXEC xp_cmdshell 'mkdir C:\DatabaseBackups', NO_OUTPUT

-- =============================================
-- FULL BACKUP PROCEDURE
-- =============================================
CREATE OR ALTER PROCEDURE sp_PerformFullBackup
    @DatabaseName NVARCHAR(128),
    @BackupPath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @BackupFileName NVARCHAR(500)
    DECLARE @BackupDescription NVARCHAR(255)
    DECLARE @CurrentDateTime NVARCHAR(20)
    
    -- Generate timestamp for filename
    SET @CurrentDateTime = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')
    SET @BackupFileName = @BackupPath + @DatabaseName + '_FULL_' + @CurrentDateTime + '.bak'
    SET @BackupDescription = 'Full backup of ' + @DatabaseName + ' database on ' + CONVERT(VARCHAR, GETDATE())
    
    -- Perform full backup
    BACKUP DATABASE @DatabaseName 
    TO DISK = @BackupFileName
    WITH 
        DESCRIPTION = @BackupDescription,
        COMPRESSION,
        CHECKSUM,
        VERIFY,
        STATS = 10
    
    PRINT 'Full backup completed: ' + @BackupFileName
END
GO

-- =============================================
-- DIFFERENTIAL BACKUP PROCEDURE
-- =============================================
CREATE OR ALTER PROCEDURE sp_PerformDifferentialBackup
    @DatabaseName NVARCHAR(128),
    @BackupPath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @BackupFileName NVARCHAR(500)
    DECLARE @BackupDescription NVARCHAR(255)
    DECLARE @CurrentDateTime NVARCHAR(20)
    
    -- Generate timestamp for filename
    SET @CurrentDateTime = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')
    SET @BackupFileName = @BackupPath + @DatabaseName + '_DIFF_' + @CurrentDateTime + '.bak'
    SET @BackupDescription = 'Differential backup of ' + @DatabaseName + ' database on ' + CONVERT(VARCHAR, GETDATE())
    
    -- Perform differential backup
    BACKUP DATABASE @DatabaseName 
    TO DISK = @BackupFileName
    WITH 
        DIFFERENTIAL,
        DESCRIPTION = @BackupDescription,
        COMPRESSION,
        CHECKSUM,
        VERIFY,
        STATS = 10
    
    PRINT 'Differential backup completed: ' + @BackupFileName
END
GO

-- =============================================
-- TRANSACTION LOG BACKUP PROCEDURE
-- =============================================
CREATE OR ALTER PROCEDURE sp_PerformLogBackup
    @DatabaseName NVARCHAR(128),
    @BackupPath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @BackupFileName NVARCHAR(500)
    DECLARE @BackupDescription NVARCHAR(255)
    DECLARE @CurrentDateTime NVARCHAR(20)
    
    -- Generate timestamp for filename
    SET @CurrentDateTime = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')
    SET @BackupFileName = @BackupPath + @DatabaseName + '_LOG_' + @CurrentDateTime + '.trn'
    SET @BackupDescription = 'Transaction log backup of ' + @DatabaseName + ' database on ' + CONVERT(VARCHAR, GETDATE())
    
    -- Perform log backup
    BACKUP LOG @DatabaseName 
    TO DISK = @BackupFileName
    WITH 
        DESCRIPTION = @BackupDescription,
        COMPRESSION,
        CHECKSUM,
        VERIFY,
        STATS = 10
    
    PRINT 'Log backup completed: ' + @BackupFileName
END
GO

-- =============================================
-- BACKUP CLEANUP PROCEDURE
-- =============================================
CREATE OR ALTER PROCEDURE sp_CleanupOldBackups
    @BackupPath NVARCHAR(500),
    @RetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @CleanupCommand NVARCHAR(1000)
    
    -- Remove backup files older than retention period
    SET @CleanupCommand = 'forfiles /p "' + @BackupPath + '" /s /m *.bak /d -' + CAST(@RetentionDays AS VARCHAR) + ' /c "cmd /c del @path"'
    EXEC xp_cmdshell @CleanupCommand, NO_OUTPUT
    
    SET @CleanupCommand = 'forfiles /p "' + @BackupPath + '" /s /m *.trn /d -' + CAST(@RetentionDays AS VARCHAR) + ' /c "cmd /c del @path"'
    EXEC xp_cmdshell @CleanupCommand, NO_OUTPUT
    
    PRINT 'Cleanup completed for files older than ' + CAST(@RetentionDays AS VARCHAR) + ' days'
END
GO

-- =============================================
-- MAIN BACKUP ORCHESTRATION PROCEDURE
-- =============================================
CREATE OR ALTER PROCEDURE sp_ExecuteBackupStrategy
    @DatabaseName NVARCHAR(128) = 'CompanyDB',
    @BackupPath NVARCHAR(500) = 'C:\DatabaseBackups\',
    @BackupType VARCHAR(20) = 'FULL' -- Options: FULL, DIFF, LOG
AS
BEGIN
    SET NOCOUNT ON
    
    BEGIN TRY
        IF @BackupType = 'FULL'
            EXEC sp_PerformFullBackup @DatabaseName, @BackupPath
        ELSE IF @BackupType = 'DIFF'
            EXEC sp_PerformDifferentialBackup @DatabaseName, @BackupPath
        ELSE IF @BackupType = 'LOG'
            EXEC sp_PerformLogBackup @DatabaseName, @BackupPath
        ELSE
            RAISERROR('Invalid backup type specified. Use FULL, DIFF, or LOG', 16, 1)
            
        -- Cleanup old backups (keep 30 days)
        EXEC sp_CleanupOldBackups @BackupPath, 30
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000)
        SET @ErrorMessage = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- Test the backup procedures
PRINT 'Backup procedures created successfully'
PRINT 'Execute: EXEC sp_ExecuteBackupStrategy ''CompanyDB'', ''C:\DatabaseBackups\'', ''FULL'''
GO
