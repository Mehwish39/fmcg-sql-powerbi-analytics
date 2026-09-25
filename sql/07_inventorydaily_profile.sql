-- Check how many daily inventory snapshots were imported
-- This confirms that all inventory records reached SQL Server

SELECT COUNT(*) AS TotalInventoryRows
FROM dbo.InventoryDaily;


-- Preview daily inventory records
-- This helps us understand how stock changes by product, warehouse, and date

SELECT TOP 10 *
FROM dbo.InventoryDaily;

-- Check for missing values in important inventory fields
-- Inventory snapshots need complete stock quantities for reliable stock analysis

SELECT
    SUM(CASE WHEN SnapshotDate IS NULL THEN 1 ELSE 0 END) AS MissingSnapshotDate,
    SUM(CASE WHEN WarehouseID IS NULL THEN 1 ELSE 0 END) AS MissingWarehouseID,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS MissingProductID,
    SUM(CASE WHEN OpeningCases IS NULL THEN 1 ELSE 0 END) AS MissingOpeningCases,
    SUM(CASE WHEN ProductionReceiptCases IS NULL THEN 1 ELSE 0 END) AS MissingProductionReceiptCases,
    SUM(CASE WHEN ShippedCases IS NULL THEN 1 ELSE 0 END) AS MissingShippedCases,
    SUM(CASE WHEN WriteOffCases IS NULL THEN 1 ELSE 0 END) AS MissingWriteOffCases,
    SUM(CASE WHEN ClosingCases IS NULL THEN 1 ELSE 0 END) AS MissingClosingCases,
    SUM(CASE WHEN StandardCostPerCaseGBP IS NULL THEN 1 ELSE 0 END) AS MissingStandardCost,
    SUM(CASE WHEN ClosingValueGBP IS NULL THEN 1 ELSE 0 END) AS MissingClosingValue,
    SUM(CASE WHEN SafetyStockCases IS NULL THEN 1 ELSE 0 END) AS MissingSafetyStock
FROM dbo.InventoryDaily;


-- Check whether daily inventory movements reconcile correctly
-- Opening stock + production receipts - shipments - write-offs should equal closing stock

SELECT COUNT(*) AS InvalidInventoryRows
FROM dbo.InventoryDaily
WHERE OpeningCases
      + ProductionReceiptCases
      - ShippedCases
      - WriteOffCases
      <> ClosingCases;




-- Check for duplicate daily inventory snapshots
-- Each product should appear only once per warehouse per day

SELECT
    SnapshotDate,
    WarehouseID,
    ProductID,
    COUNT(*) AS DuplicateCount
FROM dbo.InventoryDaily
GROUP BY
    SnapshotDate,
    WarehouseID,
    ProductID
HAVING COUNT(*) > 1;


-- Check for impossible negative inventory values
-- Stock quantities should not be negative

SELECT COUNT(*) AS NegativeInventoryRows
FROM dbo.InventoryDaily
WHERE OpeningCases < 0
   OR ProductionReceiptCases < 0
   OR ShippedCases < 0
   OR WriteOffCases < 0
   OR ClosingCases < 0
   OR SafetyStockCases < 0;



-- Check the period covered by daily inventory data
-- This confirms inventory snapshots match the project's analysis period

SELECT
    MIN(SnapshotDate) AS EarliestSnapshotDate,
    MAX(SnapshotDate) AS LatestSnapshotDate
FROM dbo.InventoryDaily;