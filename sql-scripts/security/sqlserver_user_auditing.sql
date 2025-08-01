-- =============================================
-- SQL Server User Auditing Script
-- Purpose: Enable and configure auditing for user activities
-- =============================================

USE [master]
GO

-- Create Server Audit
CREATE SERVER AUDIT [UserActivity_Audit]
TO FILE 
(   FILEPATH = 'C:\AuditLogs\'
    ,MAXSIZE = 100 MB
    ,MAX_ROLLOVER_FILES = 10
    ,RESERVE_DISK_SPACE = OFF
)
WITH
(   QUEUE_DELAY = 1000
    ,ON_FAILURE = CONTINUE
)
GO

-- Enable the server audit
ALTER SERVER AUDIT [UserActivity_Audit] WITH (STATE = ON)
GO

-- Create Database Audit Specification
USE [CompanyDB]
GO

CREATE DATABASE AUDIT SPECIFICATION [DB_UserActivity_Audit]
FOR SERVER AUDIT [UserActivity_Audit]
ADD (SELECT ON SCHEMA::[dbo] BY [public]),
ADD (INSERT ON SCHEMA::[dbo] BY [public]),
ADD (UPDATE ON SCHEMA::[dbo] BY [public]),
ADD (DELETE ON SCHEMA::[dbo] BY [public]),
ADD (EXECUTE ON SCHEMA::[dbo] BY [public])
WITH (STATE = ON)
GO

-- Create login audit specification
USE [master]
GO

CREATE SERVER AUDIT SPECIFICATION [Login_Audit]
FOR SERVER AUDIT [UserActivity_Audit]
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (LOGOUT_GROUP)
WITH (STATE = ON)
GO

-- Query to view audit logs
/*
SELECT 
    event_time,
    action_id,
    succeeded,
    session_server_principal_name,
    database_name,
    schema_name,
    object_name,
    statement,
    additional_information
FROM sys.fn_get_audit_file('C:\AuditLogs\*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC
*/

PRINT 'User auditing configured successfully'
GO
