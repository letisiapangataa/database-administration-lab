-- =============================================
-- SQL Server Disaster Recovery Testing Script
-- Purpose: Simulate outage scenarios and test recovery procedures
-- =============================================

USE [master]
GO

-- =============================================
-- DISASTER RECOVERY PROCEDURES
-- =============================================

-- Create procedure for point-in-time recovery
CREATE OR ALTER PROCEDURE sp_PointInTimeRecovery
    @DatabaseName NVARCHAR(128),
    @BackupPath NVARCHAR(500),
    @RestoreToDateTime DATETIME,
    @NewDatabaseName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @RestoreDB NVARCHAR(128)
    DECLARE @FullBackupFile NVARCHAR(500)
    DECLARE @DiffBackupFile NVARCHAR(500)
    DECLARE @LogBackupPath NVARCHAR(500)
    DECLARE @SQL NVARCHAR(MAX)
    
    -- Set restore database name
    SET @RestoreDB = ISNULL(@NewDatabaseName, @DatabaseName + '_RESTORE_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss'))
    
    BEGIN TRY
        PRINT 'Starting point-in-time recovery for database: ' + @DatabaseName
        PRINT 'Restore target time: ' + CONVERT(VARCHAR, @RestoreToDateTime)
        PRINT 'Restore database name: ' + @RestoreDB
        
        -- Find the most recent full backup before the restore point
        DECLARE @FullBackupDate DATETIME
        SELECT TOP 1 @FullBackupDate = backup_finish_date,
                     @FullBackupFile = physical_device_name
        FROM msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
        WHERE bs.database_name = @DatabaseName
            AND bs.type = 'D'  -- Full backup
            AND bs.backup_finish_date <= @RestoreToDateTime
        ORDER BY bs.backup_finish_date DESC
        
        IF @FullBackupFile IS NULL
        BEGIN
            RAISERROR('No full backup found before the specified restore point', 16, 1)
            RETURN
        END
        
        PRINT 'Using full backup: ' + @FullBackupFile + ' (Completed: ' + CONVERT(VARCHAR, @FullBackupDate) + ')'
        
        -- Restore full backup with NORECOVERY
        SET @SQL = 'RESTORE DATABASE [' + @RestoreDB + '] FROM DISK = ''' + @FullBackupFile + ''' 
                    WITH NORECOVERY, REPLACE, STATS = 10'
        
        PRINT 'Executing: ' + @SQL
        EXEC sp_executesql @SQL
        
        -- Find and restore the most recent differential backup
        SELECT TOP 1 @DiffBackupFile = physical_device_name
        FROM msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
        WHERE bs.database_name = @DatabaseName
            AND bs.type = 'I'  -- Differential backup
            AND bs.backup_finish_date > @FullBackupDate
            AND bs.backup_finish_date <= @RestoreToDateTime
        ORDER BY bs.backup_finish_date DESC
        
        IF @DiffBackupFile IS NOT NULL
        BEGIN
            PRINT 'Restoring differential backup: ' + @DiffBackupFile
            
            SET @SQL = 'RESTORE DATABASE [' + @RestoreDB + '] FROM DISK = ''' + @DiffBackupFile + ''' 
                        WITH NORECOVERY, STATS = 10'
            
            EXEC sp_executesql @SQL
        END
        
        -- Restore transaction log backups up to the specified point in time
        DECLARE log_cursor CURSOR FOR
        SELECT physical_device_name, backup_finish_date
        FROM msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
        WHERE bs.database_name = @DatabaseName
            AND bs.type = 'L'  -- Log backup
            AND bs.backup_finish_date > ISNULL(@DiffBackupFile, @FullBackupDate)
            AND bs.backup_start_date <= @RestoreToDateTime
        ORDER BY bs.backup_finish_date
        
        DECLARE @LogFile NVARCHAR(500), @LogDate DATETIME
        OPEN log_cursor
        FETCH NEXT FROM log_cursor INTO @LogFile, @LogDate
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT 'Restoring log backup: ' + @LogFile
            
            IF @LogDate >= @RestoreToDateTime
            BEGIN
                -- Last log backup - restore to specific point in time
                SET @SQL = 'RESTORE LOG [' + @RestoreDB + '] FROM DISK = ''' + @LogFile + ''' 
                            WITH STOPAT = ''' + CONVERT(VARCHAR, @RestoreToDateTime, 120) + ''', STATS = 10'
            END
            ELSE
            BEGIN
                -- Intermediate log backup - restore completely
                SET @SQL = 'RESTORE LOG [' + @RestoreDB + '] FROM DISK = ''' + @LogFile + ''' 
                            WITH NORECOVERY, STATS = 10'
            END
            
            EXEC sp_executesql @SQL
            FETCH NEXT FROM log_cursor INTO @LogFile, @LogDate
        END
        
        CLOSE log_cursor
        DEALLOCATE log_cursor
        
        -- Bring database online if not already done by STOPAT
        IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @RestoreDB AND state = 0)
        BEGIN
            SET @SQL = 'RESTORE DATABASE [' + @RestoreDB + '] WITH RECOVERY'
            EXEC sp_executesql @SQL
        END
        
        PRINT 'Point-in-time recovery completed successfully'
        PRINT 'Restored database: ' + @RestoreDB
        
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('global','log_cursor') >= -1
        BEGIN
            CLOSE log_cursor
            DEALLOCATE log_cursor
        END
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- =============================================
-- DISASTER SIMULATION PROCEDURES
-- =============================================

-- Create procedure to simulate corruption
CREATE OR ALTER PROCEDURE sp_SimulateCorruption
    @DatabaseName NVARCHAR(128),
    @SimulationType VARCHAR(50) = 'PAGE' -- Options: PAGE, INDEX, DATA
AS
BEGIN
    SET NOCOUNT ON
    
    PRINT 'DISASTER SIMULATION - ' + @SimulationType + ' corruption in database: ' + @DatabaseName
    PRINT 'WARNING: This is for testing purposes only!'
    
    -- This is a simulation - in reality, you would use DBCC commands to check for corruption
    -- and potentially tools like DBCC WRITEPAGE (not recommended for production)
    
    IF @SimulationType = 'PAGE'
    BEGIN
        PRINT 'Simulating page corruption...'
        PRINT 'In a real scenario, this would corrupt specific database pages'
        PRINT 'Use: DBCC CHECKDB(''' + @DatabaseName + ''') to detect corruption'
    END
    ELSE IF @SimulationType = 'INDEX'
    BEGIN
        PRINT 'Simulating index corruption...'
        PRINT 'In a real scenario, this would corrupt index structures'
        PRINT 'Use: DBCC CHECKTABLE with appropriate table names'
    END
    ELSE IF @SimulationType = 'DATA'
    BEGIN
        PRINT 'Simulating data corruption...'
        PRINT 'In a real scenario, this would corrupt table data'
        PRINT 'Use: DBCC CHECKDB(''' + @DatabaseName + ''') WITH DATA_PURITY'
    END
    
    PRINT 'Simulation setup complete. Run integrity checks to detect issues.'
END
GO

-- =============================================
-- INTEGRITY CHECK PROCEDURES
-- =============================================

-- Create comprehensive database integrity check procedure
CREATE OR ALTER PROCEDURE sp_DatabaseIntegrityCheck
    @DatabaseName NVARCHAR(128),
    @FixErrors BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @CheckResults TABLE (
        Error INT,
        Level INT,
        State INT,
        MessageText NVARCHAR(4000),
        RepairLevel NVARCHAR(50),
        Status INT,
        DbId INT,
        DbFragId INT,
        ObjectId INT,
        IndexId INT,
        PartitionId BIGINT,
        AllocUnitId BIGINT,
        RidDbId INT,
        RidPruId INT,
        File INT,
        Page INT,
        Slot INT,
        RefDbId INT,
        RefPruId INT,
        RefFile INT,
        RefPage INT,
        RefSlot INT,
        Allocation INT
    )
    
    PRINT 'Starting integrity check for database: ' + @DatabaseName
    PRINT 'Check started at: ' + CONVERT(VARCHAR, GETDATE())
    
    -- Run DBCC CHECKDB
    IF @FixErrors = 1
    BEGIN
        PRINT 'Running DBCC CHECKDB with REPAIR_ALLOW_DATA_LOSS option'
        SET @SQL = 'DBCC CHECKDB(''' + @DatabaseName + ''') WITH REPAIR_ALLOW_DATA_LOSS, NO_INFOMSGS'
    END
    ELSE
    BEGIN
        PRINT 'Running DBCC CHECKDB (read-only check)'
        SET @SQL = 'DBCC CHECKDB(''' + @DatabaseName + ''') WITH NO_INFOMSGS, TABLERESULTS'
    END
    
    -- Insert results into temp table for analysis
    INSERT INTO @CheckResults
    EXEC sp_executesql @SQL
    
    -- Analyze results
    DECLARE @ErrorCount INT = (SELECT COUNT(*) FROM @CheckResults WHERE Error <> 0)
    
    IF @ErrorCount = 0
    BEGIN
        PRINT 'SUCCESS: No integrity errors found'
    END
    ELSE
    BEGIN
        PRINT 'WARNING: ' + CAST(@ErrorCount AS VARCHAR) + ' integrity errors found'
        
        -- Display error summary
        SELECT 
            Error,
            Level,
            State,
            MessageText,
            RepairLevel
        FROM @CheckResults
        WHERE Error <> 0
        ORDER BY Error, Level
    END
    
    PRINT 'Integrity check completed at: ' + CONVERT(VARCHAR, GETDATE())
END
GO

-- =============================================
-- DISASTER RECOVERY TESTING WORKFLOW
-- =============================================

-- Create main disaster recovery test procedure
CREATE OR ALTER PROCEDURE sp_DisasterRecoveryTest
    @DatabaseName NVARCHAR(128) = 'CompanyDB',
    @BackupPath NVARCHAR(500) = 'C:\DatabaseBackups\',
    @TestType VARCHAR(50) = 'FULL' -- Options: FULL, CORRUPTION, HARDWARE_FAILURE
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @TestStartTime DATETIME = GETDATE()
    DECLARE @TestDB NVARCHAR(128) = @DatabaseName + '_DR_TEST_' + FORMAT(@TestStartTime, 'yyyyMMdd_HHmmss')
    
    PRINT '========================================='
    PRINT 'DISASTER RECOVERY TEST STARTED'
    PRINT 'Test Type: ' + @TestType
    PRINT 'Source Database: ' + @DatabaseName
    PRINT 'Test Database: ' + @TestDB
    PRINT 'Start Time: ' + CONVERT(VARCHAR, @TestStartTime)
    PRINT '========================================='
    
    BEGIN TRY
        -- Step 1: Pre-test backup
        PRINT 'Step 1: Creating pre-test backup...'
        EXEC sp_ExecuteBackupStrategy @DatabaseName, @BackupPath, 'FULL'
        
        -- Step 2: Simulate disaster based on test type
        PRINT 'Step 2: Simulating disaster scenario...'
        
        IF @TestType = 'CORRUPTION'
        BEGIN
            EXEC sp_SimulateCorruption @DatabaseName, 'PAGE'
        END
        ELSE IF @TestType = 'HARDWARE_FAILURE'
        BEGIN
            PRINT 'Simulating hardware failure scenario...'
            PRINT 'In real scenario: Server/storage failure, network outage, etc.'
        END
        
        -- Step 3: Perform recovery test
        PRINT 'Step 3: Testing recovery procedures...'
        
        -- Test point-in-time recovery to 1 hour ago
        DECLARE @RecoveryPoint DATETIME = DATEADD(HOUR, -1, GETDATE())
        EXEC sp_PointInTimeRecovery @DatabaseName, @BackupPath, @RecoveryPoint, @TestDB
        
        -- Step 4: Validate recovered database
        PRINT 'Step 4: Validating recovered database...'
        EXEC sp_DatabaseIntegrityCheck @TestDB
        
        -- Step 5: Performance validation
        PRINT 'Step 5: Testing basic functionality...'
        DECLARE @TestSQL NVARCHAR(MAX) = 'USE [' + @TestDB + ']; SELECT COUNT(*) as RecordCount FROM sys.tables'
        EXEC sp_executesql @TestSQL
        
        -- Step 6: Cleanup test database
        PRINT 'Step 6: Cleaning up test database...'
        SET @TestSQL = 'DROP DATABASE [' + @TestDB + ']'
        EXEC sp_executesql @TestSQL
        
        DECLARE @TestEndTime DATETIME = GETDATE()
        DECLARE @TestDuration INT = DATEDIFF(MINUTE, @TestStartTime, @TestEndTime)
        
        PRINT '========================================='
        PRINT 'DISASTER RECOVERY TEST COMPLETED SUCCESSFULLY'
        PRINT 'End Time: ' + CONVERT(VARCHAR, @TestEndTime)
        PRINT 'Total Duration: ' + CAST(@TestDuration AS VARCHAR) + ' minutes'
        PRINT 'Recovery Time Objective (RTO): ' + CAST(@TestDuration AS VARCHAR) + ' minutes'
        PRINT '========================================='
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        
        -- Cleanup on error
        IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @TestDB)
        BEGIN
            DECLARE @CleanupSQL NVARCHAR(MAX) = 'DROP DATABASE [' + @TestDB + ']'
            EXEC sp_executesql @CleanupSQL
        END
        
        PRINT '========================================='
        PRINT 'DISASTER RECOVERY TEST FAILED'
        PRINT 'Error: ' + @ErrorMessage
        PRINT '========================================='
        
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- Create disaster recovery documentation procedure
CREATE OR ALTER PROCEDURE sp_GenerateDRDocumentation
AS
BEGIN
    SET NOCOUNT ON
    
    PRINT '========================================='
    PRINT 'DISASTER RECOVERY DOCUMENTATION'
    PRINT 'Generated on: ' + CONVERT(VARCHAR, GETDATE())
    PRINT '========================================='
    
    -- Database configuration
    PRINT ''
    PRINT '1. DATABASE CONFIGURATION:'
    SELECT 
        name AS DatabaseName,
        recovery_model_desc AS RecoveryModel,
        state_desc AS State,
        create_date AS CreatedDate
    FROM sys.databases
    WHERE database_id > 4  -- Exclude system databases
    
    -- Backup history
    PRINT ''
    PRINT '2. RECENT BACKUP HISTORY:'
    SELECT TOP 10
        database_name,
        type AS BackupType,
        backup_start_date,
        backup_finish_date,
        DATEDIFF(MINUTE, backup_start_date, backup_finish_date) AS DurationMinutes,
        backup_size / 1024 / 1024 AS SizeMB
    FROM msdb.dbo.backupset
    WHERE database_name NOT IN ('master', 'model', 'msdb', 'tempdb')
    ORDER BY backup_start_date DESC
    
    -- Recovery procedures
    PRINT ''
    PRINT '3. AVAILABLE RECOVERY PROCEDURES:'
    PRINT '   - sp_PointInTimeRecovery: Restore database to specific point in time'
    PRINT '   - sp_DatabaseIntegrityCheck: Check and repair database corruption'
    PRINT '   - sp_DisasterRecoveryTest: Comprehensive DR testing'
    PRINT '   - sp_ExecuteBackupStrategy: Automated backup execution'
    
    PRINT ''
    PRINT '4. EMERGENCY CONTACTS:'
    PRINT '   - Database Administrator: [Contact Information]'
    PRINT '   - System Administrator: [Contact Information]'
    PRINT '   - Emergency Escalation: [Contact Information]'
    
    PRINT ''
    PRINT '5. RECOVERY TIME OBJECTIVES:'
    PRINT '   - Maximum acceptable downtime (RTO): 4 hours'
    PRINT '   - Maximum acceptable data loss (RPO): 15 minutes'
    
    PRINT '========================================='
END
GO

PRINT 'Disaster recovery procedures created successfully'
PRINT 'Test with: EXEC sp_DisasterRecoveryTest ''CompanyDB'', ''C:\DatabaseBackups\'', ''FULL'''
GO
