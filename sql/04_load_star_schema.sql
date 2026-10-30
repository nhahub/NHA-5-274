-- 04_load_star_schema.sql
-- Fills the dimension tables and the fact table from the staging table
-- Run 02_create_tables.sql and 03_load_staging.sql first.
-- To reload from scratch: run 02, then 03, then this script.
USE GlobalHealthDB;
GO

-- Dimension tables
INSERT INTO dbo.dim_country (country_name)
SELECT DISTINCT country FROM dbo.stg_global_health ORDER BY country;

INSERT INTO dbo.dim_disease (disease_name, disease_group)
SELECT DISTINCT disease_name, disease_group FROM dbo.stg_global_health ORDER BY disease_name;

INSERT INTO dbo.dim_disease_category (category_name)
SELECT DISTINCT disease_category FROM dbo.stg_global_health ORDER BY disease_category;

INSERT INTO dbo.dim_age_group (age_group_label, sort_order)
VALUES (N'0-18', 1), (N'19-35', 2), (N'36-60', 3), (N'61+', 4);

INSERT INTO dbo.dim_gender (gender_name)
SELECT DISTINCT gender FROM dbo.stg_global_health ORDER BY gender;

INSERT INTO dbo.dim_treatment_type (treatment_type_name)
SELECT DISTINCT treatment_type FROM dbo.stg_global_health ORDER BY treatment_type;

INSERT INTO dbo.dim_year ([year], decade)
SELECT DISTINCT [year], ([year] / 10) * 10 FROM dbo.stg_global_health ORDER BY [year];

INSERT INTO dbo.dim_income_band (band_name, min_income, max_income)
VALUES (N'Low', 0, 24999), (N'Middle', 25000, 74999), (N'High', 75000, 100000);
GO

-- Fact table: replace each text value with the key of its dimension row
INSERT INTO dbo.fact_health_stats (
    country_id, disease_id, disease_category_id, age_group_id, gender_id,
    treatment_type_id, [year], income_band_id,
    prevalence_rate_pct, incidence_rate_pct, mortality_rate_pct, population_affected,
    healthcare_access_pct, doctors_per_1000, hospital_beds_per_1000,
    avg_treatment_cost_usd, treatment_available, recovery_rate_pct, dalys,
    improvement_5y_pct, per_capita_income_usd, education_index, urbanization_rate_pct
)
SELECT
    c.country_id, d.disease_id, dc.disease_category_id, ag.age_group_id, g.gender_id,
    t.treatment_type_id, s.[year], ib.income_band_id,
    s.prevalence_rate_pct, s.incidence_rate_pct, s.mortality_rate_pct, s.population_affected,
    s.healthcare_access_pct, s.doctors_per_1000, s.hospital_beds_per_1000,
    s.avg_treatment_cost_usd, s.treatment_available, s.recovery_rate_pct, s.dalys,
    s.improvement_5y_pct, s.per_capita_income_usd, s.education_index, s.urbanization_rate_pct
FROM dbo.stg_global_health AS s
JOIN dbo.dim_country          AS c  ON c.country_name        = s.country
JOIN dbo.dim_disease          AS d  ON d.disease_name        = s.disease_name
JOIN dbo.dim_disease_category AS dc ON dc.category_name      = s.disease_category
JOIN dbo.dim_age_group        AS ag ON ag.age_group_label    = s.age_group
JOIN dbo.dim_gender           AS g  ON g.gender_name         = s.gender
JOIN dbo.dim_treatment_type   AS t  ON t.treatment_type_name = s.treatment_type
JOIN dbo.dim_income_band      AS ib ON ib.band_name          = s.income_band;
GO

-- Check 1: fact rows (expected 1,000,000)
SELECT COUNT(*) AS fact_rows FROM dbo.fact_health_stats;

-- Check 2: dimension row counts (expected: 20, 20, 11, 4, 3, 4, 25, 3)
SELECT 'dim_country' AS table_name, COUNT(*) AS row_count FROM dbo.dim_country
UNION ALL SELECT 'dim_disease', COUNT(*) FROM dbo.dim_disease
UNION ALL SELECT 'dim_disease_category', COUNT(*) FROM dbo.dim_disease_category
UNION ALL SELECT 'dim_age_group', COUNT(*) FROM dbo.dim_age_group
UNION ALL SELECT 'dim_gender', COUNT(*) FROM dbo.dim_gender
UNION ALL SELECT 'dim_treatment_type', COUNT(*) FROM dbo.dim_treatment_type
UNION ALL SELECT 'dim_year', COUNT(*) FROM dbo.dim_year
UNION ALL SELECT 'dim_income_band', COUNT(*) FROM dbo.dim_income_band;

-- Check 3: the total must be identical in staging and fact
SELECT
    (SELECT SUM(CAST(population_affected AS BIGINT)) FROM dbo.stg_global_health) AS staging_sum,
    (SELECT SUM(CAST(population_affected AS BIGINT)) FROM dbo.fact_health_stats) AS fact_sum;