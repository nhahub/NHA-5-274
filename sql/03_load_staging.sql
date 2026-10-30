-- 03_load_staging.sql
-- Loads cleaned_data.csv into the staging table and checks the result
USE GlobalHealthDB;
GO

-- Empty the staging table so the script can be re-run
TRUNCATE TABLE dbo.stg_global_health;
GO

-- CHANGE THIS PATH if you saved the file somewhere else
BULK INSERT dbo.stg_global_health
FROM 'D:\SQL_Import\cleaned_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

-- Check 1: total rows (expected 1,000,000)
SELECT COUNT(*) AS total_rows FROM dbo.stg_global_health;

-- Check 2: treatment_available (expected: 1 = 500,354 and 0 = 499,646)
SELECT treatment_available, COUNT(*) AS rows_count
FROM dbo.stg_global_health
GROUP BY treatment_available;

-- Check 3: disease_group (expected: Communicable 700,651 and Non-communicable 299,349)
SELECT disease_group, COUNT(*) AS rows_count
FROM dbo.stg_global_health
GROUP BY disease_group;

-- Check 4: income_band (expected: Middle 502,612, High 251,921, Low 245,467; text length 6, 4, 3)
SELECT income_band, LEN(income_band) AS text_length, COUNT(*) AS rows_count
FROM dbo.stg_global_health
GROUP BY income_band;