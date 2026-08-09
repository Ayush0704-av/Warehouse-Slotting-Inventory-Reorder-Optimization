TRUNCATE TABLE sku_zone_mapping;

INSERT INTO sku_zone_mapping (stock_code, zone_id, zone_type, distance_from_dock_m)
SELECT
    s.stock_code,
    CONCAT('Z', MOD(CRC32(s.stock_code), 10) + 1) AS zone_id,
    CASE
        WHEN m.abc_xyz_class IN ('AX','AY','BX') THEN
            CASE
                WHEN MOD(CRC32(s.stock_code), 100) < 82 THEN 'fast_pick'
                WHEN MOD(CRC32(s.stock_code), 100) < 88 THEN 'medium_pick'
                WHEN MOD(CRC32(s.stock_code), 100) < 94 THEN 'slow_pick'
                ELSE 'bulk_storage'
            END
        ELSE
            CASE
                WHEN MOD(CRC32(s.stock_code), 4) = 0 THEN 'fast_pick'
                WHEN MOD(CRC32(s.stock_code), 4) = 1 THEN 'medium_pick'
                WHEN MOD(CRC32(s.stock_code), 4) = 2 THEN 'slow_pick'
                ELSE 'bulk_storage'
            END
    END AS zone_type,
    10 + MOD(CRC32(s.stock_code), 90) AS distance_from_dock_m
FROM sku_demand_summary s
LEFT JOIN abc_xyz_matrix m ON s.stock_code = m.stock_code;

CREATE OR REPLACE VIEW slotting_misplacement AS
SELECT
    m.stock_code,
    m.description,
    m.abc_xyz_class,
    m.total_revenue,
    x.avg_monthly_qty,
    z.zone_type AS current_zone,
    z.distance_from_dock_m,
    CASE
        WHEN m.abc_xyz_class IN ('AX','AY','BX') AND z.zone_type != 'fast_pick'
            THEN 'MISPLACED'
        ELSE 'OK'
    END AS placement_status
FROM abc_xyz_matrix m
JOIN xyz_classification x ON m.stock_code = x.stock_code
JOIN sku_zone_mapping z ON m.stock_code = z.stock_code;

SELECT placement_status, COUNT(*) AS sku_count
FROM slotting_misplacement
WHERE abc_xyz_class IN ('AX','AY','BX')
GROUP BY placement_status;