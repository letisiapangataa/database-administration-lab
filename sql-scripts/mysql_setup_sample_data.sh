#!/bin/bash
# =============================================
# MySQL Sample Data Setup Script
# Purpose: Initialize lab environment with sample data
# =============================================

# Configuration
DB_NAME="company_db"
DB_USER="root"
DB_PASSWORD=""
DB_HOST="localhost"

# Function to execute MySQL commands
execute_mysql() {
    local query="$1"
    local database="${2:-$DB_NAME}"
    
    if [ -z "$DB_PASSWORD" ]; then
        mysql --user="$DB_USER" --host="$DB_HOST" "$database" -e "$query"
    else
        mysql --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" "$database" -e "$query"
    fi
}

# Function to execute MySQL script file
execute_mysql_file() {
    local file="$1"
    local database="${2:-$DB_NAME}"
    
    if [ -z "$DB_PASSWORD" ]; then
        mysql --user="$DB_USER" --host="$DB_HOST" "$database" < "$file"
    else
        mysql --user="$DB_USER" --password="$DB_PASSWORD" --host="$DB_HOST" "$database" < "$file"
    fi
}

echo "Setting up MySQL Company Database with sample data..."

# Create the database
execute_mysql "CREATE DATABASE IF NOT EXISTS $DB_NAME;" ""
echo "Database '$DB_NAME' created successfully"

# Create tables and insert data using multi-line SQL
cat << 'EOF' | execute_mysql_file /dev/stdin

-- Create Categories table
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Create Departments table
CREATE TABLE IF NOT EXISTS departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    budget DECIMAL(12,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Create Customers table
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_customer_city_name (city, customer_name),
    INDEX idx_customer_country (country),
    INDEX idx_customer_email (email)
) ENGINE=InnoDB;

-- Create Products table
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT,
    unit_price DECIMAL(10,2),
    units_in_stock INT DEFAULT 0,
    units_on_order INT DEFAULT 0,
    reorder_level INT DEFAULT 0,
    discontinued BOOLEAN DEFAULT FALSE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    INDEX idx_products_category (category_id),
    INDEX idx_products_name (product_name),
    INDEX idx_products_price (unit_price)
) ENGINE=InnoDB;

-- Create Employees table
CREATE TABLE IF NOT EXISTS employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    title VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    hire_date DATE,
    salary DECIMAL(10,2),
    department_id INT,
    manager_id INT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id),
    INDEX idx_employees_department (department_id),
    INDEX idx_employees_email (email),
    INDEX idx_employees_name (last_name, first_name)
) ENGINE=InnoDB;

-- Create Orders table
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    required_date DATE,
    shipped_date DATE,
    ship_address VARCHAR(200),
    ship_city VARCHAR(50),
    ship_country VARCHAR(50),
    total_amount DECIMAL(10,2),
    status ENUM('Pending', 'Processing', 'Shipped', 'Delivered', 'Completed', 'Cancelled') DEFAULT 'Pending',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_orders_customer_date (customer_id, order_date),
    INDEX idx_orders_date_status (order_date, status),
    INDEX idx_orders_status (status)
) ENGINE=InnoDB;

-- Create Order Details table
CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    discount DECIMAL(4,2) DEFAULT 0.00,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_order_details_order_id (order_id),
    INDEX idx_order_details_product_id (product_id),
    INDEX idx_order_details_order_product (order_id, product_id)
) ENGINE=InnoDB;

-- Insert sample Categories
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Books', 'Books and educational materials'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports', 'Sports equipment and accessories'),
('Toys', 'Toys and games for children'),
('Automotive', 'Car parts and accessories'),
('Health', 'Health and wellness products');

-- Insert sample Departments
INSERT INTO departments (department_name, location, budget) VALUES
('Sales', 'New York', 500000.00),
('Marketing', 'Los Angeles', 300000.00),
('IT', 'Seattle', 750000.00),
('HR', 'Chicago', 200000.00),
('Finance', 'New York', 400000.00),
('Operations', 'Dallas', 600000.00);

-- Insert sample Products
INSERT INTO products (product_name, category_id, unit_price, units_in_stock) VALUES
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
('Winter Jacket', 2, 129.99, 25);

-- Insert sample Employees
INSERT INTO employees (first_name, last_name, title, email, phone, hire_date, salary, department_id) VALUES
('John', 'Smith', 'Sales Manager', 'john.smith@company.com', '555-1001', '2020-01-15', 75000.00, 1),
('Sarah', 'Johnson', 'Marketing Director', 'sarah.johnson@company.com', '555-1002', '2019-03-20', 85000.00, 2),
('Mike', 'Davis', 'IT Manager', 'mike.davis@company.com', '555-1003', '2018-07-10', 90000.00, 3),
('Lisa', 'Wilson', 'HR Specialist', 'lisa.wilson@company.com', '555-1004', '2021-02-14', 55000.00, 4),
('David', 'Brown', 'Financial Analyst', 'david.brown@company.com', '555-1005', '2020-09-08', 65000.00, 5),
('Jennifer', 'Taylor', 'Operations Coordinator', 'jennifer.taylor@company.com', '555-1006', '2019-11-12', 50000.00, 6),
('Robert', 'Anderson', 'Senior Developer', 'robert.anderson@company.com', '555-1007', '2018-04-25', 80000.00, 3),
('Emily', 'Martinez', 'Sales Representative', 'emily.martinez@company.com', '555-1008', '2021-06-30', 45000.00, 1),
('James', 'Garcia', 'Marketing Specialist', 'james.garcia@company.com', '555-1009', '2020-12-01', 50000.00, 2),
('Michelle', 'Lee', 'Accountant', 'michelle.lee@company.com', '555-1010', '2019-08-15', 55000.00, 5);

