CREATE OR REPLACE VIEW abc_xyz_matrix AS
SELECT
    a.stock_code,
    a.description,
    a.total_revenue,
    a.abc_class,
    x.avg_monthly_qty,
    x.cv,
    x.xyz_class,
    CONCAT(a.abc_class, x.xyz_class) AS abc_xyz_class
FROM abc_classification a
JOIN xyz_classification x ON a.stock_code = x.stock_code;

SELECT abc_xyz_class, COUNT(*) AS sku_count, ROUND(SUM(total_revenue),2) AS revenue
FROM abc_xyz_matrix
GROUP BY abc_xyz_class
ORDER BY abc_xyz_class;