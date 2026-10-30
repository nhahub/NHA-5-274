-- 01_create_database.sql
-- Creates the project database (safe to run more than once)
USE master;
GO

IF DB_ID(N'GlobalHealthDB') IS NULL
    CREATE DATABASE GlobalHealthDB;
GO

USE GlobalHealthDB;
GO

SELECT DB_NAME() AS current_database;