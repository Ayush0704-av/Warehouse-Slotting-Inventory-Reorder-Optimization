import pandas as pd
import numpy as np
from scipy.stats import norm
from sqlalchemy import create_engine
import hashlib

mysql_password = "12345 "   # <-- put your actual MySQL password here
engine = create_engine(f"mysql+mysqlconnector://root:{12345}@127.0.0.1:3306/retail_slotting_db")

# Pull monthly demand per SKU (need mean + std dev of demand)
query = """
SELECT stock_code, order_month, monthly_qty
FROM sku_monthly_demand
"""
df = pd.read_sql(query, engine)

# Convert monthly qty to daily average (approx 30 days/month)
stats = df.groupby("stock_code")["monthly_qty"].agg(["mean", "std", "count"]).reset_index()
stats.columns = ["stock_code", "avg_monthly_demand", "stddev_monthly_demand", "active_months"]
stats = stats[stats["active_months"] >= 3]  # same filter as XYZ, need real variability

stats["avg_daily_demand"] = stats["avg_monthly_demand"] / 30
stats["stddev_daily_demand"] = stats["stddev_monthly_demand"].fillna(0) / np.sqrt(30)

# Assumptions (state these clearly in your project write-up)
LEAD_TIME_DAYS = 7          # assumed supplier lead time
SERVICE_LEVEL = 0.95        # 95% service level
Z_SCORE = norm.ppf(SERVICE_LEVEL)   # ~1.65

stats["safety_stock"] = (Z_SCORE * stats["stddev_daily_demand"] * np.sqrt(LEAD_TIME_DAYS)).round(0)
stats["reorder_point"] = (stats["avg_daily_demand"] * LEAD_TIME_DAYS + stats["safety_stock"]).round(0)

print(stats[["stock_code","avg_daily_demand","safety_stock","reorder_point"]].head(10))
print(f"\nTotal SKUs with reorder points calculated: {len(stats)}")

# --- Simulate current stock level and flag critical (below reorder point) SKUs ---
def sim_stock(code, reorder_point):
    h = int(hashlib.md5(code.encode()).hexdigest(), 16)
    factor = 0.4 + (h % 100) / 100 * 1.2   # spread stock from 40% to 160% of reorder point
    return round(reorder_point * factor)

stats["current_stock"] = stats.apply(lambda r: sim_stock(r["stock_code"], r["reorder_point"]), axis=1)
stats["stock_status"] = stats.apply(lambda r: "CRITICAL" if r["current_stock"] < r["reorder_point"] else "OK", axis=1)

print(f"\nCritical SKUs (below reorder point): {(stats['stock_status'] == 'CRITICAL').sum()}")

stats.to_sql("reorder_point_analysis", con=engine, if_exists="replace", index=False)
print("Saved reorder_point_analysis table to MySQL for Power BI.")