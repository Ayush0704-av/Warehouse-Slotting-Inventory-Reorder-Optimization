CREATE OR REPLACE VIEW abc_classification AS
WITH ranked AS (
    SELECT
        stock_code,
        description,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        SUM(total_revenue) OVER ()                             AS grand_total
    FROM sku_demand_summary
)
SELECT
    stock_code,
    description,
    total_revenue,
    ROUND(running_total / grand_total * 100, 2) AS cumulative_pct,
    CASE
        WHEN running_total / grand_total <= 0.80 THEN 'A'
        WHEN running_total / grand_total <= 0.95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM ranked;

SELECT abc_class, COUNT(*) AS sku_count, ROUND(SUM(total_revenue),2) AS revenue
FROM abc_classification
GROUP BY abc_class
ORDER BY abc_class;