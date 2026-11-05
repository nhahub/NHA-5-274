# 03_eda.py
# Exploratory data analysis: reads cleaned_data.csv and saves 8 charts in the folder "eda_outputs"
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter
from pathlib import Path

# CHANGE THIS PATH: the folder that contains cleaned_data.csv
folder = Path(r"D:\OneDrive - Arab Academy for Science and Technology\To Be Developed\07 Depi\05 FInal Project")

out = folder / "eda_outputs"
out.mkdir(exist_ok=True)

df = pd.read_csv(folder / "cleaned_data.csv")
print("Loaded:", df.shape)

BLUE = "#1f4e79"
ORANGE = "#c55a11"
NOTE = "Synthetic dataset: for methodology demonstration"
THOUSANDS = StrMethodFormatter("{x:,.0f}")


def finish(fig, name):
    """Adds the synthetic-data note, saves the chart, and shows it."""
    fig.text(0.5, -0.03, NOTE, ha="center", fontsize=9, color="gray")
    fig.savefig(out / name, dpi=150, bbox_inches="tight")
    plt.show()
    print("Saved:", name)


# %%
# Chart 1: distributions of six key numeric columns
cols = ["prevalence_rate_pct", "mortality_rate_pct", "healthcare_access_pct",
        "per_capita_income_usd", "doctors_per_1000", "dalys"]
titles = ["Prevalence rate (%)", "Mortality rate (%)", "Healthcare access (%)",
          "Per capita income (USD)", "Doctors per 1000", "DALYs"]

fig, axes = plt.subplots(2, 3, figsize=(13, 7))
for ax, col, title in zip(axes.flat, cols, titles):
    ax.hist(df[col], bins=40, color=BLUE, edgecolor="white")
    ax.set_title(title)
    ax.set_xlabel(title)
    ax.set_ylabel("Number of records")
    ax.set_ylim(bottom=0)
    ax.yaxis.set_major_formatter(THOUSANDS)
fig.suptitle("Distribution of key numeric columns (a flat shape means evenly spread values)", fontsize=14)
fig.tight_layout()
finish(fig, "eda_01_distributions.png")

# %%
# Chart 2: number of records by country
counts = df["country"].value_counts().sort_values(ascending=False)

fig, ax = plt.subplots(figsize=(12, 5.5))
ax.bar(counts.index, counts.values, color=BLUE)
ax.set_title("Number of records by country")
ax.set_xlabel("Country")
ax.set_ylabel("Number of records")
ax.set_ylim(bottom=0)
ax.yaxis.set_major_formatter(THOUSANDS)
plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
fig.tight_layout()
finish(fig, "eda_02_records_by_country.png")

# %%
# Chart 3: number of records by disease
counts = df["disease_name"].value_counts().sort_values(ascending=True)

fig, ax = plt.subplots(figsize=(10, 7))
ax.barh(counts.index, counts.values, color=BLUE)
ax.set_title("Number of records by disease")
ax.set_xlabel("Number of records")
ax.set_ylabel("Disease")
ax.set_xlim(left=0)
ax.xaxis.set_major_formatter(THOUSANDS)
fig.tight_layout()
finish(fig, "eda_03_records_by_disease.png")

# %%
# Chart 4: average mortality rate by year (the axis starts at 0 so small changes are not exaggerated)
yearly = df.groupby("year")["mortality_rate_pct"].mean()

fig, ax = plt.subplots(figsize=(11, 5.5))
ax.plot(yearly.index, yearly.values, color=BLUE, marker="o")
ax.set_title("Average mortality rate by year")
ax.set_xlabel("Year")
ax.set_ylabel("Average mortality rate (%)")
ax.set_ylim(0, 10)
ax.text(0.02, 0.92, "Yearly averages range from {:.2f} to {:.2f}".format(yearly.min(), yearly.max()),
        transform=ax.transAxes, fontsize=10, color=ORANGE)
fig.tight_layout()
finish(fig, "eda_04_mortality_by_year.png")

# %%
# Chart 5: correlation heatmap (values close to 0 mean no linear relationship)
num = df.select_dtypes(include="number").drop(columns=["year"])
corr = num.corr()
mask = ~np.eye(len(corr), dtype=bool)
print("Largest absolute correlation between two different columns:", round(corr.abs().where(mask).max().max(), 4))

fig, ax = plt.subplots(figsize=(11, 9))
im = ax.imshow(corr.values, cmap="coolwarm", vmin=-1, vmax=1)
ax.set_xticks(range(len(corr.columns)))
ax.set_yticks(range(len(corr.columns)))
ax.set_xticklabels(corr.columns, rotation=60, ha="right", fontsize=8)
ax.set_yticklabels(corr.columns, fontsize=8)
for i in range(len(corr.columns)):
    for j in range(len(corr.columns)):
        ax.text(j, i, "{:.2f}".format(corr.values[i, j]), ha="center", va="center", fontsize=6,
                color="white" if abs(corr.values[i, j]) > 0.5 else "black")
fig.colorbar(im, ax=ax, label="Correlation (-1 to +1)")
ax.set_title("Correlation between numeric columns")
fig.tight_layout()
finish(fig, "eda_05_correlation_heatmap.png")

# %%
# Chart 6: mortality and recovery by disease group
grp = df.groupby("disease_group")[["mortality_rate_pct", "recovery_rate_pct"]].mean()

fig, axes = plt.subplots(1, 2, figsize=(11, 5))
for ax, col, title, color in zip(axes, ["mortality_rate_pct", "recovery_rate_pct"],
                                 ["Average mortality rate (%)", "Average recovery rate (%)"],
                                 [BLUE, ORANGE]):
    bars = ax.bar(grp.index, grp[col], color=color)
    ax.set_title(title)
    ax.set_xlabel("Disease group")
    ax.set_ylabel(title)
    ax.set_ylim(bottom=0)
    ax.bar_label(bars, fmt="%.2f", padding=3)
fig.suptitle("Mortality and recovery by disease group", fontsize=14)
fig.tight_layout()
finish(fig, "eda_06_disease_group.png")

# %%
# Chart 7: average treatment cost by treatment type
cost = df.groupby("treatment_type")["avg_treatment_cost_usd"].mean().sort_values(ascending=False)

fig, ax = plt.subplots(figsize=(9, 5.5))
bars = ax.bar(cost.index, cost.values, color=BLUE)
ax.set_title("Average treatment cost by treatment type")
ax.set_xlabel("Treatment type")
ax.set_ylabel("Average treatment cost (USD)")
ax.set_ylim(bottom=0)
ax.yaxis.set_major_formatter(THOUSANDS)
ax.bar_label(bars, fmt="{:,.0f}", padding=3)
fig.tight_layout()
finish(fig, "eda_07_treatment_cost.png")

# %%
# Chart 8: number of records by income band
order = ["Low", "Middle", "High"]
counts = df["income_band"].value_counts().reindex(order)

fig, ax = plt.subplots(figsize=(8, 5.5))
bars = ax.bar(counts.index, counts.values, color=BLUE)
ax.set_title("Number of records by income band")
ax.set_xlabel("Income band (Low: under 25,000 | Middle: 25,000 to 74,999 | High: 75,000 or more, USD)")
ax.set_ylabel("Number of records")
ax.set_ylim(bottom=0)
ax.yaxis.set_major_formatter(THOUSANDS)
ax.bar_label(bars, fmt="{:,.0f}", padding=3)
fig.tight_layout()
finish(fig, "eda_08_income_bands.png")

print("Done. Charts are in:", out)