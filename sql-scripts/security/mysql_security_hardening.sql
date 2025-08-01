-- =============================================
-- MySQL Security Hardening Script
-- Purpose: Implement security best practices for MySQL
-- =============================================

-- Create database and switch to it
CREATE DATABASE IF NOT EXISTS company_db;
USE company_db;

-- Create custom roles (MySQL 8.0+)
CREATE ROLE IF NOT EXISTS 'read_only_role';
CREATE ROLE IF NOT EXISTS 'app_user_role';
CREATE ROLE IF NOT EXISTS 'report_user_role';
CREATE ROLE IF NOT EXISTS 'backup_operator_role';

-- Grant permissions to roles
-- Read-only role
GRANT SELECT ON company_db.* TO 'read_only_role';

-- Application user role
GRANT SELECT, INSERT, UPDATE, DELETE ON company_db.* TO 'app_user_role';
GRANT EXECUTE ON company_db.* TO 'app_user_role';

-- Report user role
GRANT SELECT ON company_db.* TO 'report_user_role';
GRANT SHOW VIEW ON company_db.* TO 'report_user_role';

-- Backup operator role
GRANT SELECT, LOCK TABLES, SHOW VIEW ON company_db.* TO 'backup_operator_role';
GRANT RELOAD, PROCESS ON *.* TO 'backup_operator_role';

-- Create users with strong passwords
CREATE USER IF NOT EXISTS 'app_service'@'localhost' IDENTIFIED BY 'StrongP@ssw0rd123!';
CREATE USER IF NOT EXISTS 'report_user'@'localhost' IDENTIFIED BY 'Rep0rt@Pass456!';
CREATE USER IF NOT EXISTS 'backup_user'@'localhost' IDENTIFIED BY 'Backup#789Pass!';
CREATE USER IF NOT EXISTS 'readonly_user'@'localhost' IDENTIFIED BY 'ReadOnly$012!';

-- Assign roles to users
GRANT 'app_user_role' TO 'app_service'@'localhost';
GRANT 'report_user_role' TO 'report_user'@'localhost';
GRANT 'backup_operator_role' TO 'backup_user'@'localhost';
GRANT 'read_only_role' TO 'readonly_user'@'localhost';

-- Set default roles for users
ALTER USER 'app_service'@'localhost' DEFAULT ROLE 'app_user_role';
ALTER USER 'report_user'@'localhost' DEFAULT ROLE 'report_user_role';
ALTER USER 'backup_user'@'localhost' DEFAULT ROLE 'backup_operator_role';
ALTER USER 'readonly_user'@'localhost' DEFAULT ROLE 'read_only_role';

-- Remove anonymous users and test database access
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Configure password validation
-- Note: Ensure validate_password plugin is installed
SET GLOBAL validate_password.policy = 'STRONG';
SET GLOBAL validate_password.length = 12;
SET GLOBAL validate_password.mixed_case_count = 1;
SET GLOBAL validate_password.number_count = 1;
SET GLOBAL validate_password.special_char_count = 1;

-- Enable general query log for auditing (optional, can impact performance)
-- SET GLOBAL general_log = 'ON';
-- SET GLOBAL general_log_file = '/var/log/mysql/general.log';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Display security configuration
SELECT 'MySQL Security Hardening Complete' AS Status;
SELECT User, Host, authentication_string FROM mysql.user WHERE User != '';
