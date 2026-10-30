-- 02_create_tables.sql
-- Creates the staging table, 8 dimension tables, and the fact table (star schema)
USE GlobalHealthDB;
GO

-- Drop tables if they exist so the script can be re-run (fact table first, because it depends on the dimensions)
DROP TABLE IF EXISTS dbo.fact_health_stats;
DROP TABLE IF EXISTS dbo.dim_country;
DROP TABLE IF EXISTS dbo.dim_disease;
DROP TABLE IF EXISTS dbo.dim_disease_category;
DROP TABLE IF EXISTS dbo.dim_age_group;
DROP TABLE IF EXISTS dbo.dim_gender;
DROP TABLE IF EXISTS dbo.dim_treatment_type;
DROP TABLE IF EXISTS dbo.dim_year;
DROP TABLE IF EXISTS dbo.dim_income_band;
DROP TABLE IF EXISTS dbo.stg_global_health;
GO

-- Staging table: same 24 columns and order as cleaned_data.csv
CREATE TABLE dbo.stg_global_health (
    country                 NVARCHAR(50),
    [year]                  INT,
    disease_name            NVARCHAR(50),
    disease_category        NVARCHAR(50),
    prevalence_rate_pct     DECIMAL(5,2),
    incidence_rate_pct      DECIMAL(5,2),
    mortality_rate_pct      DECIMAL(5,2),
    age_group               NVARCHAR(10),
    gender                  NVARCHAR(10),
    population_affected     INT,
    healthcare_access_pct   DECIMAL(5,2),
    doctors_per_1000        DECIMAL(4,2),
    hospital_beds_per_1000  DECIMAL(4,2),
    treatment_type          NVARCHAR(30),
    avg_treatment_cost_usd  INT,
    treatment_available     BIT,
    recovery_rate_pct       DECIMAL(5,2),
    dalys                   INT,
    improvement_5y_pct      DECIMAL(4,2),
    per_capita_income_usd   INT,
    education_index         DECIMAL(3,2),
    urbanization_rate_pct   DECIMAL(5,2),
    disease_group           NVARCHAR(30),
    income_band             NVARCHAR(20)
);
GO

-- Dimension tables
CREATE TABLE dbo.dim_country (
    country_id    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    country_name  NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.dim_disease (
    disease_id     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    disease_name   NVARCHAR(50) NOT NULL UNIQUE,
    disease_group  NVARCHAR(30) NOT NULL
);

CREATE TABLE dbo.dim_disease_category (
    disease_category_id  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_name        NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.dim_age_group (
    age_group_id     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    age_group_label  NVARCHAR(10) NOT NULL UNIQUE,
    sort_order       INT NOT NULL
);

CREATE TABLE dbo.dim_gender (
    gender_id    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    gender_name  NVARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE dbo.dim_treatment_type (
    treatment_type_id    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    treatment_type_name  NVARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE dbo.dim_year (
    [year]  INT NOT NULL PRIMARY KEY,
    decade  INT NOT NULL
);

CREATE TABLE dbo.dim_income_band (
    income_band_id  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    band_name       NVARCHAR(20) NOT NULL UNIQUE,
    min_income      INT NOT NULL,
    max_income      INT NOT NULL
);
GO

-- Fact table: one row per source record, linked to every dimension
CREATE TABLE dbo.fact_health_stats (
    health_stat_id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    country_id              INT NOT NULL REFERENCES dbo.dim_country(country_id),
    disease_id              INT NOT NULL REFERENCES dbo.dim_disease(disease_id),
    disease_category_id     INT NOT NULL REFERENCES dbo.dim_disease_category(disease_category_id),
    age_group_id            INT NOT NULL REFERENCES dbo.dim_age_group(age_group_id),
    gender_id               INT NOT NULL REFERENCES dbo.dim_gender(gender_id),
    treatment_type_id       INT NOT NULL REFERENCES dbo.dim_treatment_type(treatment_type_id),
    [year]                  INT NOT NULL REFERENCES dbo.dim_year([year]),
    income_band_id          INT NOT NULL REFERENCES dbo.dim_income_band(income_band_id),
    prevalence_rate_pct     DECIMAL(5,2) NOT NULL,
    incidence_rate_pct      DECIMAL(5,2) NOT NULL,
    mortality_rate_pct      DECIMAL(5,2) NOT NULL,
    population_affected     INT NOT NULL,
    healthcare_access_pct   DECIMAL(5,2) NOT NULL,
    doctors_per_1000        DECIMAL(4,2) NOT NULL,
    hospital_beds_per_1000  DECIMAL(4,2) NOT NULL,
    avg_treatment_cost_usd  INT NOT NULL,
    treatment_available     BIT NOT NULL,
    recovery_rate_pct       DECIMAL(5,2) NOT NULL,
    dalys                   INT NOT NULL,
    improvement_5y_pct      DECIMAL(4,2) NOT NULL,
    per_capita_income_usd   INT NOT NULL,
    education_index         DECIMAL(3,2) NOT NULL,
    urbanization_rate_pct   DECIMAL(5,2) NOT NULL
);
GO

-- Check: list the tables that were created (expected: 10)
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;