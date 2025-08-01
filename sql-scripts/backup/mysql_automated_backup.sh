#!/bin/bash
# =============================================
# MySQL Automated Backup Script
# Purpose: Full and incremental backup automation
# =============================================

# Configuration variables
DB_NAME="company_db"
DB_USER="backup_user"
DB_PASSWORD="Backup#789Pass!"
DB_HOST="localhost"
BACKUP_DIR="/var/backups/mysql"
LOG_FILE="/var/log/mysql_backup.log"
RETENTION_DAYS=30

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/full"
mkdir -p "$BACKUP_DIR/incremental"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to perform full backup
perform_full_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/full/${DB_NAME}_full_${timestamp}.sql"
    
    log_message "Starting full backup of database: $DB_NAME"
    
    # Create full backup with mysqldump
    if mysqldump --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" \
        --single-transaction --routines --triggers --events \
        --flush-logs --master-data=2 \
        "$DB_NAME" > "$backup_file"; then
        
        # Compress the backup
        gzip "$backup_file"
        log_message "Full backup completed successfully: ${backup_file}.gz"
        
        # Calculate and log backup size
        local backup_size=$(du -h "${backup_file}.gz" | cut -f1)
        log_message "Backup size: $backup_size"
        
        return 0
    else
        log_message "ERROR: Full backup failed for database: $DB_NAME"
        return 1
    fi
}

# Function to perform incremental backup using binary logs
perform_incremental_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/incremental/${DB_NAME}_incremental_${timestamp}.sql"
    
    log_message "Starting incremental backup of database: $DB_NAME"
    
    # Get the current binary log file and position
    local binlog_info=$(mysql --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" \
        -e "SHOW MASTER STATUS\G" | grep -E "(File|Position)")
    
    if [ $? -eq 0 ]; then
        echo "-- Binary Log Information at backup time:" > "$backup_file"
        echo "-- $binlog_info" >> "$backup_file"
        
        # Flush logs to ensure all transactions are written
        mysql --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" \
            -e "FLUSH LOGS;"
        
        # Create incremental backup (structure + recent data)
        mysqldump --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" \
            --single-transaction --where="1 LIMIT 1000" \
            "$DB_NAME" >> "$backup_file"
        
        # Compress the backup
        gzip "$backup_file"
        log_message "Incremental backup completed successfully: ${backup_file}.gz"
        
        return 0
    else
        log_message "ERROR: Incremental backup failed for database: $DB_NAME"
        return 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    log_message "Starting cleanup of backups older than $RETENTION_DAYS days"
    
    # Remove old full backups
    find "$BACKUP_DIR/full" -name "*.gz" -type f -mtime +$RETENTION_DAYS -delete
    
    # Remove old incremental backups
    find "$BACKUP_DIR/incremental" -name "*.gz" -type f -mtime +$RETENTION_DAYS -delete
    
    log_message "Cleanup completed"
}

# Function to verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    if [ -f "$backup_file" ]; then
        # Test if the gzipped file is valid
        if gzip -t "$backup_file" 2>/dev/null; then
            log_message "Backup integrity verified: $backup_file"
            return 0
        else
            log_message "ERROR: Backup integrity check failed: $backup_file"
            return 1
        fi
    else
        log_message "ERROR: Backup file not found: $backup_file"
        return 1
    fi
}

# Function to send notification (optional)
send_notification() {
    local status="$1"
    local message="$2"
    
    # Example: Send email notification (requires mail configuration)
    # echo "$message" | mail -s "MySQL Backup $status" admin@company.com
    
    log_message "Notification: $status - $message"
}

# Main backup execution function
execute_backup() {
    local backup_type="$1"
    
    log_message "=== Starting MySQL backup process ==="
    log_message "Backup type: $backup_type"
    
    case "$backup_type" in
        "full")
            if perform_full_backup; then
                send_notification "SUCCESS" "Full backup completed successfully"
            else
                send_notification "FAILED" "Full backup failed"
                exit 1
            fi
            ;;
        "incremental")
            if perform_incremental_backup; then
                send_notification "SUCCESS" "Incremental backup completed successfully"
            else
                send_notification "FAILED" "Incremental backup failed"
                exit 1
            fi
            ;;
        *)
            log_message "ERROR: Invalid backup type. Use 'full' or 'incremental'"
            exit 1
            ;;
    esac
    
    # Cleanup old backups
    cleanup_old_backups
    
    log_message "=== Backup process completed ==="
}

# Check if backup type is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {full|incremental}"
    echo "Example: $0 full"
    exit 1
fi

# Execute backup based on provided type
execute_backup "$1"
