-- 05_analysis_queries.sql
-- Analytical queries for questions Q2 to Q7 (Q1 is covered by the data quality assessment, Q8 by the validation views)
USE GlobalHealthDB;
GO

-- ============================================================
-- Q2: Which diseases and countries carry the highest burden? By age group and gender?
-- ============================================================

-- Q2a: burden by disease
SELECT d.disease_name, d.disease_group,
       SUM(CAST(f.population_affected AS BIGINT)) AS total_population_affected,
       SUM(CAST(f.dalys AS BIGINT)) AS total_dalys,
       CAST(AVG(f.prevalence_rate_pct) AS DECIMAL(10,2)) AS avg_prevalence_rate_pct,
       CAST(AVG(f.incidence_rate_pct) AS DECIMAL(10,2)) AS avg_incidence_rate_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_disease AS d ON d.disease_id = f.disease_id
GROUP BY d.disease_name, d.disease_group
ORDER BY total_population_affected DESC;

-- Q2b: burden by country
SELECT c.country_name,
       SUM(CAST(f.population_affected AS BIGINT)) AS total_population_affected,
       SUM(CAST(f.dalys AS BIGINT)) AS total_dalys,
       CAST(AVG(f.prevalence_rate_pct) AS DECIMAL(10,2)) AS avg_prevalence_rate_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_country AS c ON c.country_id = f.country_id
GROUP BY c.country_name
ORDER BY total_dalys DESC;

-- Q2c: burden by age group and gender
SELECT ag.age_group_label, g.gender_name,
       SUM(CAST(f.population_affected AS BIGINT)) AS total_population_affected,
       SUM(CAST(f.dalys AS BIGINT)) AS total_dalys
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_age_group AS ag ON ag.age_group_id = f.age_group_id
JOIN dbo.dim_gender AS g ON g.gender_id = f.gender_id
GROUP BY ag.age_group_label, ag.sort_order, g.gender_name
ORDER BY ag.sort_order, g.gender_name;

-- ============================================================
-- Q3: Which diseases (and disease groups) have the highest mortality and the lowest recovery?
-- ============================================================

-- Q3a: mortality and recovery by disease, with rankings (window functions)
SELECT d.disease_name, d.disease_group,
       CAST(AVG(f.mortality_rate_pct) AS DECIMAL(10,2)) AS avg_mortality_rate_pct,
       CAST(AVG(f.recovery_rate_pct) AS DECIMAL(10,2)) AS avg_recovery_rate_pct,
       RANK() OVER (ORDER BY AVG(f.mortality_rate_pct) DESC) AS mortality_rank,
       RANK() OVER (ORDER BY AVG(f.recovery_rate_pct) ASC) AS lowest_recovery_rank
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_disease AS d ON d.disease_id = f.disease_id
GROUP BY d.disease_name, d.disease_group
ORDER BY mortality_rank;

-- Q3b: communicable vs. non-communicable
SELECT d.disease_group,
       COUNT(*) AS records,
       CAST(AVG(f.mortality_rate_pct) AS DECIMAL(10,2)) AS avg_mortality_rate_pct,
       CAST(AVG(f.recovery_rate_pct) AS DECIMAL(10,2)) AS avg_recovery_rate_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_disease AS d ON d.disease_id = f.disease_id
GROUP BY d.disease_group
ORDER BY d.disease_group;

-- ============================================================
-- Q4: How do healthcare capacity and access differ across countries?
-- ============================================================

-- Q4a: capacity by country, ranked from lowest access
SELECT c.country_name,
       CAST(AVG(f.doctors_per_1000) AS DECIMAL(10,2)) AS avg_doctors_per_1000,
       CAST(AVG(f.hospital_beds_per_1000) AS DECIMAL(10,2)) AS avg_beds_per_1000,
       CAST(AVG(f.healthcare_access_pct) AS DECIMAL(10,2)) AS avg_healthcare_access_pct,
       RANK() OVER (ORDER BY AVG(f.healthcare_access_pct) ASC) AS lowest_access_rank
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_country AS c ON c.country_id = f.country_id
GROUP BY c.country_name
ORDER BY lowest_access_rank;

-- Q4b: the five countries with the lowest access
SELECT TOP 5 c.country_name,
       CAST(AVG(f.doctors_per_1000) AS DECIMAL(10,2)) AS avg_doctors_per_1000,
       CAST(AVG(f.hospital_beds_per_1000) AS DECIMAL(10,2)) AS avg_beds_per_1000,
       CAST(AVG(f.healthcare_access_pct) AS DECIMAL(10,2)) AS avg_healthcare_access_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_country AS c ON c.country_id = f.country_id
GROUP BY c.country_name
ORDER BY AVG(f.healthcare_access_pct) ASC;

-- ============================================================
-- Q5: Is there a relationship between socioeconomic factors and health outcomes?
-- ============================================================

