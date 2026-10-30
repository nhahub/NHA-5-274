-- 06_views.sql
-- Views for Tableau, validation, and general inspection
USE GlobalHealthDB;
GO

-- View 1: every record with the dimension names (1,000,000 rows)
CREATE OR ALTER VIEW dbo.vw_health_detail AS
SELECT
    f.health_stat_id,
    c.country_name,
    f.[year],
    d.disease_name,
    d.disease_group,
    dc.category_name AS disease_category,
    ag.age_group_label AS age_group,
    g.gender_name AS gender,
    t.treatment_type_name AS treatment_type,
    ib.band_name AS income_band,
    f.prevalence_rate_pct,
    f.incidence_rate_pct,
    f.mortality_rate_pct,
    f.population_affected,
    f.healthcare_access_pct,
    f.doctors_per_1000,
    f.hospital_beds_per_1000,
    f.avg_treatment_cost_usd,
    f.treatment_available,
    f.recovery_rate_pct,
    f.dalys,
    f.improvement_5y_pct,
    f.per_capita_income_usd,
    f.education_index,
    f.urbanization_rate_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_country          AS c  ON c.country_id           = f.country_id
JOIN dbo.dim_disease          AS d  ON d.disease_id           = f.disease_id
JOIN dbo.dim_disease_category AS dc ON dc.disease_category_id = f.disease_category_id
JOIN dbo.dim_age_group        AS ag ON ag.age_group_id        = f.age_group_id
JOIN dbo.dim_gender           AS g  ON g.gender_id            = f.gender_id
JOIN dbo.dim_treatment_type   AS t  ON t.treatment_type_id    = f.treatment_type_id
JOIN dbo.dim_income_band      AS ib ON ib.income_band_id      = f.income_band_id;
GO

-- View 2: aggregated data for Tableau Public (the free version reads files only)
-- Averages in Tableau = SUM(sum_...) / SUM(record_count), which equals the row-level average.
CREATE OR ALTER VIEW dbo.vw_tableau_base AS
SELECT
    c.country_name AS country,
    f.[year] AS [year],
    d.disease_name,
    d.disease_group,
    ag.age_group_label AS age_group,
    ag.sort_order AS age_group_order,
    g.gender_name AS gender,
    t.treatment_type_name AS treatment_type,
    COUNT(*) AS record_count,
    SUM(CAST(f.population_affected AS BIGINT)) AS sum_population_affected,
    SUM(CAST(f.dalys AS BIGINT)) AS sum_dalys,
    SUM(CAST(f.prevalence_rate_pct AS DECIMAL(18,2))) AS sum_prevalence_rate_pct,
    SUM(CAST(f.mortality_rate_pct AS DECIMAL(18,2))) AS sum_mortality_rate_pct,
    SUM(CAST(f.recovery_rate_pct AS DECIMAL(18,2))) AS sum_recovery_rate_pct,
    SUM(CAST(f.avg_treatment_cost_usd AS BIGINT)) AS sum_treatment_cost_usd
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_country        AS c  ON c.country_id        = f.country_id
JOIN dbo.dim_disease        AS d  ON d.disease_id        = f.disease_id
JOIN dbo.dim_age_group      AS ag ON ag.age_group_id     = f.age_group_id
JOIN dbo.dim_gender         AS g  ON g.gender_id         = f.gender_id
JOIN dbo.dim_treatment_type AS t  ON t.treatment_type_id = f.treatment_type_id
GROUP BY c.country_name, f.[year], d.disease_name, d.disease_group,
         ag.age_group_label, ag.sort_order, g.gender_name, t.treatment_type_name;
GO

-- View 3: fixed set of metrics used to validate figures across Python, SQL, Power BI, and Tableau
CREATE OR ALTER VIEW dbo.vw_validation_metrics AS
SELECT 'V01' AS metric_id, 'Total records' AS metric_name,
       CAST(COUNT_BIG(*) AS DECIMAL(38,4)) AS metric_value
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V02', 'Sum of population affected',
       CAST(SUM(CAST(population_affected AS BIGINT)) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V03', 'Sum of DALYs',
       CAST(SUM(CAST(dalys AS BIGINT)) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V04', 'Average mortality rate (%)',
       CAST(AVG(CAST(mortality_rate_pct AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V05', 'Average recovery rate (%)',
       CAST(AVG(CAST(recovery_rate_pct AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V06', 'Average treatment cost (USD)',
       CAST(AVG(CAST(avg_treatment_cost_usd AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V07', 'Average doctors per 1000',
       CAST(AVG(CAST(doctors_per_1000 AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V08', 'Average hospital beds per 1000',
       CAST(AVG(CAST(hospital_beds_per_1000 AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V09', 'Average healthcare access (%)',
       CAST(AVG(CAST(healthcare_access_pct AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V10', 'Treatment availability rate (%)',
       CAST(100.0 * AVG(CAST(treatment_available AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats
UNION ALL
SELECT 'V11', 'Average mortality rate (%), communicable diseases',
       CAST(AVG(CAST(f.mortality_rate_pct AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_disease AS d ON d.disease_id = f.disease_id
WHERE d.disease_group = 'Communicable'
UNION ALL
SELECT 'V12', 'Average recovery rate (%), USA, 2020',
       CAST(AVG(CAST(f.recovery_rate_pct AS DECIMAL(18,6))) AS DECIMAL(38,4))
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_country AS c ON c.country_id = f.country_id
WHERE c.country_name = 'USA' AND f.[year] = 2020;
GO

-- Checks
SELECT COUNT(*) AS detail_rows FROM dbo.vw_health_detail;
SELECT COUNT(*) AS tableau_rows, SUM(record_count) AS tableau_records FROM dbo.vw_tableau_base;
SELECT * FROM dbo.vw_validation_metrics ORDER BY metric_id;