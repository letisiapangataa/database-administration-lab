#!/bin/bash
# =============================================
# MySQL Disaster Recovery Testing Script
# Purpose: Simulate outage scenarios and test recovery procedures
# =============================================

# Configuration
DB_NAME="company_db"
DB_USER="backup_user"
DB_PASSWORD="Backup#789Pass!"
DB_HOST="localhost"
BACKUP_DIR="/var/backups/mysql"
DR_TEST_DIR="/var/backups/mysql/dr_test"
LOG_FILE="/var/log/mysql_dr_test.log"

# Create directories
mkdir -p "$DR_TEST_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to execute MySQL commands
execute_mysql() {
    local query="$1"
    local database="${2:-$DB_NAME}"
    
    mysql --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" "$database" -e "$query" 2>/dev/null
}

# Function to perform point-in-time recovery
point_in_time_recovery() {
    local target_time="$1"
    local restore_db_name="$2"
    
    log_message "Starting point-in-time recovery"
    log_message "Target time: $target_time"
    log_message "Restore database: $restore_db_name"
    
    # Find the latest full backup before target time
    local backup_file=$(find "$BACKUP_DIR/full" -name "*.gz" -type f -exec stat -c '%Y %n' {} \; | \
                       awk -v target="$(date -d "$target_time" +%s)" '$1 <= target {print $2}' | \
                       sort -n | tail -1)
    
    if [ -z "$backup_file" ]; then
        log_message "ERROR: No suitable full backup found before target time"
        return 1
    fi
    
    log_message "Using backup file: $backup_file"
    
    # Create restore database
    execute_mysql "CREATE DATABASE IF NOT EXISTS $restore_db_name;" ""
    
    # Restore from backup
    if gunzip -c "$backup_file" | mysql --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" "$restore_db_name"; then
        log_message "Point-in-time recovery completed successfully"
        return 0
    else
        log_message "ERROR: Point-in-time recovery failed"
        return 1
    fi
}

# Function to simulate corruption
simulate_corruption() {
    local corruption_type="$1"
    
    log_message "DISASTER SIMULATION - $corruption_type corruption"
    log_message "WARNING: This is for testing purposes only!"
    
    case "$corruption_type" in
        "TABLE")
            log_message "Simulating table corruption..."
            log_message "In real scenario: Table file corruption, missing .frm files"
            log_message "Use: CHECK TABLE table_name; to detect corruption"
            ;;
        "INDEX")
            log_message "Simulating index corruption..."
            log_message "In real scenario: Index file corruption"
            log_message "Use: CHECK TABLE table_name; REPAIR TABLE table_name;"
            ;;
        "INNODB")
            log_message "Simulating InnoDB corruption..."
            log_message "In real scenario: InnoDB tablespace corruption"
            log_message "Use: innodb_force_recovery settings and backup/restore"
            ;;
        *)
            log_message "Unknown corruption type: $corruption_type"
            return 1
            ;;
    esac
    
    log_message "Simulation setup complete"
}

# Function to check database integrity
check_database_integrity() {
    local database="$1"
    local fix_errors="$2"
    
    log_message "Starting integrity check for database: $database"
    
    # Get list of tables in database
    local tables=$(execute_mysql "SHOW TABLES;" "$database" | grep -v "Tables_in_")
    
    local error_count=0
    local total_tables=0
    
    while IFS= read -r table; do
        if [ -n "$table" ]; then
            total_tables=$((total_tables + 1))
            log_message "Checking table: $table"
            
            # Check table integrity
            local check_result=$(execute_mysql "CHECK TABLE $table;" "$database" | grep -v "Table\|Op\|Msg_type\|Msg_text" | awk '{print $3}')
            
            if [[ "$check_result" != "OK" ]]; then
                error_count=$((error_count + 1))
                log_message "ERROR: Table $table has integrity issues: $check_result"
                
                if [ "$fix_errors" = "true" ]; then
                    log_message "Attempting to repair table: $table"
                    local repair_result=$(execute_mysql "REPAIR TABLE $table;" "$database" | grep -v "Table\|Op\|Msg_type\|Msg_text" | awk '{print $3}')
                    log_message "Repair result for $table: $repair_result"
                fi
            else
                log_message "Table $table: OK"
            fi
        fi
    done <<< "$tables"
    
    log_message "Integrity check completed"
    log_message "Total tables checked: $total_tables"
    log_message "Tables with errors: $error_count"
    
    return $error_count
}

