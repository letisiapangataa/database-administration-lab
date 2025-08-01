# 📚 Database Administration Lab - User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Security Implementation](#security-implementation)
4. [Backup Automation](#backup-automation)
5. [Performance Optimization](#performance-optimization)
6. [Disaster Recovery](#disaster-recovery)
7. [Troubleshooting](#troubleshooting)

---

## Introduction

This lab environment provides hands-on experience with database administration practices for both SQL Server and MySQL. It covers essential DBA tasks including security hardening, backup automation, performance tuning, and disaster recovery testing.

### Prerequisites
- SQL Server 2019+ or MySQL 8.0+
- Administrative access to database servers
- Basic understanding of SQL and database concepts
- PowerShell (for SQL Server scripts) or Bash (for MySQL scripts)

---

## Getting Started

### SQL Server Setup

1. **Database Creation**
   ```sql
   -- Run the following to create the sample database
   sqlcmd -S localhost -i sql-scripts\security\sqlserver_role_based_access.sql
   ```

2. **Enable Required Features**
   ```sql
   -- Enable xp_cmdshell for backup automation
   sp_configure 'show advanced options', 1;
   RECONFIGURE;
   sp_configure 'xp_cmdshell', 1;
   RECONFIGURE;
   ```

### MySQL Setup

1. **Database Creation**
   ```bash
   # Run the security hardening script
   mysql -u root -p < sql-scripts/security/mysql_security_hardening.sql
   ```

2. **Configure Binary Logging**
   ```bash
   # Add to my.cnf and restart MySQL
   log_bin = /var/log/mysql/mysql-bin.log
   binlog_format = ROW
   ```

---

## Security Implementation

### Role-Based Access Control

#### SQL Server
- **Custom Roles Created:**
  - `db_read_only_users`: SELECT permissions only
  - `db_app_users`: CRUD operations for applications
  - `db_report_users`: SELECT + VIEW DEFINITION for reporting
  - `db_backup_operators`: Backup and restore permissions

#### MySQL
- **Custom Roles Created:**
  - `read_only_role`: SELECT permissions only
  - `app_user_role`: CRUD operations for applications
  - `report_user_role`: SELECT + SHOW VIEW for reporting
  - `backup_operator_role`: Backup-related permissions

### User Auditing

#### SQL Server
- Server-level audit for login tracking
- Database-level audit for DML operations
- Audit files stored in `C:\AuditLogs\`

#### MySQL
- General query log for basic auditing
- Performance schema for detailed monitoring
- Binary logs for change tracking

### Security Best Practices Implemented

1. **Password Policies**
   - Minimum 12 characters
   - Mixed case, numbers, and special characters required
   - Regular password rotation enforced

2. **Network Security**
   - Disabled unnecessary protocols
   - Restricted bind addresses
   - Firewall rules configured

3. **Privilege Management**
   - Least privilege principle enforced
   - Regular access reviews scheduled
   - Temporary access procedures documented

---

## Backup Automation

### SQL Server Backup Strategy

#### Backup Types
- **Full Backup**: Complete database backup (weekly)
- **Differential Backup**: Changes since last full backup (daily)
- **Transaction Log Backup**: Log file backup (every 15 minutes)

#### Automated Execution
```sql
-- Schedule full backup
EXEC sp_ExecuteBackupStrategy 'CompanyDB', 'C:\DatabaseBackups\', 'FULL'

-- Schedule differential backup
EXEC sp_ExecuteBackupStrategy 'CompanyDB', 'C:\DatabaseBackups\', 'DIFF'

-- Schedule log backup
EXEC sp_ExecuteBackupStrategy 'CompanyDB', 'C:\DatabaseBackups\', 'LOG'
```

#### SQL Agent Jobs
1. **Full Backup Job**: Weekly on Sunday 2:00 AM
2. **Differential Backup Job**: Daily at 2:00 AM (except Sunday)
3. **Log Backup Job**: Every 15 minutes during business hours

### MySQL Backup Strategy

#### Backup Types
- **Full Backup**: Complete database dump (daily)
- **Incremental Backup**: Binary log-based incremental (hourly)

#### Automated Execution
```bash
# Full backup
./sql-scripts/backup/mysql_automated_backup.sh full

# Incremental backup
./sql-scripts/backup/mysql_automated_backup.sh incremental
```

#### Cron Jobs
```bash
# Add to crontab
0 2 * * * /path/to/mysql_automated_backup.sh full
0 */1 * * * /path/to/mysql_automated_backup.sh incremental
```

### Backup Validation

#### Verification Steps
1. **Integrity Checks**: CHECKSUM verification during backup
2. **Restore Testing**: Automated restore to test environment
3. **Size Monitoring**: Track backup sizes for anomalies
4. **Retention Management**: Automated cleanup of old backups

---

## Performance Optimization

### SQL Server Optimization

#### Index Analysis
```sql
-- Find missing indexes
EXEC sp_FindMissingIndexes

-- Find unused indexes
EXEC sp_FindUnusedIndexes

-- Performance report
EXEC sp_DatabasePerformanceReport
```

#### Query Optimization
```sql
-- Find top resource-consuming queries
EXEC sp_FindTopResourceQueries 20

-- Example optimized stored procedure
EXEC sp_OptimizedCustomerSearch 
    @CustomerName = 'John', 
    @City = 'New York'
```

### MySQL Optimization

#### Index Analysis
```sql
-- Find unused indexes
CALL sp_find_unused_indexes();

-- Analyze table statistics
CALL sp_analyze_table_stats();

-- Find duplicate indexes
CALL sp_find_duplicate_indexes();
```

#### Performance Monitoring
```sql
-- Find slow queries
CALL sp_find_slow_queries();

-- Monitor table I/O
CALL sp_monitor_table_io();

-- Check for full table scans
CALL sp_find_full_table_scans();
```

### Performance Tuning Checklist

#### SQL Server
- [ ] Configure memory settings appropriately
- [ ] Set MAXDOP based on CPU cores
- [ ] Enable optimize for ad hoc workloads
- [ ] Configure TempDB properly
- [ ] Monitor wait statistics
- [ ] Update statistics regularly

#### MySQL
- [ ] Configure InnoDB buffer pool size
- [ ] Set appropriate connection limits
- [ ] Enable slow query log
- [ ] Configure query cache (MySQL 5.7)
- [ ] Monitor Performance Schema
- [ ] Optimize my.cnf settings

---

## Disaster Recovery

### Recovery Planning

#### Recovery Objectives
- **RTO (Recovery Time Objective)**: 4 hours
- **RPO (Recovery Point Objective)**: 15 minutes for SQL Server, 5 minutes for MySQL

#### Recovery Scenarios
1. **Hardware Failure**: Complete server failure
2. **Corruption**: Database file corruption
3. **Human Error**: Accidental data deletion
4. **Natural Disaster**: Site-wide outage

### SQL Server Recovery

#### Point-in-Time Recovery
```sql
-- Restore to specific point in time
EXEC sp_PointInTimeRecovery 
    @DatabaseName = 'CompanyDB',
    @BackupPath = 'C:\DatabaseBackups\',
    @RestoreToDateTime = '2025-01-01 14:30:00',
    @NewDatabaseName = 'CompanyDB_Restored'
```

#### Integrity Checking
```sql
-- Check database integrity
EXEC sp_DatabaseIntegrityCheck 'CompanyDB', 0  -- Read-only check

-- Check and repair (use with caution)
EXEC sp_DatabaseIntegrityCheck 'CompanyDB', 1  -- With repair
```

#### Disaster Recovery Testing
```sql
-- Full DR test
EXEC sp_DisasterRecoveryTest 
    @DatabaseName = 'CompanyDB',
    @BackupPath = 'C:\DatabaseBackups\',
    @TestType = 'FULL'
```

### MySQL Recovery

#### Point-in-Time Recovery
```bash
# Restore to specific point in time
./sql-scripts/disaster-recovery/mysql_disaster_recovery.sh \
    point_in_time_recovery '2025-01-01 14:30:00' restored_db
```

#### Integrity Checking
```bash
# Check database integrity
./sql-scripts/disaster-recovery/mysql_disaster_recovery.sh \
    check_integrity company_db false

# Check and repair
./sql-scripts/disaster-recovery/mysql_disaster_recovery.sh \
    check_integrity company_db true
```

#### Disaster Recovery Testing
```bash
# Full DR test
./sql-scripts/disaster-recovery/mysql_disaster_recovery.sh \
    disaster_recovery_test CORRUPTION
```

### Recovery Documentation

#### Emergency Procedures
1. **Initial Assessment**: Determine scope and cause
2. **Communication**: Notify stakeholders
3. **Recovery Execution**: Follow documented procedures
4. **Validation**: Verify data integrity and functionality
5. **Post-Recovery**: Document lessons learned

---

## Troubleshooting

### Common Issues

#### SQL Server

**Issue**: Backup fails with insufficient disk space
```sql
-- Check disk space
EXEC xp_fixeddrives

-- Solution: Clean up old backups or add storage
EXEC sp_CleanupOldBackups 'C:\DatabaseBackups\', 15  -- Keep 15 days
```

**Issue**: Slow query performance
```sql
-- Check for missing indexes
EXEC sp_FindMissingIndexes

-- Check wait statistics
SELECT TOP 10 * FROM sys.dm_os_wait_stats 
WHERE waiting_tasks_count > 0
ORDER BY wait_time_ms DESC
```

#### MySQL

**Issue**: InnoDB deadlocks
```sql
-- Check deadlock information
SHOW ENGINE INNODB STATUS;

-- Solution: Optimize transaction ordering and duration
```

**Issue**: Slow queries
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;

-- Analyze slow queries
CALL sp_find_slow_queries();
```

### Monitoring Scripts

#### SQL Server Health Check
```sql
-- Quick health check
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    state_desc AS State,
    recovery_model_desc AS RecoveryModel
FROM sys.databases
WHERE database_id > 4
```

#### MySQL Health Check
```sql
-- Quick health check
SELECT 
    SCHEMA_NAME AS DatabaseName,
    DEFAULT_CHARACTER_SET_NAME,
    DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
```

### Performance Monitoring

#### Key Metrics to Monitor
1. **CPU Usage**: Database server CPU utilization
2. **Memory Usage**: Buffer pool hit ratio
3. **Disk I/O**: Read/write latency and throughput
4. **Connection Count**: Active and maximum connections
5. **Query Performance**: Slow query counts and execution times
6. **Lock Waits**: Blocking and deadlock statistics

---

## Next Steps

### Advanced Topics
1. **High Availability**: Set up Always On Availability Groups (SQL Server) or MySQL Group Replication
2. **Replication**: Configure master-slave replication for read scaling
3. **Partitioning**: Implement table partitioning for large datasets
4. **Automation**: Develop PowerShell/Bash scripts for routine tasks
5. **Monitoring**: Integrate with monitoring tools like Nagios or Zabbix

### Certification Paths
- **Microsoft**: MCSA SQL Server, MCSE Data Management and Analytics
- **MySQL**: MySQL DBA Certification
- **Vendor Neutral**: CompTIA Server+

---

## Additional Resources

- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Database Administration Best Practices](https://www.brentozar.com/)
- [Performance Tuning Guides](https://use-the-index-luke.com/)
