"""
Step 1 - Clean the Stack Overflow 2025 Developer Survey and build:
  - clean_data/respondents.csv   (one row per respondent, cleaned)
  - clean_data/tech_long.csv     (one row per respondent x technology)
  - clean_data/roles_long.csv    (one row per respondent x developer role)
  - stackoverflow_2025.db        (SQLite database with the same 3 tables)

Usage:  python 01_clean_stackoverflow_2025.py survey_results_public.csv
"""
import sys
import sqlite3
from pathlib import Path

import numpy as np
import pandas as pd

RAW = Path(sys.argv[1] if len(sys.argv) > 1 else "survey_results_public.csv")
OUT = Path("clean_data")
OUT.mkdir(exist_ok=True)

# ---------------------------------------------------------------- 1. Load
df = pd.read_csv(RAW, encoding="utf-8-sig", low_memory=False)
print(f"Loaded {df.shape[0]:,} rows x {df.shape[1]} columns")
assert df["ResponseId"].is_unique, "ResponseId should be unique"

# ------------------------------------------------- 2. Keep the core columns
core_cols = [
    "ResponseId", "MainBranch", "Age", "EdLevel", "Employment", "WorkExp",
    "YearsCode", "OrgSize", "RemoteWork", "Industry", "Country",
    "ConvertedCompYearly", "JobSat", "AISelect", "AISent", "AIAcc",
]
missing = [c for c in core_cols if c not in df.columns]
if missing:
    sys.exit(f"Columns not found (check your file): {missing}")
res = df[core_cols].copy()

# ------------------------------------------------------------ 3. Clean text
for c in res.select_dtypes(include=["object", "string"]).columns:
    res[c] = res[c].str.strip()

short_country = {
    "United States of America": "USA",
    "United Kingdom of Great Britain and Northern Ireland": "UK",
    "Russian Federation": "Russia",
    "Iran, Islamic Republic of...": "Iran",
    "Republic of Korea": "South Korea",
    "Viet Nam": "Vietnam",
    "Hong Kong (S.A.R.)": "Hong Kong",
    "United Republic of Tanzania": "Tanzania",
}
res["Country"] = res["Country"].replace(short_country)

res["Industry"] = res["Industry"].replace({"Other:": "Other"})
res["EdLevel"] = res["EdLevel"].replace({
    "Bachelor’s degree (B.A., B.S., B.Eng., etc.)": "Bachelor's",
    "Master’s degree (M.A., M.S., M.Eng., MBA, etc.)": "Master's",
    "Some college/university study without earning a degree": "Some college",
    "Secondary school (e.g. American high school, German Realschule or Gymnasium, etc.)": "Secondary school",
    "Professional degree (JD, MD, Ph.D, Ed.D, etc.)": "Professional/PhD",
    "Associate degree (A.A., A.S., etc.)": "Associate",
    "Primary/elementary school": "Primary school",
    "Other (please specify):": "Other",
})
res["MainBranch"] = res["MainBranch"].replace({
    "I am a developer by profession": "Professional developer",
    "I am not primarily a developer, but I write code sometimes as part of my work/studies": "Codes sometimes",
    "I am learning to code": "Learning to code",
    "I code primarily as a hobby": "Hobbyist",
    "I used to be a developer by profession, but no longer am": "Former developer",
    "I work with developers or my work supports developers but am not a developer by profession": "Supports developers",
})

# ------------------------------------------------------- 4. Numeric fields
for c in ["WorkExp", "YearsCode", "JobSat", "ConvertedCompYearly"]:
    res[c] = pd.to_numeric(res[c], errors="coerce")

# Experience bands (for charts / slicers)
res["ExpBand"] = pd.cut(
    res["WorkExp"], bins=[-1, 2, 5, 10, 20, 100],
    labels=["0-2 yrs", "3-5 yrs", "6-10 yrs", "11-20 yrs", "20+ yrs"],
)

# Age order helper for sorting in Power BI
age_order = {"18-24 years old": 1, "25-34 years old": 2, "35-44 years old": 3,
             "45-54 years old": 4, "55-64 years old": 5, "65 years or older": 6,
             "Prefer not to say": 7}
res["AgeSort"] = res["Age"].map(age_order)

# ------------------------------------------------------ 5. Salary outliers
# Keep raw value, plus a cleaned column: >= $1,000 and <= Q3 + 1.5*IQR
comp = res["ConvertedCompYearly"]
q1, q3 = comp.quantile([0.25, 0.75])
upper = q3 + 1.5 * (q3 - q1)
res["CompOutlier"] = (comp < 1000) | (comp > upper)
res["CompClean"] = comp.where(~res["CompOutlier"] & comp.notna())
print(f"Salary rows: {comp.notna().sum():,} | kept after outlier rule: "
      f"{res['CompClean'].notna().sum():,} (upper bound ${upper:,.0f})")

# --------------------------------------- 6. Long tables for multi-select cols
tech_sources = {
    # (Category, Status): column name
    ("Language", "Used"):  "LanguageHaveWorkedWith",
    ("Language", "Want"):  "LanguageWantToWorkWith",
    ("Database", "Used"):  "DatabaseHaveWorkedWith",
    ("Database", "Want"):  "DatabaseWantToWorkWith",
    ("Platform", "Used"):  "PlatformHaveWorkedWith",
    ("Platform", "Want"):  "PlatformWantToWorkWith",
    ("Web framework", "Used"): "WebframeHaveWorkedWith",
    ("Web framework", "Want"): "WebframeWantToWorkWith",
}

def explode(frame, col):
    out = frame[["ResponseId", col]].dropna()
    out = out.assign(Item=out[col].str.split(";")).explode("Item")
    out["Item"] = out["Item"].str.strip()
    return out[out["Item"] != ""][["ResponseId", "Item"]]

parts = []
for (cat, status), col in tech_sources.items():
    if col not in df.columns:
        print(f"  (skipping {col}: not in file)")
        continue
    t = explode(df, col).rename(columns={"Item": "Technology"})
    t["Category"], t["Status"] = cat, status
    parts.append(t)
tech = pd.concat(parts, ignore_index=True)[["ResponseId", "Category", "Status", "Technology"]]

roles = explode(df, "DevType").rename(columns={"Item": "Role"})

# ---------------------------------------------------------------- 7. Save
res.to_csv(OUT / "respondents.csv", index=False)
tech.to_csv(OUT / "tech_long.csv", index=False)
roles.to_csv(OUT / "roles_long.csv", index=False)

with sqlite3.connect("stackoverflow_2025.db") as con:
    res.to_sql("respondents", con, if_exists="replace", index=False)
    tech.to_sql("tech_long", con, if_exists="replace", index=False)
    roles.to_sql("roles_long", con, if_exists="replace", index=False)
    con.execute("CREATE UNIQUE INDEX IF NOT EXISTS ix_resp_id ON respondents(ResponseId)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_tech_id ON tech_long(ResponseId)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_tech_cat ON tech_long(Category, Status, Technology)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_roles_id ON roles_long(ResponseId)")

print(f"respondents: {len(res):,} | tech_long: {len(tech):,} | roles_long: {len(roles):,}")
print("Done. Files are in ./clean_data and stackoverflow_2025.db")