/*
=========================================================
Project: FMCG ERP Analytics
Script: 01_database_setup.sql
Purpose: Create the project database and verify setup
=========================================================
*/

-- Create the database only if it does not already exist
IF DB_ID('FMCG_Analytics') IS NULL
BEGIN
    CREATE DATABASE FMCG_Analytics;
END;
GO


-- Switch to the project database
USE FMCG_Analytics;
GO


-- Check which tables currently exist
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