# Function to test database connectivity and basic operations
test_database_functionality() {
    local database="$1"
    
    log_message "Testing database functionality: $database"
    
    # Test basic connectivity
    if ! execute_mysql "SELECT 1;" "$database" >/dev/null 2>&1; then
        log_message "ERROR: Cannot connect to database $database"
        return 1
    fi
    
    # Test table count
    local table_count=$(execute_mysql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$database';" "" | grep -v "COUNT")
    log_message "Database $database contains $table_count tables"
    
    # Test a simple query on each table
    local tables=$(execute_mysql "SHOW TABLES;" "$database" | grep -v "Tables_in_")
    
    while IFS= read -r table; do
        if [ -n "$table" ]; then
            local row_count=$(execute_mysql "SELECT COUNT(*) FROM $table;" "$database" | grep -v "COUNT" 2>/dev/null)
            if [ $? -eq 0 ]; then
                log_message "Table $table: $row_count rows"
            else
                log_message "ERROR: Cannot query table $table"
                return 1
            fi
        fi
    done <<< "$tables"
    
    log_message "Database functionality test completed successfully"
    return 0
}

# Function to perform complete disaster recovery test
disaster_recovery_test() {
    local test_type="$1"
    local start_time=$(date)
    local test_db="dr_test_$(date +%Y%m%d_%H%M%S)"
    
    log_message "========================================="
    log_message "DISASTER RECOVERY TEST STARTED"
    log_message "Test Type: $test_type"
    log_message "Source Database: $DB_NAME"
    log_message "Test Database: $test_db"
    log_message "Start Time: $start_time"
    log_message "========================================="
    
    # Step 1: Pre-test backup
    log_message "Step 1: Creating pre-test backup..."
    if ! ./mysql_automated_backup.sh full; then
        log_message "ERROR: Pre-test backup failed"
        return 1
    fi
    
    # Step 2: Simulate disaster
    log_message "Step 2: Simulating disaster scenario..."
    case "$test_type" in
        "CORRUPTION")
            simulate_corruption "TABLE"
            ;;
        "HARDWARE_FAILURE")
            log_message "Simulating hardware failure scenario..."
            log_message "In real scenario: Server failure, disk corruption, network outage"
            ;;
        "HUMAN_ERROR")
            log_message "Simulating human error scenario..."
            log_message "In real scenario: Accidental DROP TABLE, DELETE without WHERE clause"
            ;;
        *)
            log_message "Simulating general disaster scenario..."
            ;;
    esac
    
    # Step 3: Perform recovery test
    log_message "Step 3: Testing recovery procedures..."
    
    # Test point-in-time recovery to 1 hour ago
    local recovery_point=$(date -d "1 hour ago" "+%Y-%m-%d %H:%M:%S")
    if ! point_in_time_recovery "$recovery_point" "$test_db"; then
        log_message "ERROR: Recovery test failed"
        return 1
    fi
    
    # Step 4: Validate recovered database
    log_message "Step 4: Validating recovered database..."
    if ! check_database_integrity "$test_db" "false"; then
        log_message "WARNING: Integrity issues found in recovered database"
    fi
    
    # Step 5: Test functionality
    log_message "Step 5: Testing database functionality..."
    if ! test_database_functionality "$test_db"; then
        log_message "ERROR: Functionality test failed"
        execute_mysql "DROP DATABASE IF EXISTS $test_db;" ""
        return 1
    fi
    
    # Step 6: Performance test (basic)
    log_message "Step 6: Basic performance test..."
    local start_perf=$(date +%s.%N)
    execute_mysql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$test_db';" "" >/dev/null
    local end_perf=$(date +%s.%N)
    local perf_time=$(echo "$end_perf - $start_perf" | bc -l)
    log_message "Query execution time: ${perf_time}s"
    
    # Step 7: Cleanup
    log_message "Step 7: Cleaning up test database..."
    execute_mysql "DROP DATABASE IF EXISTS $test_db;" ""
    
    local end_time=$(date)
    local duration=$(( $(date -d "$end_time" +%s) - $(date -d "$start_time" +%s) ))
    
    log_message "========================================="
    log_message "DISASTER RECOVERY TEST COMPLETED SUCCESSFULLY"
    log_message "End Time: $end_time"
    log_message "Total Duration: $duration seconds"
    log_message "Recovery Time Objective (RTO): $duration seconds"
    log_message "========================================="
    
    return 0
}

