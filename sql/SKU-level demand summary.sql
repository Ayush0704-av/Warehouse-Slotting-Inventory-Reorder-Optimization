USE retail_slotting_db;

CREATE OR REPLACE VIEW sku_demand_summary AS
SELECT
    stock_code,
    MAX(description)                              AS description,
    COUNT(DISTINCT invoice_no)                     AS order_count,
    SUM(quantity)                                  AS total_quantity,
    ROUND(SUM(quantity * price), 2)                AS total_revenue,
    ROUND(AVG(quantity), 2)                        AS avg_qty_per_order,
    MIN(invoice_date)                              AS first_order_date,
    MAX(invoice_date)                              AS last_order_date
FROM online_retail
WHERE invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND price > 0
  AND stock_code IS NOT NULL
  AND stock_code != ''
  AND stock_code NOT IN ('M', 'DOT', 'POST', 'D', 'C2', 'BANK CHARGES', 'PADS', 'CRUK')
  AND quantity < 5000        -- filters extreme bulk/error rows
GROUP BY stock_code
HAVING order_count >= 2;      -- drop one-off SKUs (need history for XYZ variability anyway)

SELECT COUNT(*) FROM sku_demand_summary;

SELECT * FROM sku_demand_summary
ORDER BY total_revenue DESC
LIMIT 10;