-- =============================================
-- SQL Server Role-Based Access Control Script
-- Purpose: Implement least privilege principle with custom roles
-- =============================================

USE [master]
GO

-- Create custom database roles for specific access levels
CREATE DATABASE [CompanyDB]
GO

USE [CompanyDB]
GO

-- Create custom roles
CREATE ROLE [db_read_only_users]
CREATE ROLE [db_app_users]
CREATE ROLE [db_report_users]
CREATE ROLE [db_backup_operators]
GO

-- Grant permissions to roles
-- Read-only role permissions
GRANT SELECT ON SCHEMA::dbo TO [db_read_only_users]

-- Application user role permissions  
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [db_app_users]
GRANT EXECUTE ON SCHEMA::dbo TO [db_app_users]

-- Report user role permissions
GRANT SELECT ON SCHEMA::dbo TO [db_report_users]
GRANT VIEW DEFINITION ON SCHEMA::dbo TO [db_report_users]

-- Backup operator role permissions
GRANT BACKUP DATABASE TO [db_backup_operators]
GRANT BACKUP LOG TO [db_backup_operators]
GRANT RESTORE TO [db_backup_operators]

-- Create sample users and assign to roles
CREATE USER [app_service_user] WITHOUT LOGIN
CREATE USER [report_user] WITHOUT LOGIN  
CREATE USER [backup_user] WITHOUT LOGIN
CREATE USER [readonly_user] WITHOUT LOGIN

-- Add users to appropriate roles
ALTER ROLE [db_app_users] ADD MEMBER [app_service_user]
ALTER ROLE [db_report_users] ADD MEMBER [report_user]
ALTER ROLE [db_backup_operators] ADD MEMBER [backup_user]
ALTER ROLE [db_read_only_users] ADD MEMBER [readonly_user]

-- Remove public permissions for security
REVOKE ALL ON SCHEMA::dbo FROM [public]

PRINT 'Role-based access control configured successfully'
GO
