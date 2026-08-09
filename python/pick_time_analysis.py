import pandas as pd
from sqlalchemy import create_engine

mysql_password = "YOUR_PASSWORD_HERE"
engine = create_engine(f"mysql+mysqlconnector://root:{12345}@127.0.0.1:3306/retail_slotting_db")

# Pull misplaced SKUs with their order frequency
query = """
SELECT
    sm.stock_code,
    sm.description,
    sm.abc_xyz_class,
    sm.current_zone,
    sm.distance_from_dock_m,
    sm.placement_status,
    sd.order_count
FROM slotting_misplacement sm
JOIN sku_demand_summary sd ON sm.stock_code = sd.stock_code
WHERE sm.abc_xyz_class IN ('AX','AY','BX')
"""
df = pd.read_sql(query, engine)

# Assumption: walking speed ~1.2 m/s, plus fixed 5 sec pick/search overhead
WALK_SPEED_M_PER_SEC = 1.2
FIXED_PICK_SEC = 5

df["time_per_pick_sec"] = (df["distance_from_dock_m"] / WALK_SPEED_M_PER_SEC) + FIXED_PICK_SEC

# If it were in fast_pick zone instead, assume a baseline distance of ~15m (near dock)
BASELINE_FAST_PICK_DISTANCE = 15
df["ideal_time_per_pick_sec"] = (BASELINE_FAST_PICK_DISTANCE / WALK_SPEED_M_PER_SEC) + FIXED_PICK_SEC

df["extra_sec_per_pick"] = df["time_per_pick_sec"] - df["ideal_time_per_pick_sec"]
df["extra_sec_per_pick"] = df["extra_sec_per_pick"].clip(lower=0)

df["total_extra_time_sec"] = df["extra_sec_per_pick"] * df["order_count"]

misplaced = df[df["placement_status"] == "MISPLACED"]

total_extra_hours = misplaced["total_extra_time_sec"].sum() / 3600
total_picks = misplaced["order_count"].sum()

print(f"Misplaced SKUs: {len(misplaced)}")
print(f"Total extra picking time (all-time): {total_extra_hours:.1f} hours")
print(f"Total affected picks: {total_picks}")
print(f"Avg extra seconds per pick: {misplaced['extra_sec_per_pick'].mean():.1f} sec")

misplaced.to_sql("misplaced_skus_analysis", con=engine, if_exists="replace", index=False)
print("Saved misplaced_skus_analysis table to MySQL for Power BI.")