-- Check how many production batches were imported
-- This confirms that all manufacturing records reached SQL Server

SELECT COUNT(*) AS TotalProductionBatches
FROM dbo.ProductionBatches;


-- Preview manufacturing records
-- This helps us understand what each production batch contains

SELECT TOP 10 *
FROM dbo.ProductionBatches;


-- Check for missing values in important production fields
-- DowntimeReason can be NULL when there was no downtime

SELECT
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS MissingProductID,
    SUM(CASE WHEN PlantID IS NULL THEN 1 ELSE 0 END) AS MissingPlantID,
    SUM(CASE WHEN WarehouseID IS NULL THEN 1 ELSE 0 END) AS MissingWarehouseID,
    SUM(CASE WHEN LineCode IS NULL THEN 1 ELSE 0 END) AS MissingLineCode,
    SUM(CASE WHEN PlannedCases IS NULL THEN 1 ELSE 0 END) AS MissingPlannedCases,
    SUM(CASE WHEN ProducedCases IS NULL THEN 1 ELSE 0 END) AS MissingProducedCases,
    SUM(CASE WHEN GoodCases IS NULL THEN 1 ELSE 0 END) AS MissingGoodCases,
    SUM(CASE WHEN RejectedCases IS NULL THEN 1 ELSE 0 END) AS MissingRejectedCases,
    SUM(CASE WHEN ScheduledMinutes IS NULL THEN 1 ELSE 0 END) AS MissingScheduledMinutes,
    SUM(CASE WHEN DowntimeMinutes IS NULL THEN 1 ELSE 0 END) AS MissingDowntimeMinutes,
    SUM(CASE WHEN DowntimeReason IS NULL THEN 1 ELSE 0 END) AS MissingDowntimeReason
FROM dbo.ProductionBatches;


-- Check whether production quantities add up correctly
-- Good cases + rejected cases should equal total produced cases

SELECT COUNT(*) AS InvalidProductionRows
FROM dbo.ProductionBatches
WHERE GoodCases + RejectedCases <> ProducedCases;


-- Check for impossible downtime values
-- Downtime cannot be negative or exceed the scheduled production time

SELECT COUNT(*) AS InvalidDowntimeRows
FROM dbo.ProductionBatches
WHERE DowntimeMinutes < 0
   OR DowntimeMinutes > ScheduledMinutes;



-- Check whether any batch produced more cases than originally planned
-- This helps identify overproduction or unusual batch behaviour

SELECT COUNT(*) AS OverProducedBatches
FROM dbo.ProductionBatches
WHERE ProducedCases > PlannedCases;


-- Observation:
-- 869 production batches exceeded their planned production quantity.
-- This is treated as valid operational behaviour rather than a data-quality error.



-- Check the period covered by manufacturing data
-- This confirms that production activity matches the project's analysis period

SELECT
    MIN(ProductionDate) AS EarliestProductionDate,
    MAX(ProductionDate) AS LatestProductionDate
FROM dbo.ProductionBatches;