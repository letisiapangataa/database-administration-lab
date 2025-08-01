-- =============================================
-- MySQL Query Optimization & Performance Tuning
-- Purpose: Index analysis, query optimization, and performance monitoring
-- =============================================

USE company_db;

-- =============================================
-- INDEX ANALYSIS PROCEDURES
-- =============================================

-- Procedure to identify unused indexes
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS sp_find_unused_indexes()
BEGIN
    SELECT 
        t.TABLE_SCHEMA,
        t.TABLE_NAME,
        s.INDEX_NAME,
        s.CARDINALITY,
        'ALTER TABLE ' + t.TABLE_SCHEMA + '.' + t.TABLE_NAME + ' DROP INDEX ' + s.INDEX_NAME + ';' AS drop_statement
    FROM information_schema.STATISTICS s
    JOIN information_schema.TABLES t ON s.TABLE_SCHEMA = t.TABLE_SCHEMA AND s.TABLE_NAME = t.TABLE_NAME
    LEFT JOIN performance_schema.table_io_waits_summary_by_index_usage i 
        ON s.TABLE_SCHEMA = i.OBJECT_SCHEMA 
        AND s.TABLE_NAME = i.OBJECT_NAME 
        AND s.INDEX_NAME = i.INDEX_NAME
    WHERE t.TABLE_SCHEMA = DATABASE()
        AND s.INDEX_NAME != 'PRIMARY'
        AND (i.COUNT_READ IS NULL OR i.COUNT_READ = 0)
    ORDER BY t.TABLE_NAME, s.INDEX_NAME;
END//

-- Procedure to analyze table statistics
CREATE PROCEDURE IF NOT EXISTS sp_analyze_table_stats()
BEGIN
    SELECT 
        TABLE_NAME,
        TABLE_ROWS,
        ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS 'Size (MB)',
        ROUND(DATA_LENGTH / 1024 / 1024, 2) AS 'Data Size (MB)',
        ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS 'Index Size (MB)',
        AUTO_INCREMENT,
        TABLE_COLLATION
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_TYPE = 'BASE TABLE'
    ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;
END//

-- Procedure to find duplicate indexes
CREATE PROCEDURE IF NOT EXISTS sp_find_duplicate_indexes()
BEGIN
    SELECT 
        TABLE_SCHEMA,
        TABLE_NAME,
        GROUP_CONCAT(INDEX_NAME) AS duplicate_indexes,
        GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
        AND INDEX_NAME != 'PRIMARY'
    GROUP BY TABLE_SCHEMA, TABLE_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX)
    HAVING COUNT(*) > 1;
END//

DELIMITER ;

-- =============================================
-- PERFORMANCE MONITORING PROCEDURES
-- =============================================

DELIMITER //

-- Procedure to identify slow queries
CREATE PROCEDURE IF NOT EXISTS sp_find_slow_queries()
BEGIN
    SELECT 
        SCHEMA_NAME,
        DIGEST_TEXT,
        COUNT_STAR,
        SUM_TIMER_WAIT/1000000000000 AS total_time_seconds,
        AVG_TIMER_WAIT/1000000000000 AS avg_time_seconds,
        SUM_ROWS_EXAMINED,
        SUM_ROWS_SENT,
        SUM_SELECT_SCAN,
        FIRST_SEEN,
        LAST_SEEN
    FROM performance_schema.events_statements_summary_by_digest
    WHERE SCHEMA_NAME = DATABASE()
        AND AVG_TIMER_WAIT > 1000000000  -- More than 1 second average
    ORDER BY AVG_TIMER_WAIT DESC
    LIMIT 20;
END//

-- Procedure to monitor table I/O
CREATE PROCEDURE IF NOT EXISTS sp_monitor_table_io()
BEGIN
    SELECT 
        OBJECT_SCHEMA,
        OBJECT_NAME,
        COUNT_READ,
        COUNT_WRITE,
        COUNT_FETCH,
        COUNT_INSERT,
        COUNT_UPDATE,
        COUNT_DELETE,
        SUM_TIMER_WAIT/1000000000000 AS total_time_seconds
    FROM performance_schema.table_io_waits_summary_by_table
    WHERE OBJECT_SCHEMA = DATABASE()
        AND COUNT_READ + COUNT_WRITE > 0
    ORDER BY SUM_TIMER_WAIT DESC;
END//

-- Procedure to check for full table scans
CREATE PROCEDURE IF NOT EXISTS sp_find_full_table_scans()
BEGIN
    SELECT 
        OBJECT_SCHEMA,
        OBJECT_NAME,
        INDEX_NAME,
        COUNT_READ,
        COUNT_FETCH,
        SUM_TIMER_WAIT/1000000000000 AS total_time_seconds
    FROM performance_schema.table_io_waits_summary_by_index_usage
    WHERE OBJECT_SCHEMA = DATABASE()
        AND INDEX_NAME IS NULL  -- NULL indicates full table scan
        AND COUNT_READ > 100
    ORDER BY COUNT_READ DESC;
