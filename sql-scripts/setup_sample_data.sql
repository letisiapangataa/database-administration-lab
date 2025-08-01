-- =============================================
-- Database Setup and Sample Data Creation
-- Purpose: Initialize lab environment with sample data
-- =============================================

USE [master]
GO

-- Create the main lab database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CompanyDB')
BEGIN
    CREATE DATABASE [CompanyDB]
    ALTER DATABASE [CompanyDB] SET RECOVERY FULL
    PRINT 'CompanyDB database created successfully'
END
GO

USE [CompanyDB]
GO

-- =============================================
-- CREATE SAMPLE TABLES
-- =============================================

-- Customers table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(20),
    Address NVARCHAR(200),
    City NVARCHAR(50),
    State NVARCHAR(50),
    Country NVARCHAR(50),
    PostalCode NVARCHAR(20),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    LastModified DATETIME2 DEFAULT GETDATE()
)

-- Orders table
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    RequiredDate DATE,
    ShippedDate DATE,
    ShipAddress NVARCHAR(200),
    ShipCity NVARCHAR(50),
    ShipCountry NVARCHAR(50),
    TotalAmount DECIMAL(10,2),
    Status NVARCHAR(20) DEFAULT 'Pending',
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
)

-- Products table
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    CategoryID INT,
    UnitPrice DECIMAL(10,2),
    UnitsInStock INT DEFAULT 0,
    UnitsOnOrder INT DEFAULT 0,
    ReorderLevel INT DEFAULT 0,
    Discontinued BIT DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE()
)

-- Order Details table
CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    Discount REAL DEFAULT 0,
    
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
)

-- Categories table
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255),
    CreatedDate DATETIME2 DEFAULT GETDATE()
)

-- Employees table
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(100),
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(20),
    HireDate DATE,
    Salary DECIMAL(10,2),
    DepartmentID INT,
    ManagerID INT,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    
    FOREIGN KEY (ManagerID) REFERENCES Employees(EmployeeID)
)

-- Departments table
CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100),
    Budget DECIMAL(12,2),
    CreatedDate DATETIME2 DEFAULT GETDATE()
)

-- Add foreign key for Products -> Categories
ALTER TABLE Products ADD FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)

-- Add foreign key for Employees -> Departments
ALTER TABLE Employees ADD FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

-- Insert Categories
INSERT INTO Categories (CategoryName, Description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Books', 'Books and educational materials'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports', 'Sports equipment and accessories'),
('Toys', 'Toys and games for children'),
('Automotive', 'Car parts and accessories'),
('Health', 'Health and wellness products')

-- Insert Departments
INSERT INTO Departments (DepartmentName, Location, Budget) VALUES
('Sales', 'New York', 500000.00),
('Marketing', 'Los Angeles', 300000.00),
('IT', 'Seattle', 750000.00),
('HR', 'Chicago', 200000.00),
('Finance', 'New York', 400000.00),
('Operations', 'Dallas', 600000.00)

-- Insert sample Products
INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock) VALUES
('Laptop Computer', 1, 999.99, 50),
('Smartphone', 1, 699.99, 100),
('Wireless Headphones', 1, 199.99, 75),
('Cotton T-Shirt', 2, 19.99, 200),
('Jeans', 2, 59.99, 150),
('Programming Book', 3, 45.99, 30),
('Garden Hose', 4, 29.99, 25),
('Basketball', 5, 24.99, 40),
('Board Game', 6, 34.99, 60),
('Car Battery', 7, 89.99, 20),
('Vitamin C', 8, 12.99, 80),
('Running Shoes', 5, 89.99, 70),
('Coffee Maker', 4, 79.99, 35),
('Tablet', 1, 399.99, 45),
('Winter Jacket', 2, 129.99, 25)

