# %%
# Step 1: settings and loading the raw data
import numpy as np
import pandas as pd
from pathlib import Path

# CHANGE THIS PATH: the folder that contains the dataset file "Global Health Statistics.csv"
folder = Path(r"D:\OneDrive - Arab Academy for Science and Technology\To Be Developed\07 Depi\05 FInal Project")

raw_file = folder / "Global Health Statistics.csv"
clean_file = folder / "cleaned_data.csv"

df = pd.read_csv(raw_file)
print("Raw shape:", df.shape)

# %%
# Step 2: rename columns to simple names (lowercase, underscores)
rename_map = {
    "Country": "country",
    "Year": "year",
    "Disease Name": "disease_name",
    "Disease Category": "disease_category",
    "Prevalence Rate (%)": "prevalence_rate_pct",
    "Incidence Rate (%)": "incidence_rate_pct",
    "Mortality Rate (%)": "mortality_rate_pct",
    "Age Group": "age_group",
    "Gender": "gender",
    "Population Affected": "population_affected",
    "Healthcare Access (%)": "healthcare_access_pct",
    "Doctors per 1000": "doctors_per_1000",
    "Hospital Beds per 1000": "hospital_beds_per_1000",
    "Treatment Type": "treatment_type",
    "Average Treatment Cost (USD)": "avg_treatment_cost_usd",
    "Availability of Vaccines/Treatment": "treatment_available",
    "Recovery Rate (%)": "recovery_rate_pct",
    "DALYs": "dalys",
    "Improvement in 5 Years (%)": "improvement_5y_pct",
    "Per Capita Income (USD)": "per_capita_income_usd",
    "Education Index": "education_index",
    "Urbanization Rate (%)": "urbanization_rate_pct",
}
df = df.rename(columns=rename_map)
print(df.columns.tolist())

# %%
# Step 3: standardize values
# 3.1 remove spaces around text values (none were found, but this keeps the script reliable)
text_cols = ["country", "disease_name", "disease_category", "age_group",
             "gender", "treatment_type", "treatment_available"]
for col in text_cols:
    df[col] = df[col].str.strip()

# 3.2 convert Yes/No to 1/0
df["treatment_available"] = df["treatment_available"].map({"Yes": 1, "No": 0})
print(df["treatment_available"].value_counts(dropna=False))

# %%
# Step 4: derived columns (created by the team, not part of the original dataset)
# 4.1 disease group: communicable vs. non-communicable
non_communicable = ["Cancer", "Asthma", "Diabetes",
                    "Alzheimer's Disease", "Parkinson's Disease", "Hypertension"]
df["disease_group"] = np.where(df["disease_name"].isin(non_communicable),
                               "Non-communicable", "Communicable")

# 4.2 income band: Low (< 25,000), Middle (25,000 to 74,999), High (75,000 or more)
bins = [0, 25000, 75000, float("inf")]
labels = ["Low", "Middle", "High"]
df["income_band"] = pd.cut(df["per_capita_income_usd"], bins=bins,
                           labels=labels, right=False).astype(str)

print(df["disease_group"].value_counts())
print(df["income_band"].value_counts())

# %%
# Step 5: automatic checks (the script stops with a message if any check fails)
assert df.shape[0] == 1_000_000, "Row count changed"
assert df.isnull().sum().sum() == 0, "There are missing values"
assert df.duplicated().sum() == 0, "There are duplicate rows"
assert df["treatment_available"].isin([0, 1]).all(), "Unexpected treatment_available value"
assert df["disease_group"].nunique() == 2, "disease_group should have 2 values"
assert df["income_band"].nunique() == 3, "income_band should have 3 values"
for col in [c for c in df.columns if c.endswith("_pct")]:
    assert df[col].between(0, 100).all(), col + " is outside 0 to 100"
print("All checks passed")

# %%
# Step 6: save the cleaned data
df.to_csv(clean_file, index=False)
print("Saved:", clean_file)
print("Rows:", len(df), "| Columns:", df.shape[1])
print(df.dtypes)