END//

DELIMITER ;

-- =============================================
-- SAMPLE OPTIMIZED STORED PROCEDURES
-- =============================================

DELIMITER //

-- Optimized customer search with proper indexing
CREATE PROCEDURE IF NOT EXISTS sp_optimized_customer_search(
    IN p_customer_name VARCHAR(100),
    IN p_city VARCHAR(50),
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Enable query cache for this session
    SET SESSION query_cache_type = ON;
    
    -- Use prepared statement to avoid SQL injection
    SET @sql = 'SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        c.country,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(od.quantity * od.unit_price), 0) AS total_order_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id';
    
    -- Add date filter if provided
    IF p_start_date IS NOT NULL OR p_end_date IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND o.order_date BETWEEN COALESCE(?, o.order_date) AND COALESCE(?, o.order_date)');
    END IF;
    
    SET @sql = CONCAT(@sql, '
    LEFT JOIN order_details od ON o.order_id = od.order_id
    WHERE 1=1');
    
    -- Add filters based on parameters
    IF p_customer_name IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND c.customer_name LIKE CONCAT(?, "%")');
    END IF;
    
    IF p_city IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND c.city = ?');
    END IF;
    
    SET @sql = CONCAT(@sql, '
    GROUP BY c.customer_id, c.customer_name, c.city, c.country
    ORDER BY total_order_value DESC
    LIMIT 100');
    
    -- Prepare and execute with parameters
    PREPARE stmt FROM @sql;
    
    -- Execute based on provided parameters
    IF p_customer_name IS NOT NULL AND p_city IS NOT NULL AND p_start_date IS NOT NULL THEN
        EXECUTE stmt USING p_customer_name, p_city, p_start_date, p_end_date;
    ELSEIF p_customer_name IS NOT NULL AND p_city IS NOT NULL THEN
        EXECUTE stmt USING p_customer_name, p_city;
    ELSEIF p_customer_name IS NOT NULL THEN
        EXECUTE stmt USING p_customer_name;
    ELSEIF p_city IS NOT NULL THEN
        EXECUTE stmt USING p_city;
    ELSE
        EXECUTE stmt;
    END IF;
    
    DEALLOCATE PREPARE stmt;
END//

DELIMITER ;

-- =============================================
-- CREATE SAMPLE TABLES WITH OPTIMIZED STRUCTURE
-- =============================================

-- Create customers table with proper indexing
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    city VARCHAR(50),
    country VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    INDEX idx_customer_city_name (city, customer_name),
    INDEX idx_customer_country (country),
    INDEX idx_customer_created_date (created_date)
) ENGINE=InnoDB;

-- Create orders table with proper indexing
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    
    -- Indexes for performance
    INDEX idx_orders_customer_date (customer_id, order_date),
    INDEX idx_orders_date_status (order_date, status),
    INDEX idx_orders_status (status)
) ENGINE=InnoDB;

-- Create order_details table with proper indexing
CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    
    -- Foreign key constraint
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    
    -- Indexes for performance
    INDEX idx_order_details_order_id (order_id),
    INDEX idx_order_details_product (product_name)
) ENGINE=InnoDB;

-- =============================================
-- OPTIMIZATION CONFIGURATION
-- =============================================

-- Enable performance schema if not already enabled
-- SET GLOBAL performance_schema = ON;

-- Configure query cache (if using MySQL 5.7 or earlier)
-- SET GLOBAL query_cache_size = 268435456;  -- 256MB
-- SET GLOBAL query_cache_type = ON;

-- Configure InnoDB buffer pool
-- SET GLOBAL innodb_buffer_pool_size = 1073741824;  -- 1GB

-- =============================================
-- PERFORMANCE ANALYSIS QUERIES
-- =============================================

-- View to check current MySQL configuration
CREATE OR REPLACE VIEW v_mysql_performance_config AS
SELECT 
    'innodb_buffer_pool_size' AS setting_name,
    @@innodb_buffer_pool_size AS current_value,
    'Bytes' AS unit
UNION ALL
SELECT 
    'max_connections',
    @@max_connections,
    'Connections'
UNION ALL
SELECT 
    'thread_cache_size',
    @@thread_cache_size,
    'Threads'
UNION ALL
SELECT 
    'table_open_cache',
    @@table_open_cache,
    'Tables';

-- View to monitor current database statistics
CREATE OR REPLACE VIEW v_database_statistics AS
SELECT 
    'Total Tables' AS metric,
    COUNT(*) AS value
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
UNION ALL
SELECT 
    'Total Indexes',
    COUNT(DISTINCT INDEX_NAME)
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
UNION ALL
SELECT 
    'Database Size (MB)',
    ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2)
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE();

-- Test query to validate optimization setup
SELECT 'MySQL optimization procedures and sample schema created successfully' AS status;

-- Show available optimization procedures
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
