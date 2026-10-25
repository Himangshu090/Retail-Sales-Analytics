-- ============================================================
-- 04_stored_procedures.sql
-- Reusable reporting procedures built on vw_orders_enriched.
-- ============================================================

USE retail_performance_db;

DROP PROCEDURE IF EXISTS GetRegionalPerformance;
DROP PROCEDURE IF EXISTS GetSalesByDateRange;

DELIMITER //

-- Sales, profit, margin and order count per region
CREATE PROCEDURE GetRegionalPerformance()
BEGIN
    SELECT
        region,
        SUM(sales)                                 AS total_sales,
        SUM(profit)                                AS total_profit,
        ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
        COUNT(DISTINCT order_id)                   AS total_orders
    FROM vw_orders_enriched
    GROUP BY region
    ORDER BY total_sales DESC;
END //

-- Category performance for any date range
CREATE PROCEDURE GetSalesByDateRange(
    IN start_date DATE,
    IN end_date   DATE
)
BEGIN
    SELECT
        category,
        SUM(sales)               AS total_sales,
        SUM(profit)              AS total_profit,
        COUNT(DISTINCT order_id) AS total_orders
    FROM vw_orders_enriched
    WHERE order_date BETWEEN start_date AND end_date
    GROUP BY category
    ORDER BY total_sales DESC;
END //

DELIMITER ;

-- Example calls
CALL GetRegionalPerformance();
CALL GetSalesByDateRange('2017-01-01', '2017-12-31');
