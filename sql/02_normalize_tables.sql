-- ============================================================
-- 02_normalize_tables.sql
-- Splits the flat staging table into customers, orders, returns.
-- ============================================================

USE retail_performance_db;

-- ---------- customers ----------
-- Only attributes that are genuinely fixed per customer live here.
-- City / state / postal_code / region VARY per order for the same
-- customer_id (they describe the shipping address), so they belong
-- in the orders table, not here.
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment       VARCHAR(50),
    country       VARCHAR(50)
);

INSERT INTO customers (customer_id, customer_name, segment, country)
SELECT DISTINCT customer_id, customer_name, segment, country
FROM staging_superstore;

SELECT COUNT(*) AS customer_count FROM customers;                    -- 794 in this dataset


-- ---------- orders (fact table) ----------
-- row_id is unique per line item. order_id repeats on purpose:
-- one order can contain several products.
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    row_id       INT PRIMARY KEY,
    order_id     VARCHAR(20),
    order_date   DATE,
    ship_date    DATE,
    ship_mode    VARCHAR(50),
    customer_id  VARCHAR(20),
    city         VARCHAR(100),
    state        VARCHAR(50),
    postal_code  VARCHAR(10),
    region       VARCHAR(50),
    product_id   VARCHAR(30),
    category     VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales        DECIMAL(10,4),
    quantity     INT,
    discount     DECIMAL(4,2),
    profit       DECIMAL(10,4),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO orders
    (row_id, order_id, order_date, ship_date, ship_mode, customer_id,
     city, state, postal_code, region,
     product_id, category, sub_category, product_name,
     sales, quantity, discount, profit)
SELECT
     row_id, order_id, order_date, ship_date, ship_mode, customer_id,
     city, state, postal_code, region,
     product_id, category, sub_category, product_name,
     sales, quantity, discount, profit
FROM staging_superstore;

SELECT COUNT(*) AS order_line_count FROM orders;                     -- expect 9994
SELECT COUNT(DISTINCT order_id) AS unique_orders FROM orders;        -- 5009 in this dataset


-- ---------- returns (SIMULATED) ----------
-- The Superstore dataset contains no return information, so a random
-- sample of order IDs is flagged as returned for demonstration only.
-- ORDER BY RAND() gives a different sample on every run, so the exact
-- return rate will vary slightly between runs.
--
-- No foreign key to orders: MySQL requires the referenced column to be
-- unique, and orders.order_id is intentionally not unique
-- (Error 6125 if you try). The relationship is enforced through the
-- LEFT JOIN in the view instead.
DROP TABLE IF EXISTS returns;

CREATE TABLE returns (
    order_id VARCHAR(20) PRIMARY KEY,
    returned VARCHAR(5) DEFAULT 'Yes'
);

INSERT INTO returns (order_id)
SELECT DISTINCT order_id
FROM orders
ORDER BY RAND()
LIMIT 450;

SELECT
    (SELECT COUNT(*) FROM returns)                  AS returned_orders,
    (SELECT COUNT(DISTINCT order_id) FROM orders)   AS total_orders,
    ROUND((SELECT COUNT(*) FROM returns) * 100.0
          / (SELECT COUNT(DISTINCT order_id) FROM orders), 2) AS return_rate_pct;   -- about 8.98
