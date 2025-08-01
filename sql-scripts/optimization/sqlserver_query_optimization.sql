-- =============================================
-- SQL Server Query Optimization & Performance Tuning
-- Purpose: Index analysis, query optimization, and performance monitoring
-- =============================================

USE [CompanyDB]
GO

-- =============================================
-- INDEX ANALYSIS AND RECOMMENDATIONS
-- =============================================

-- Create procedure to identify missing indexes
CREATE OR ALTER PROCEDURE sp_FindMissingIndexes
AS
BEGIN
    SET NOCOUNT ON
    
    SELECT 
        ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans), 0) AS [Total Cost],
        d.database_id,
        d.object_id,
        d.equality_columns,
        d.inequality_columns,
        d.included_columns,
        s.unique_compiles,
        s.user_seeks,
        s.user_scans,
        OBJECT_NAME(d.object_id, d.database_id) AS [Table Name],
        'CREATE INDEX [IX_' + OBJECT_NAME(d.object_id, d.database_id) + '_' + 
        REPLACE(REPLACE(REPLACE(ISNULL(d.equality_columns, ''), ', ', '_'), '[', ''), ']', '') + 
        CASE WHEN d.inequality_columns IS NOT NULL THEN '_' + 
        REPLACE(REPLACE(REPLACE(d.inequality_columns, ', ', '_'), '[', ''), ']', '') ELSE '' END + '] ON ' + 
        d.statement + ' (' + ISNULL(d.equality_columns, '') + 
        CASE WHEN d.equality_columns IS NOT NULL AND d.inequality_columns IS NOT NULL THEN ',' ELSE '' END + 
        ISNULL(d.inequality_columns, '') + ')' + 
        ISNULL(' INCLUDE (' + d.included_columns + ')', '') AS [Proposed Index Statement]
    FROM sys.dm_db_missing_index_group_stats s
    INNER JOIN sys.dm_db_missing_index_groups g ON s.group_handle = g.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details d ON g.index_handle = d.index_handle
    WHERE d.database_id = DB_ID()
    ORDER BY [Total Cost] DESC
END
GO

-- Create procedure to identify unused indexes
CREATE OR ALTER PROCEDURE sp_FindUnusedIndexes
AS
BEGIN
    SET NOCOUNT ON
    
    SELECT 
        OBJECT_NAME(i.object_id) AS [Table Name],
        i.name AS [Index Name],
        i.index_id,
        dm_ius.user_seeks,
        dm_ius.user_scans,
        dm_ius.user_lookups,
        dm_ius.user_updates,
        p.TableRows,
        'DROP INDEX [' + i.name + '] ON [' + SCHEMA_NAME(t.schema_id) + '].[' + OBJECT_NAME(i.object_id) + ']' AS [Drop Statement]
    FROM sys.indexes i
    INNER JOIN sys.objects t ON i.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT OUTER JOIN sys.dm_db_index_usage_stats dm_ius ON i.index_id = dm_ius.index_id 
        AND dm_ius.object_id = i.object_id
    INNER JOIN (SELECT SUM(p.rows) TableRows, p.object_id, p.index_id
                FROM sys.partitions p GROUP BY p.object_id, p.index_id) p
        ON p.object_id = i.object_id AND p.index_id = i.index_id
    WHERE OBJECTPROPERTY(i.object_id,'IsUserTable') = 1
        AND dm_ius.index_id IS NULL OR (dm_ius.user_seeks = 0 AND dm_ius.user_scans = 0 AND dm_ius.user_lookups = 0)
        AND i.is_primary_key = 0
        AND i.is_unique_constraint = 0
    ORDER BY OBJECT_NAME(i.object_id), i.name
END
GO

-- =============================================
-- QUERY PERFORMANCE ANALYSIS
-- =============================================

-- Create procedure to find top resource-consuming queries
CREATE OR ALTER PROCEDURE sp_FindTopResourceQueries
    @TopCount INT = 10
AS
BEGIN
    SET NOCOUNT ON
    
    -- Top CPU consuming queries
    SELECT TOP (@TopCount)
        'CPU Usage' AS [Metric],
        total_worker_time AS [Total Time],
        total_worker_time/execution_count AS [Avg Time], 
        execution_count,
        SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
            ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(st.text) 
            ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS [Query Text]
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
    ORDER BY total_worker_time DESC
    
    UNION ALL
    
    -- Top I/O consuming queries
    SELECT TOP (@TopCount)
        'I/O Usage' AS [Metric],
        (total_logical_reads + total_logical_writes + total_physical_reads) AS [Total Time],
        (total_logical_reads + total_logical_writes + total_physical_reads)/execution_count AS [Avg Time],
        execution_count,
        SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
            ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(st.text) 
            ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS [Query Text]
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
    ORDER BY (total_logical_reads + total_logical_writes + total_physical_reads) DESC