-- Q5a: outcomes by income band
SELECT ib.band_name, COUNT(*) AS records,
       CAST(AVG(f.healthcare_access_pct) AS DECIMAL(10,2)) AS avg_healthcare_access_pct,
       CAST(AVG(f.recovery_rate_pct) AS DECIMAL(10,2)) AS avg_recovery_rate_pct,
       CAST(AVG(f.mortality_rate_pct) AS DECIMAL(10,2)) AS avg_mortality_rate_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_income_band AS ib ON ib.income_band_id = f.income_band_id
GROUP BY ib.band_name, ib.min_income
ORDER BY ib.min_income;

-- Q5b: correlation coefficients (Pearson; 0 means no linear relationship)
WITH m AS (
    SELECT AVG(CAST(per_capita_income_usd AS FLOAT)) AS mean_income,
           AVG(CAST(healthcare_access_pct AS FLOAT)) AS mean_access,
           STDEVP(CAST(per_capita_income_usd AS FLOAT)) AS sd_income,
           STDEVP(CAST(healthcare_access_pct AS FLOAT)) AS sd_access,
           AVG(CAST(education_index AS FLOAT)) AS mean_education,
           AVG(CAST(recovery_rate_pct AS FLOAT)) AS mean_recovery,
           STDEVP(CAST(education_index AS FLOAT)) AS sd_education,
           STDEVP(CAST(recovery_rate_pct AS FLOAT)) AS sd_recovery
    FROM dbo.fact_health_stats
)
SELECT
    ROUND(AVG((CAST(f.per_capita_income_usd AS FLOAT) - m.mean_income) * (CAST(f.healthcare_access_pct AS FLOAT) - m.mean_access))
          / (MAX(m.sd_income) * MAX(m.sd_access)), 4) AS corr_income_vs_access,
    ROUND(AVG((CAST(f.education_index AS FLOAT) - m.mean_education) * (CAST(f.recovery_rate_pct AS FLOAT) - m.mean_recovery))
          / (MAX(m.sd_education) * MAX(m.sd_recovery)), 4) AS corr_education_vs_recovery
FROM dbo.fact_health_stats AS f
CROSS JOIN m;

-- ============================================================
-- Q6: Which treatment types are most effective and most costly? Does availability relate to recovery?
-- ============================================================

-- Q6a: cost and recovery by treatment type
SELECT t.treatment_type_name,
       CAST(AVG(CAST(f.avg_treatment_cost_usd AS DECIMAL(18,2))) AS DECIMAL(10,2)) AS avg_treatment_cost_usd,
       CAST(AVG(f.recovery_rate_pct) AS DECIMAL(10,2)) AS avg_recovery_rate_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_treatment_type AS t ON t.treatment_type_id = f.treatment_type_id
GROUP BY t.treatment_type_name
ORDER BY avg_recovery_rate_pct DESC;

-- Q6b: recovery by availability of vaccines or treatment
SELECT CASE WHEN f.treatment_available = 1 THEN 'Yes' ELSE 'No' END AS treatment_available,
       COUNT(*) AS records,
       CAST(AVG(f.recovery_rate_pct) AS DECIMAL(10,2)) AS avg_recovery_rate_pct,
       CAST(AVG(f.mortality_rate_pct) AS DECIMAL(10,2)) AS avg_mortality_rate_pct
FROM dbo.fact_health_stats AS f
GROUP BY f.treatment_available
ORDER BY f.treatment_available DESC;

-- ============================================================
-- Q7: How have mortality, prevalence, and recovery changed between 2000 and 2024?
-- ============================================================

-- Q7a: yearly averages with the change from the previous year (CTE and window function)
WITH yearly AS (
    SELECT f.[year] AS [year],
           CAST(AVG(f.mortality_rate_pct) AS DECIMAL(10,3)) AS avg_mortality_rate_pct,
           CAST(AVG(f.prevalence_rate_pct) AS DECIMAL(10,3)) AS avg_prevalence_rate_pct,
           CAST(AVG(f.recovery_rate_pct) AS DECIMAL(10,3)) AS avg_recovery_rate_pct
    FROM dbo.fact_health_stats AS f
    GROUP BY f.[year]
)
SELECT [year],
       avg_mortality_rate_pct,
       CAST(avg_mortality_rate_pct - LAG(avg_mortality_rate_pct) OVER (ORDER BY [year]) AS DECIMAL(10,3)) AS mortality_change_vs_previous_year,
       avg_prevalence_rate_pct,
       avg_recovery_rate_pct
FROM yearly
ORDER BY [year];

-- Q7b: five-year improvement by disease group
SELECT d.disease_group,
       CAST(AVG(f.improvement_5y_pct) AS DECIMAL(10,2)) AS avg_improvement_5y_pct
FROM dbo.fact_health_stats AS f
JOIN dbo.dim_disease AS d ON d.disease_id = f.disease_id
GROUP BY d.disease_group
ORDER BY d.disease_group;