-- Insert sample Employees
INSERT INTO Employees (FirstName, LastName, Title, Email, Phone, HireDate, Salary, DepartmentID) VALUES
('John', 'Smith', 'Sales Manager', 'john.smith@company.com', '555-1001', '2020-01-15', 75000.00, 1),
('Sarah', 'Johnson', 'Marketing Director', 'sarah.johnson@company.com', '555-1002', '2019-03-20', 85000.00, 2),
('Mike', 'Davis', 'IT Manager', 'mike.davis@company.com', '555-1003', '2018-07-10', 90000.00, 3),
('Lisa', 'Wilson', 'HR Specialist', 'lisa.wilson@company.com', '555-1004', '2021-02-14', 55000.00, 4),
('David', 'Brown', 'Financial Analyst', 'david.brown@company.com', '555-1005', '2020-09-08', 65000.00, 5),
('Jennifer', 'Taylor', 'Operations Coordinator', 'jennifer.taylor@company.com', '555-1006', '2019-11-12', 50000.00, 6),
('Robert', 'Anderson', 'Senior Developer', 'robert.anderson@company.com', '555-1007', '2018-04-25', 80000.00, 3),
('Emily', 'Martinez', 'Sales Representative', 'emily.martinez@company.com', '555-1008', '2021-06-30', 45000.00, 1),
('James', 'Garcia', 'Marketing Specialist', 'james.garcia@company.com', '555-1009', '2020-12-01', 50000.00, 2),
('Michelle', 'Lee', 'Accountant', 'michelle.lee@company.com', '555-1010', '2019-08-15', 55000.00, 5)

-- Insert sample Customers
DECLARE @i INT = 1
WHILE @i <= 1000
BEGIN
    INSERT INTO Customers (CustomerName, Email, Phone, City, State, Country, PostalCode)
    VALUES (
        'Customer ' + CAST(@i AS VARCHAR),
        'customer' + CAST(@i AS VARCHAR) + '@email.com',
        '555-' + RIGHT('0000' + CAST(@i AS VARCHAR), 4),
        CASE (@i % 10)
            WHEN 0 THEN 'New York'
            WHEN 1 THEN 'Los Angeles'
            WHEN 2 THEN 'Chicago'
            WHEN 3 THEN 'Houston'
            WHEN 4 THEN 'Phoenix'
            WHEN 5 THEN 'Philadelphia'
            WHEN 6 THEN 'San Antonio'
            WHEN 7 THEN 'San Diego'
            WHEN 8 THEN 'Dallas'
            ELSE 'San Jose'
        END,
        CASE (@i % 5)
            WHEN 0 THEN 'NY'
            WHEN 1 THEN 'CA'
            WHEN 2 THEN 'IL'
            WHEN 3 THEN 'TX'
            ELSE 'AZ'
        END,
        'USA',
        RIGHT('00000' + CAST((10000 + @i) AS VARCHAR), 5)
    )
    SET @i = @i + 1
END

-- Insert sample Orders
DECLARE @j INT = 1
WHILE @j <= 5000
BEGIN
    INSERT INTO Orders (CustomerID, OrderDate, RequiredDate, TotalAmount, Status)
    VALUES (
        ((@j % 1000) + 1),  -- Random customer ID between 1-1000
        DATEADD(DAY, -(@j % 365), GETDATE()),  -- Random date within last year
        DATEADD(DAY, 7, DATEADD(DAY, -(@j % 365), GETDATE())),  -- Required date 7 days after order
        ROUND((RAND() * 1000 + 50), 2),  -- Random amount between $50-$1050
        CASE (@j % 5)
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'Processing'
            WHEN 2 THEN 'Shipped'
            WHEN 3 THEN 'Delivered'
            ELSE 'Completed'
        END
    )
    SET @j = @j + 1
END