END
GO

-- =============================================
-- STORED PROCEDURE OPTIMIZATION
-- =============================================

-- Create sample stored procedure with optimization techniques
CREATE OR ALTER PROCEDURE sp_OptimizedCustomerSearch
    @CustomerName NVARCHAR(100) = NULL,
    @City NVARCHAR(50) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- For reporting queries
    
    -- Use parameter sniffing optimization
    DECLARE @CustomerNameParam NVARCHAR(100) = @CustomerName
    DECLARE @CityParam NVARCHAR(50) = @City
    DECLARE @StartDateParam DATE = @StartDate
    DECLARE @EndDateParam DATE = @EndDate
    
    -- Dynamic SQL with proper parameterization to avoid SQL injection
    DECLARE @SQL NVARCHAR(MAX) = N'
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.City,
        c.Country,
        COUNT(o.OrderID) AS OrderCount,
        SUM(od.Quantity * od.UnitPrice) AS TotalOrderValue
    FROM Customers c WITH (NOLOCK)
    LEFT JOIN Orders o WITH (NOLOCK) ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od WITH (NOLOCK) ON o.OrderID = od.OrderID
    WHERE 1=1'
    
    -- Build WHERE clause dynamically based on provided parameters
    IF @CustomerNameParam IS NOT NULL
        SET @SQL = @SQL + N' AND c.CustomerName LIKE @CustomerNameParam + ''%'''
    
    IF @CityParam IS NOT NULL
        SET @SQL = @SQL + N' AND c.City = @CityParam'
    
    IF @StartDateParam IS NOT NULL
        SET @SQL = @SQL + N' AND o.OrderDate >= @StartDateParam'
    
    IF @EndDateParam IS NOT NULL
        SET @SQL = @SQL + N' AND o.OrderDate <= @EndDateParam'
    
    SET @SQL = @SQL + N'
    GROUP BY c.CustomerID, c.CustomerName, c.City, c.Country
    ORDER BY TotalOrderValue DESC'
    
    -- Execute with parameters
    EXEC sp_executesql @SQL,
        N'@CustomerNameParam NVARCHAR(100), @CityParam NVARCHAR(50), @StartDateParam DATE, @EndDateParam DATE',
        @CustomerNameParam, @CityParam, @StartDateParam, @EndDateParam
END
GO

-- =============================================
-- PERFORMANCE MONITORING SETUP
-- =============================================

-- Create procedure to monitor database performance metrics
CREATE OR ALTER PROCEDURE sp_DatabasePerformanceReport
AS
BEGIN
    SET NOCOUNT ON
    
    -- Database file sizes and growth
    SELECT 
        name AS [File Name],
        physical_name AS [Physical Name],
        size/128.0 AS [Size (MB)],
        size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS [Available Space (MB)],
        type_desc AS [File Type]
    FROM sys.database_files
    
    -- Wait statistics
    SELECT TOP 10
        wait_type,
        wait_time_ms,
        signal_wait_time_ms,
        waiting_tasks_count,
        wait_time_ms / waiting_tasks_count AS [Avg Wait Time (ms)]
    FROM sys.dm_os_wait_stats
    WHERE waiting_tasks_count > 0
    ORDER BY wait_time_ms DESC
    
    -- Index fragmentation
    SELECT 
        OBJECT_NAME(ips.object_id) AS [Table Name],
        i.name AS [Index Name],
        ips.index_type_desc,
        ips.avg_fragmentation_in_percent,
        ips.page_count
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.avg_fragmentation_in_percent > 10
        AND ips.page_count > 1000
    ORDER BY ips.avg_fragmentation_in_percent DESC
END
GO

-- Create sample tables for testing optimization
CREATE TABLE IF NOT EXISTS Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    City NVARCHAR(50),
    Country NVARCHAR(50),
    CreatedDate DATETIME2 DEFAULT GETDATE()
)

CREATE TABLE IF NOT EXISTS Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
)

CREATE TABLE IF NOT EXISTS OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    ProductName NVARCHAR(100),
    Quantity INT,
    UnitPrice DECIMAL(10,2)
)

-- Create optimized indexes
CREATE NONCLUSTERED INDEX IX_Customers_City_Name ON Customers (City, CustomerName)
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_Date ON Orders (CustomerID, OrderDate) INCLUDE (TotalAmount)
CREATE NONCLUSTERED INDEX IX_OrderDetails_OrderID ON OrderDetails (OrderID) INCLUDE (Quantity, UnitPrice)

PRINT 'Query optimization procedures and sample schema created successfully'
GO
