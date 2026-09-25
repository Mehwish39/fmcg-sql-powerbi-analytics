/*
=========================================================
Project: FMCG ERP Analytics
Script: 02_customers_profile.sql
Purpose: Inspect and profile the Customers table
=========================================================
*/

USE FMCG_Analytics;
GO

-- View the first 10 customer records
SELECT TOP 10 *
FROM dbo.Customers;

-- Count the total number of customer records
SELECT COUNT(*) AS TotalCustomers
FROM dbo.Customers;

-- Check column names and data types
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Customers'
ORDER BY ORDINAL_POSITION;

-- Check for missing values in the Customers table
SELECT
    SUM(CASE WHEN CustomerName IS NULL THEN 1 ELSE 0 END) AS MissingCustomerName,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS MissingRegion,
    SUM(CASE WHEN Channel IS NULL THEN 1 ELSE 0 END) AS MissingChannel,
    SUM(CASE WHEN CustomerSegment IS NULL THEN 1 ELSE 0 END) AS MissingCustomerSegment,
    SUM(CASE WHEN OnboardDate IS NULL THEN 1 ELSE 0 END) AS MissingOnboardDate,
    SUM(CASE WHEN CreditLimitGBP IS NULL THEN 1 ELSE 0 END) AS MissingCreditLimit,
    SUM(CASE WHEN PaymentTermsDays IS NULL THEN 1 ELSE 0 END) AS MissingPaymentTerms,
    SUM(CASE WHEN SalesRepCode IS NULL THEN 1 ELSE 0 END) AS MissingSalesRepCode
FROM dbo.Customers;

-- Inspect customers with no assigned sales representative
SELECT TOP 20
    CustomerID,
    CustomerName,
    Region,
    Channel,
    CustomerSegment,
    SalesRepCode
FROM dbo.Customers
WHERE SalesRepCode IS NULL;


-- Check whether any CustomerID appears more than once
SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM dbo.Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- Review distinct values in key customer categories
SELECT DISTINCT Region
FROM dbo.Customers
ORDER BY Region;

SELECT DISTINCT Channel
FROM dbo.Customers
ORDER BY Channel;

SELECT DISTINCT CustomerSegment
FROM dbo.Customers
ORDER BY CustomerSegment;

-- Check for leading or trailing spaces in Channel
SELECT
    CustomerID,
    Channel,
    LEN(Channel) AS VisibleLength,
    DATALENGTH(Channel) / 2 AS StoredLength
FROM dbo.Customers
WHERE DATALENGTH(Channel) <> DATALENGTH(LTRIM(RTRIM(Channel)));

-- Inspect Channel values containing leading or trailing spaces
SELECT TOP 20
    CustomerID,
    '[' + Channel + ']' AS OriginalChannel,
    '[' + LTRIM(RTRIM(Channel)) + ']' AS CleanedChannel
FROM dbo.Customers
WHERE DATALENGTH(Channel) <> DATALENGTH(LTRIM(RTRIM(Channel)));

-- Count Channel values after removing leading/trailing spaces
SELECT
    LTRIM(RTRIM(Channel)) AS TrimmedChannel,
    COUNT(*) AS CustomerCount
FROM dbo.Customers
GROUP BY LTRIM(RTRIM(Channel))
ORDER BY TrimmedChannel;

-- Check Channel capitalization using an exact comparison
SELECT
    LTRIM(RTRIM(Channel)) COLLATE Latin1_General_100_BIN2 AS ExactChannel,
    COUNT(*) AS CustomerCount
FROM dbo.Customers
GROUP BY
    LTRIM(RTRIM(Channel)) COLLATE Latin1_General_100_BIN2
ORDER BY ExactChannel;



-- Check Region values exactly as stored
SELECT
    Region COLLATE Latin1_General_100_BIN2 AS ExactRegion,
    COUNT(*) AS CustomerCount
FROM dbo.Customers
GROUP BY Region COLLATE Latin1_General_100_BIN2
ORDER BY ExactRegion;

-- Check CustomerSegment values exactly as stored
SELECT
    CustomerSegment COLLATE Latin1_General_100_BIN2 AS ExactSegment,
    COUNT(*) AS CustomerCount
FROM dbo.Customers
GROUP BY CustomerSegment COLLATE Latin1_General_100_BIN2
ORDER BY ExactSegment;

-- Check the earliest and latest customer onboarding dates
SELECT
    MIN(OnboardDate) AS EarliestOnboardDate,
    MAX(OnboardDate) AS LatestOnboardDate
FROM dbo.Customers;

-- Check the range of customer credit limits
SELECT
    MIN(CreditLimitGBP) AS MinimumCreditLimit,
    MAX(CreditLimitGBP) AS MaximumCreditLimit,
    AVG(CreditLimitGBP) AS AverageCreditLimit
FROM dbo.Customers;

-- Check how many customers have each payment term
SELECT
    PaymentTermsDays,
    COUNT(*) AS CustomerCount
FROM dbo.Customers
GROUP BY PaymentTermsDays
ORDER BY PaymentTermsDays;


-- Check how customers are distributed across sales reps
SELECT
    SalesRepCode,
    COUNT(*) AS CustomerCount
FROM dbo.Customers
GROUP BY SalesRepCode
ORDER BY SalesRepCode;