-- Insert sample Order Details
DECLARE @k INT = 1
WHILE @k <= 15000
BEGIN
    INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
    VALUES (
        ((@k % 5000) + 1),  -- Random order ID
        ((@k % 15) + 1),    -- Random product ID between 1-15
        ROUND((RAND() * 100 + 10), 2),  -- Random price between $10-$110
        (@k % 5) + 1,       -- Random quantity between 1-5
        ROUND((RAND() * 0.2), 2)  -- Random discount 0-20%
    )
    SET @k = @k + 1
END

-- =============================================
-- CREATE PERFORMANCE-OPTIMIZED INDEXES
-- =============================================

-- Customer indexes
CREATE INDEX IX_Customers_City ON Customers (City)
CREATE INDEX IX_Customers_Country ON Customers (Country)
CREATE INDEX IX_Customers_Email ON Customers (Email)
CREATE INDEX IX_Customers_Name ON Customers (CustomerName)

-- Order indexes
CREATE INDEX IX_Orders_CustomerID ON Orders (CustomerID)
CREATE INDEX IX_Orders_OrderDate ON Orders (OrderDate)
CREATE INDEX IX_Orders_Status ON Orders (Status)
CREATE INDEX IX_Orders_Customer_Date ON Orders (CustomerID, OrderDate) INCLUDE (TotalAmount)

-- Order Details indexes
CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails (OrderID)
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails (ProductID)
CREATE INDEX IX_OrderDetails_Order_Product ON OrderDetails (OrderID, ProductID)

-- Product indexes
CREATE INDEX IX_Products_CategoryID ON Products (CategoryID)
CREATE INDEX IX_Products_Name ON Products (ProductName)
CREATE INDEX IX_Products_Price ON Products (UnitPrice)

-- Employee indexes
CREATE INDEX IX_Employees_DepartmentID ON Employees (DepartmentID)
CREATE INDEX IX_Employees_Email ON Employees (Email)
CREATE INDEX IX_Employees_Name ON Employees (LastName, FirstName)

-- =============================================
-- CREATE VIEWS FOR REPORTING
-- =============================================

-- Customer Order Summary View
CREATE VIEW vw_CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    c.Country,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalOrderValue,
    AVG(o.TotalAmount) AS AvgOrderValue,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.City, c.Country

-- Product Sales Summary View
CREATE VIEW vw_ProductSalesSummary AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    COUNT(od.OrderDetailID) AS TimesSold,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalRevenue,
    AVG(od.UnitPrice) AS AvgSellingPrice
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName

-- Monthly Sales Report View
CREATE VIEW vw_MonthlySalesReport AS
SELECT 
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    DATENAME(MONTH, o.OrderDate) AS MonthName,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    SUM(o.TotalAmount) AS TotalRevenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM Orders o
WHERE o.OrderDate IS NOT NULL
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATENAME(MONTH, o.OrderDate)

-- =============================================
-- UPDATE STATISTICS
-- =============================================
UPDATE STATISTICS Customers
UPDATE STATISTICS Orders  
UPDATE STATISTICS OrderDetails
UPDATE STATISTICS Products
UPDATE STATISTICS Categories
UPDATE STATISTICS Employees
UPDATE STATISTICS Departments

-- =============================================
-- FINAL VERIFICATION
-- =============================================
PRINT 'Database setup completed successfully!'
PRINT 'Tables created with sample data:'

SELECT 
    t.TABLE_NAME,
    p.rows AS RecordCount
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN sys.partitions p ON OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME) = p.object_id
WHERE t.TABLE_TYPE = 'BASE TABLE' 
    AND p.index_id IN (0,1)
    AND t.TABLE_SCHEMA = 'dbo'
ORDER BY t.TABLE_NAME

PRINT 'Sample queries to test:'
PRINT '1. SELECT * FROM vw_CustomerOrderSummary WHERE TotalOrders > 5'
PRINT '2. SELECT * FROM vw_ProductSalesSummary ORDER BY TotalRevenue DESC'
PRINT '3. SELECT * FROM vw_MonthlySalesReport ORDER BY SalesYear DESC, SalesMonth DESC'
