CREATE OR REPLACE VIEW sku_monthly_demand AS
SELECT
    stock_code,
    DATE_FORMAT(invoice_date, '%Y-%m') AS order_month,
    SUM(quantity) AS monthly_qty
FROM online_retail
WHERE invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND price > 0
  AND stock_code IS NOT NULL
  AND stock_code != ''
  AND stock_code NOT IN ('M', 'DOT', 'POST', 'D', 'C2', 'BANK CHARGES', 'PADS', 'CRUK')
  AND quantity < 5000
GROUP BY stock_code, DATE_FORMAT(invoice_date, '%Y-%m');

CREATE OR REPLACE VIEW xyz_classification AS
SELECT
    stock_code,
    COUNT(*)              AS active_months,
    ROUND(AVG(monthly_qty), 2)   AS avg_monthly_qty,
    ROUND(STDDEV(monthly_qty), 2) AS stddev_monthly_qty,
    ROUND(STDDEV(monthly_qty) / AVG(monthly_qty), 3) AS cv,
    CASE
        WHEN STDDEV(monthly_qty) / AVG(monthly_qty) < 0.5 THEN 'X'
        WHEN STDDEV(monthly_qty) / AVG(monthly_qty) < 1.0 THEN 'Y'
        ELSE 'Z'
    END AS xyz_class
FROM sku_monthly_demand
GROUP BY stock_code
HAVING active_months >= 3;   -- need at least 3 months of activity for a meaningful CV

SELECT xyz_class, COUNT(*) AS sku_count
FROM xyz_classification
GROUP BY xyz_class
ORDER BY xyz_class;