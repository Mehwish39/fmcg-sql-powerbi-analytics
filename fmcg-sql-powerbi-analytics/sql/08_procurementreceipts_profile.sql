-- Check how many procurement receipt records were imported
-- This confirms that all supplier receipt records reached SQL Server

SELECT COUNT(*) AS TotalProcurementReceipts
FROM dbo.ProcurementReceipts;


-- Preview supplier receipt records
-- This helps us understand the procurement fields before validation

SELECT TOP 10 *
FROM dbo.ProcurementReceipts;


-- Check for missing values in important procurement fields
-- Complete supplier and receipt data is needed for reliable supplier-performance analysis

SELECT
    SUM(CASE WHEN PONumber IS NULL THEN 1 ELSE 0 END) AS MissingPONumber,
    SUM(CASE WHEN SupplierID IS NULL THEN 1 ELSE 0 END) AS MissingSupplierID,
    SUM(CASE WHEN MaterialID IS NULL THEN 1 ELSE 0 END) AS MissingMaterialID,
    SUM(CASE WHEN PlantID IS NULL THEN 1 ELSE 0 END) AS MissingPlantID,
    SUM(CASE WHEN PODate IS NULL THEN 1 ELSE 0 END) AS MissingPODate,
    SUM(CASE WHEN PromisedReceiptDate IS NULL THEN 1 ELSE 0 END) AS MissingPromisedDate,
    SUM(CASE WHEN ActualReceiptDate IS NULL THEN 1 ELSE 0 END) AS MissingActualDate,
    SUM(CASE WHEN OrderedQty IS NULL THEN 1 ELSE 0 END) AS MissingOrderedQty,
    SUM(CASE WHEN ReceivedQty IS NULL THEN 1 ELSE 0 END) AS MissingReceivedQty,
    SUM(CASE WHEN RejectedQty IS NULL THEN 1 ELSE 0 END) AS MissingRejectedQty,
    SUM(CASE WHEN ContractUnitPriceGBP IS NULL THEN 1 ELSE 0 END) AS MissingContractPrice,
    SUM(CASE WHEN ActualUnitPriceGBP IS NULL THEN 1 ELSE 0 END) AS MissingActualPrice,
    SUM(CASE WHEN InvoiceAmountGBP IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceAmount
FROM dbo.ProcurementReceipts;



-- Check whether procurement quantities make business sense
-- Rejected quantity should not be negative or exceed the quantity received

SELECT COUNT(*) AS InvalidProcurementQuantityRows
FROM dbo.ProcurementReceipts
WHERE OrderedQty <= 0
   OR ReceivedQty < 0
   OR RejectedQty < 0
   OR RejectedQty > ReceivedQty;



-- Check whether procurement dates follow a sensible sequence
-- A receipt should not happen before the purchase order was created

SELECT COUNT(*) AS InvalidProcurementDateRows
FROM dbo.ProcurementReceipts
WHERE PromisedReceiptDate < PODate
   OR ActualReceiptDate < PODate;


-- Check whether invoice amount matches received quantity × actual unit price
-- This confirms that supplier invoice values are calculated correctly

SELECT COUNT(*) AS InvalidInvoiceRows
FROM dbo.ProcurementReceipts
WHERE ABS(
        InvoiceAmountGBP - (ReceivedQty * ActualUnitPriceGBP)
      ) > 0.01;



-- Check the period covered by supplier receipts
-- Actual receipt date is the main date we will use for procurement analysis

SELECT
    MIN(ActualReceiptDate) AS EarliestReceiptDate,
    MAX(ActualReceiptDate) AS LatestReceiptDate
FROM dbo.ProcurementReceipts;