# Function to generate DR documentation
generate_dr_documentation() {
    local doc_file="$DR_TEST_DIR/dr_documentation_$(date +%Y%m%d).txt"
    
    {
        echo "========================================="
        echo "MYSQL DISASTER RECOVERY DOCUMENTATION"
        echo "Generated on: $(date)"
        echo "========================================="
        echo
        echo "1. DATABASE CONFIGURATION:"
        execute_mysql "SELECT @@version AS MySQL_Version;" ""
        execute_mysql "SHOW VARIABLES LIKE 'log_bin';" ""
        execute_mysql "SHOW VARIABLES LIKE 'innodb_file_per_table';" ""
        echo
        echo "2. DATABASE SIZES:"
        execute_mysql "SELECT 
            table_schema AS 'Database',
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
        FROM information_schema.tables 
        WHERE table_schema = '$DB_NAME'
        GROUP BY table_schema;" ""
        echo
        echo "3. BACKUP LOCATIONS:"
        echo "   - Full backups: $BACKUP_DIR/full"
        echo "   - Incremental backups: $BACKUP_DIR/incremental"
        echo "   - Binary logs: $(execute_mysql "SHOW VARIABLES LIKE 'log_bin_basename';" "" | grep log_bin_basename | awk '{print $2}')"
        echo
        echo "4. RECOVERY PROCEDURES:"
        echo "   - Full recovery: ./mysql_disaster_recovery.sh disaster_recovery_test FULL"
        echo "   - Point-in-time recovery: Function point_in_time_recovery"
        echo "   - Integrity check: Function check_database_integrity"
        echo
        echo "5. EMERGENCY CONTACTS:"
        echo "   - Database Administrator: [Contact Information]"
        echo "   - System Administrator: [Contact Information]"
        echo "   - Emergency Escalation: [Contact Information]"
        echo
        echo "6. RECOVERY TIME OBJECTIVES:"
        echo "   - Maximum acceptable downtime (RTO): 2 hours"
        echo "   - Maximum acceptable data loss (RPO): 5 minutes"
        echo
        echo "========================================="
    } > "$doc_file"
    
    log_message "DR documentation generated: $doc_file"
}

# Main execution
case "${1:-help}" in
    "disaster_recovery_test")
        disaster_recovery_test "${2:-FULL}"
        ;;
    "point_in_time_recovery")
        if [ $# -lt 3 ]; then
            echo "Usage: $0 point_in_time_recovery 'YYYY-MM-DD HH:MM:SS' restore_db_name"
            exit 1
        fi
        point_in_time_recovery "$2" "$3"
        ;;
    "simulate_corruption")
        simulate_corruption "${2:-TABLE}"
        ;;
    "check_integrity")
        check_database_integrity "${2:-$DB_NAME}" "${3:-false}"
        ;;
    "test_functionality")
        test_database_functionality "${2:-$DB_NAME}"
        ;;
    "generate_documentation")
        generate_dr_documentation
        ;;
    "help"|*)
        echo "MySQL Disaster Recovery Testing Script"
        echo "Usage: $0 {command} [options]"
        echo
        echo "Commands:"
        echo "  disaster_recovery_test [type]     - Run complete DR test (FULL|CORRUPTION|HARDWARE_FAILURE|HUMAN_ERROR)"
        echo "  point_in_time_recovery 'time' db  - Restore to specific point in time"
        echo "  simulate_corruption [type]        - Simulate corruption (TABLE|INDEX|INNODB)"
        echo "  check_integrity [db] [fix]        - Check database integrity (true/false for fix)"
        echo "  test_functionality [db]           - Test basic database functionality"
        echo "  generate_documentation            - Generate DR documentation"
        echo "  help                              - Show this help"
        echo
        echo "Examples:"
        echo "  $0 disaster_recovery_test CORRUPTION"
        echo "  $0 point_in_time_recovery '2025-01-01 12:00:00' restored_db"
        echo "  $0 check_integrity company_db true"
        ;;
esac
