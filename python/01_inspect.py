# %%
import pandas as pd
from pathlib import Path

# CHANGE THIS PATH: the folder that contains the dataset file "Global Health Statistics.csv"
folder = Path(r"D:\OneDrive - Arab Academy for Science and Technology\To Be Developed\07 Depi\05 FInal Project")

# 2) اسم الملف الكامل
file_path = folder / "Global Health Statistics.csv"

# 3) نعرض كل الأعمدة لما نطبع جدول (وإلا pandas بيخفي بعضها)
pd.set_option("display.max_columns", None)

# 4) نتأكد إن الملف موجود
print("File exists:", file_path.exists())

# %%
df = pd.read_csv(file_path)
print("Done loading")

# %%
print(df.shape)                 # (عدد الصفوف, عدد الأعمدة)
print(df.columns.tolist())      # أسماء الأعمدة
df.info(memory_usage="deep")    # نوع كل عمود، وعدد القيم غير الفاضية، والذاكرة

# %%
df.head()

# %%
# عدد الصفوف المتكررة بالكامل (نفس القيم في كل الأعمدة)
print("Duplicate rows:", df.duplicated().sum())

# عدد القيم المختلفة في كل عمود
print(df.nunique())

# %%
cat_cols = [
    "Country",
    "Disease Name",
    "Disease Category",
    "Age Group",
    "Gender",
    "Treatment Type",
    "Availability of Vaccines/Treatment",
]

for col in cat_cols:
    print("=== ", col, " ===")
    print(df[col].value_counts())
    print()
    
# %%
# نعرض الأرقام بشكل عادي بدل الصيغة العلمية
pd.set_option("display.float_format", "{:,.2f}".format)
pd.set_option("display.width", 200)

print(df.describe().T)

# %%
for col in cat_cols:
    n_spaces = (df[col] != df[col].str.strip()).sum()
    print(col, "-> values with extra spaces:", n_spaces)
# %%
# كل مرض ظاهر تحت كام تصنيف مختلف؟
print(df.groupby("Disease Name")["Disease Category"].nunique())

# نفس الدولة ونفس السنة: كام قيمة دخل مختلفة؟
income_check = df.groupby(["Country", "Year"])["Per Capita Income (USD)"].nunique()
print(income_check.describe())

# %%
import numpy as np

# كل الأعمدة الرقمية ما عدا السنة
num_cols = df.select_dtypes(include="number").columns.drop("Year")

# جدول الارتباط: كل رقم بين -1 و +1 (صفر يعني مفيش علاقة)
corr = df[num_cols].corr()
print(corr.round(3))

# أكبر ارتباط (بالقيمة المطلقة) بين عمودين مختلفين
mask = ~np.eye(len(corr), dtype=bool)
print()
print("Max absolute correlation between different columns:",
      round(corr.abs().where(mask).max().max(), 4))

# %%
cols = ["Mortality Rate (%)", "Recovery Rate (%)", "Average Treatment Cost (USD)"]

print("=== Average by Country ===")
print(df.groupby("Country")[cols].mean().round(2).sort_values("Mortality Rate (%)"))

print()
print("=== Average by Disease ===")
print(df.groupby("Disease Name")[cols].mean().round(2).sort_values("Mortality Rate (%)"))

print()
print("=== Average Mortality by Year ===")
print(df.groupby("Year")["Mortality Rate (%)"].mean().round(3))