EOF

echo "Basic tables and sample data created successfully"

# Generate larger datasets using stored procedure
echo "Generating sample customers..."

execute_mysql "
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS generate_customers(IN num_customers INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE city_name VARCHAR(50);
    DECLARE state_code VARCHAR(5);
    
    WHILE i <= num_customers DO
        -- Select city and state based on modulo
        CASE (i % 10)
            WHEN 0 THEN SET city_name = 'New York', state_code = 'NY';
            WHEN 1 THEN SET city_name = 'Los Angeles', state_code = 'CA';
            WHEN 2 THEN SET city_name = 'Chicago', state_code = 'IL';
            WHEN 3 THEN SET city_name = 'Houston', state_code = 'TX';
            WHEN 4 THEN SET city_name = 'Phoenix', state_code = 'AZ';
            WHEN 5 THEN SET city_name = 'Philadelphia', state_code = 'PA';
            WHEN 6 THEN SET city_name = 'San Antonio', state_code = 'TX';
            WHEN 7 THEN SET city_name = 'San Diego', state_code = 'CA';
            WHEN 8 THEN SET city_name = 'Dallas', state_code = 'TX';
            ELSE SET city_name = 'San Jose', state_code = 'CA';
        END CASE;
        
        INSERT INTO customers (customer_name, email, phone, city, state, country, postal_code)
        VALUES (
            CONCAT('Customer ', i),
            CONCAT('customer', i, '@email.com'),
            CONCAT('555-', LPAD(i, 4, '0')),
            city_name,
            state_code,
            'USA',
            LPAD((10000 + i), 5, '0')
        );
        
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ;

CALL generate_customers(1000);
DROP PROCEDURE generate_customers;
"

echo "Generating sample orders..."

execute_mysql "
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS generate_orders(IN num_orders INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE order_status VARCHAR(20);
    
    WHILE i <= num_orders DO
        -- Select status based on modulo
        CASE (i % 5)
            WHEN 0 THEN SET order_status = 'Pending';
            WHEN 1 THEN SET order_status = 'Processing';
            WHEN 2 THEN SET order_status = 'Shipped';
            WHEN 3 THEN SET order_status = 'Delivered';
            ELSE SET order_status = 'Completed';
        END CASE;
        
        INSERT INTO orders (customer_id, order_date, required_date, total_amount, status)
        VALUES (
            ((i % 1000) + 1),
            DATE_SUB(CURDATE(), INTERVAL (i % 365) DAY),
            DATE_ADD(DATE_SUB(CURDATE(), INTERVAL (i % 365) DAY), INTERVAL 7 DAY),
            ROUND((RAND() * 1000 + 50), 2),
            order_status
        );
        
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ;

CALL generate_orders(5000);
DROP PROCEDURE generate_orders;
"

echo "Generating sample order details..."

execute_mysql "
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS generate_order_details(IN num_details INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    
    WHILE i <= num_details DO
        INSERT INTO order_details (order_id, product_id, unit_price, quantity, discount)
        VALUES (
            ((i % 5000) + 1),
            ((i % 15) + 1),
            ROUND((RAND() * 100 + 10), 2),
            ((i % 5) + 1),
            ROUND((RAND() * 0.2), 2)
        );
        
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ;

CALL generate_order_details(15000);
DROP PROCEDURE generate_order_details;
"

echo "Creating views for reporting..."

execute_mysql "
-- Customer Order Summary View
CREATE OR REPLACE VIEW v_customer_order_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    c.country,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_order_value,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city, c.country;

-- Product Sales Summary View
CREATE OR REPLACE VIEW v_product_sales_summary AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(od.order_detail_id) AS times_sold,
    COALESCE(SUM(od.quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0) AS total_revenue,
    COALESCE(AVG(od.unit_price), 0) AS avg_selling_price
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name, c.category_name;

-- Monthly Sales Report View
CREATE OR REPLACE VIEW v_monthly_sales_report AS
SELECT 
    YEAR(o.order_date) AS sales_year,
    MONTH(o.order_date) AS sales_month,
    MONTHNAME(o.order_date) AS month_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value
FROM orders o
WHERE o.order_date IS NOT NULL
GROUP BY YEAR(o.order_date), MONTH(o.order_date), MONTHNAME(o.order_date)
ORDER BY sales_year DESC, sales_month DESC;
"

echo "Analyzing tables for optimization..."
execute_mysql "ANALYZE TABLE customers, orders, order_details, products, categories, employees, departments;"

echo "Database setup completed successfully!"

# Display summary
echo "
==== SETUP SUMMARY ===="
execute_mysql "
SELECT 
    'customers' AS table_name, COUNT(*) AS record_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_details', COUNT(*) FROM order_details
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'departments', COUNT(*) FROM departments;
"

echo "
Sample queries to test:
1. SELECT * FROM v_customer_order_summary WHERE total_orders > 5;
2. SELECT * FROM v_product_sales_summary ORDER BY total_revenue DESC;
3. SELECT * FROM v_monthly_sales_report ORDER BY sales_year DESC, sales_month DESC;
"

echo "Setup completed! Database '$DB_NAME' is ready for use."
