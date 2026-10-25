-- ============================================================
-- 01_setup_and_import.sql
-- Creates the database and loads the raw Superstore CSV into a
-- flat staging table.
-- Tested against: MySQL 8.4 / MySQL Workbench 8.0
-- ============================================================

CREATE DATABASE IF NOT EXISTS retail_performance_db;
USE retail_performance_db;

DROP TABLE IF EXISTS staging_superstore;

CREATE TABLE staging_superstore (
    row_id        INT,
    order_id      VARCHAR(20),
    order_date    DATE,
    ship_date     DATE,
    ship_mode     VARCHAR(50),
    customer_id   VARCHAR(20),
    customer_name VARCHAR(100),
    segment       VARCHAR(50),
    country       VARCHAR(50),
    city          VARCHAR(100),
    state         VARCHAR(50),
    postal_code   VARCHAR(10),     -- VARCHAR, not INT: keeps leading zeros
    region        VARCHAR(50),
    product_id    VARCHAR(30),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    product_name  VARCHAR(255),
    sales         DECIMAL(10,4),
    quantity      INT,
    discount      DECIMAL(4,2),
    profit        DECIMAL(10,4)
);

-- LOAD DATA INFILE can only read from the folder in secure_file_priv.
-- Copy the CSV into that folder first.
SHOW VARIABLES LIKE 'secure_file_priv';

-- Why not the Table Data Import Wizard?
-- The wizard lost sync on quoted fields containing commas
-- (e.g. "Leather Task Chair, Black") and rejected M/D/YYYY dates.
-- LOAD DATA handles both explicitly.
-- Adjust the path and filename to match your machine.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/Sample - Superstore.csv'
INTO TABLE staging_superstore
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(row_id, order_id, @order_date, @ship_date, ship_mode, customer_id, customer_name,
 segment, country, city, state, postal_code, region, product_id, category,
 sub_category, product_name, sales, quantity, discount, profit)
SET order_date = STR_TO_DATE(@order_date, '%m/%d/%Y'),
    ship_date  = STR_TO_DATE(@ship_date,  '%m/%d/%Y');

-- ---------- Verification ----------
SELECT COUNT(*) AS row_count FROM staging_superstore;                -- expect 9994
SELECT * FROM staging_superstore WHERE row_id = 1360;                -- product_name should read 'Leather Task Chair, Black'
SELECT COUNT(*) AS null_dates
FROM staging_superstore
WHERE order_date IS NULL OR ship_date IS NULL;                       -- expect 0
