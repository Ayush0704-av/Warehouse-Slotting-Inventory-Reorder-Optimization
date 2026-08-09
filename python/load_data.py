import pandas as pd
from sqlalchemy import create_engine

# ---- CONFIG ----
csv_path = r"C:\Users\vayus\OneDrive\Desktop\placements\1. non tech\projects\project-3(inventory reorder optimization)\raw\online_retail_II.csv"
mysql_password = "YOUR_PASSWORD_HERE"   # <-- replace with your actual MySQL root password

engine = create_engine(f"mysql+mysqlconnector://root:{12345}@127.0.0.1:3306/retail_slotting_db")

# ---- LOAD ----
print("Reading CSV...")
df = pd.read_csv(csv_path, encoding="ISO-8859-1")

print("Columns found:", df.columns.tolist())
print("Row count:", len(df))

# Rename columns to match our MySQL table
df.columns = ["invoice_no", "stock_code", "description", "quantity",
              "invoice_date", "price", "customer_id", "country"]

df["invoice_date"] = pd.to_datetime(df["invoice_date"], errors="coerce")

print("Inserting into MySQL (this may take a minute for ~1M rows)...")
df.to_sql("online_retail", con=engine, if_exists="append", index=False, chunksize=10000)

print("Done.")