-- Standardise customer channel names
-- This removes extra spaces and makes the labels consistent 

SELECT
    CustomerID,
    Channel AS OriginalChannel,
    LTRIM(RTRIM(Channel)) AS TrimmedChannel
FROM dbo.Customers
WHERE Channel <> LTRIM(RTRIM(Channel));


-- Find customer channel values containing leading or trailing spaces
-- DATALENGTH lets us detect spaces that normal SQL comparisons may ignore

SELECT
    CustomerID,
    '[' + Channel + ']' AS OriginalChannel,
    '[' + LTRIM(RTRIM(Channel)) + ']' AS CleanedChannel
FROM dbo.Customers
WHERE DATALENGTH(Channel)
      <> DATALENGTH(LTRIM(RTRIM(Channel)));




-- Create a cleaned customer view for reporting and Power BI
-- The raw Customers table remains unchanged

CREATE OR ALTER VIEW dbo.vw_Customers_Clean
AS

SELECT
    CustomerID,
    CustomerName,
    Region,

    -- Remove extra spaces and standardise channel names
    CASE UPPER(LTRIM(RTRIM(Channel)))
        WHEN 'ECOMMERCE' THEN 'Ecommerce'
        WHEN 'MODERN TRADE' THEN 'Modern Trade'
        WHEN 'TRADITIONAL TRADE' THEN 'Traditional Trade'
        WHEN 'WHOLESALE' THEN 'Wholesale'
    END AS Channel,

    CustomerSegment,
    OnboardDate,
    CreditLimitGBP,
    PaymentTermsDays,

    -- Show customers without a sales rep as Unassigned
    COALESCE(SalesRepCode, 'Unassigned') AS SalesRepCode

FROM dbo.Customers;
GO



-- Check the cleaned customer view
-- We expect standard channel names and no blank sales rep values

SELECT TOP 20
    CustomerID,
    Channel,
    SalesRepCode
FROM dbo.vw_Customers_Clean
ORDER BY CustomerID;



-- Check that missing sales reps were converted to 'Unassigned'
-- This prevents blank categories from appearing in Power BI

SELECT COUNT(*) AS UnassignedCustomers
FROM dbo.vw_Customers_Clean
WHERE SalesRepCode = 'Unassigned';



-- Create a clean Product dimension for Power BI
-- Each ProductID should appear only once with its product details

CREATE OR ALTER VIEW dbo.vw_Products
AS

SELECT DISTINCT
    ProductID,
    ProductName,
    Category,
    Brand,
    UnitsPerCase
FROM dbo.SalesOrderLines;
GO


-- Confirm that the Product dimension contains the expected 60 SKUs
SELECT COUNT(*) AS TotalProducts
FROM dbo.vw_Products;


-- Create a Date dimension for Power BI
-- This gives sales, deliveries, inventory, production and procurement one shared calendar

DROP TABLE IF EXISTS dbo.DimDate;

CREATE TABLE dbo.DimDate
(
    DateKey     DATE PRIMARY KEY,
    YearNumber  INT,
    QuarterNo   INT,
    MonthNo     INT,
    MonthName   VARCHAR(20),
    DayOfMonth  INT
);

DECLARE @CurrentDate DATE = '2024-01-01';

WHILE @CurrentDate <= '2025-12-31'
BEGIN
    INSERT INTO dbo.DimDate
    (
        DateKey,
        YearNumber,
        QuarterNo,
        MonthNo,
        MonthName,
        DayOfMonth
    )
    VALUES
    (
        @CurrentDate,
        YEAR(@CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        MONTH(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        DAY(@CurrentDate)
    );

    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END;


-- Confirm that the calendar contains every day in 2024 and 2025
SELECT COUNT(*) AS TotalDates
FROM dbo.DimDate;


-- Create a Location dimension for Power BI
-- This gives us one clean list of Plant and Warehouse combinations

CREATE OR ALTER VIEW dbo.vw_Locations
AS

SELECT DISTINCT
    PlantID,
    WarehouseID
FROM dbo.ProductionBatches;
GO


-- Check the Plant-to-Warehouse structure
SELECT *
FROM dbo.vw_Locations
ORDER BY PlantID;


-- Create a Supplier dimension for Power BI
-- Each supplier should appear only once

CREATE OR ALTER VIEW dbo.vw_Suppliers
AS

SELECT DISTINCT
    SupplierID,
    SupplierName
FROM dbo.ProcurementReceipts;
GO


-- Check how many suppliers exist
SELECT COUNT(*) AS TotalSuppliers
FROM dbo.vw_Suppliers;


-- Create a Material dimension for Power BI
-- Each raw/packaging material should appear only once

CREATE OR ALTER VIEW dbo.vw_Materials
AS

SELECT DISTINCT
    MaterialID,
    MaterialName,
    MaterialUOM
FROM dbo.ProcurementReceipts;
GO


-- Check how many unique materials exist
SELECT COUNT(*) AS TotalMaterials
FROM dbo.vw_Materials;



-- Create the Sales Orders fact view for Power BI
-- Keep transaction IDs, relationship keys and measurable order values

CREATE OR ALTER VIEW dbo.vw_FactSalesOrders
AS

SELECT
    OrderLineID,
    OrderID,
    LineNumber,
    OrderDate,
    PromisedDate,

    -- Keys used to connect to Customer, Product and Location dimensions
    CustomerID,
    ProductID,
    WarehouseID,

    -- Order quantities
    OrderedCases,
    CancelledCases,

    -- Standardise financial values for reporting
    CAST(ListPricePerCaseGBP AS DECIMAL(18,2)) AS ListPricePerCaseGBP,
    CAST(DiscountRate AS DECIMAL(6,4)) AS DiscountRate,

    PromoCode,
    OrderStatus

FROM dbo.SalesOrderLines;
GO


-- Confirm that no sales-order rows were lost
SELECT COUNT(*) AS TotalFactSalesOrderRows
FROM dbo.vw_FactSalesOrders;



-- Create the Deliveries fact view for Power BI
-- Each row represents one shipment/delivery event

CREATE OR ALTER VIEW dbo.vw_FactDeliveries
AS

SELECT
    DeliveryLineID,
    OrderLineID,

    -- Delivery dates
    DispatchDate,
    DeliveredDate,

    -- Quantity shipped
    ShippedCases,

    -- Financial measures
    CAST(NetUnitPriceGBP AS DECIMAL(18,2)) AS NetUnitPriceGBP,
    CAST(NetInvoiceGBP AS DECIMAL(18,2)) AS NetInvoiceGBP,
    CAST(StandardCostPerCaseGBP AS DECIMAL(18,2)) AS StandardCostPerCaseGBP,
    CAST(COGSGBP AS DECIMAL(18,2)) AS COGSGBP,
    CAST(FreightGBP AS DECIMAL(18,2)) AS FreightGBP,

    CarrierCode,
    DeliveryStatus

FROM dbo.DeliveryLines;
GO


-- Confirm that no delivery rows were lost
SELECT COUNT(*) AS TotalFactDeliveryRows
FROM dbo.vw_FactDeliveries;


-- Create the Returns fact view for Power BI
-- Each row represents one customer return linked to a delivery

CREATE OR ALTER VIEW dbo.vw_FactReturns
AS

SELECT
    ReturnLineID,
    DeliveryLineID,

    -- Date the customer returned the goods
    ReturnDate,

    -- Quantity returned
    ReturnedCases,

    -- Why the product was returned
    ReasonCode,

    -- Financial impact of the return
    CAST(CreditAmountGBP AS DECIMAL(18,2)) AS CreditAmountGBP,
    CAST(HandlingCostGBP AS DECIMAL(18,2)) AS HandlingCostGBP,

    -- What happened to the returned goods
    Disposition

FROM dbo.ReturnLines;
GO


-- Confirm that no return rows were lost
SELECT COUNT(*) AS TotalFactReturnRows
FROM dbo.vw_FactReturns;


-- Create the Production fact view for Power BI
-- Each row represents one manufacturing batch

CREATE OR ALTER VIEW dbo.vw_FactProduction
AS

SELECT
    BatchID,
    ProductionDate,

    -- Keys used to connect production to dimensions
    ProductID,
    PlantID,
    WarehouseID,
    LineCode,

    -- Planned and actual production quantities
    PlannedCases,
    ProducedCases,
    GoodCases,
    RejectedCases,

    -- Production time and downtime
    ScheduledMinutes,
    DowntimeMinutes,
    DowntimeReason,

    -- Manufacturing cost information
    CAST(StandardCostPerCaseGBP AS DECIMAL(18,2)) AS StandardCostPerCaseGBP,
    CAST(ActualConversionCostGBP AS DECIMAL(18,2)) AS ActualConversionCostGBP

FROM dbo.ProductionBatches;
GO


-- Confirm that no production batches were lost
SELECT COUNT(*) AS TotalFactProductionRows
FROM dbo.vw_FactProduction;



-- Create the Inventory fact view for Power BI
-- Each row represents one daily stock snapshot for one product in one warehouse

CREATE OR ALTER VIEW dbo.vw_FactInventory
AS

SELECT
    SnapshotID,
    SnapshotDate,

    -- Keys used to connect inventory to dimensions
    WarehouseID,
    ProductID,

    -- Daily inventory movements
    OpeningCases,
    ProductionReceiptCases,
    ShippedCases,
    WriteOffCases,
    ClosingCases,
    SafetyStockCases,

    -- Inventory value
    CAST(StandardCostPerCaseGBP AS DECIMAL(18,2)) AS StandardCostPerCaseGBP,
    CAST(ClosingValueGBP AS DECIMAL(18,2)) AS ClosingValueGBP

FROM dbo.InventoryDaily;
GO


-- Confirm that no inventory snapshot rows were lost
SELECT COUNT(*) AS TotalFactInventoryRows
FROM dbo.vw_FactInventory;



-- Create the Procurement fact view for Power BI
-- Each row represents one supplier receipt against a purchase order

CREATE OR ALTER VIEW dbo.vw_FactProcurement
AS

SELECT
    POReceiptID,
    PONumber,

    -- Keys used to connect procurement to dimensions
    SupplierID,
    MaterialID,
    PlantID,

    -- Important procurement dates
    PODate,
    PromisedReceiptDate,
    ActualReceiptDate,

    -- Ordered, received and rejected quantities
    OrderedQty,
    ReceivedQty,
    RejectedQty,

    -- Supplier pricing and invoice value
    CAST(ContractUnitPriceGBP AS DECIMAL(18,4)) AS ContractUnitPriceGBP,
    CAST(ActualUnitPriceGBP AS DECIMAL(18,4)) AS ActualUnitPriceGBP,
    CAST(InvoiceAmountGBP AS DECIMAL(18,2)) AS InvoiceAmountGBP

FROM dbo.ProcurementReceipts;
GO


-- Confirm that no procurement receipt rows were lost
SELECT COUNT(*) AS TotalFactProcurementRows
FROM dbo.vw_FactProcurement;


-- Improve the Deliveries fact view for a cleaner Power BI star schema
-- Customer, Product and Warehouse keys are brought in from the original sales order line

CREATE OR ALTER VIEW dbo.vw_FactDeliveries
AS

SELECT
    d.DeliveryLineID,
    d.OrderLineID,

    -- Dimension keys for Power BI relationships
    s.CustomerID,
    s.ProductID,
    s.WarehouseID,

    -- Delivery dates
    d.DispatchDate,
    d.DeliveredDate,

    -- Quantity shipped
    d.ShippedCases,

    -- Financial measures
    CAST(d.NetUnitPriceGBP AS DECIMAL(18,2)) AS NetUnitPriceGBP,
    CAST(d.NetInvoiceGBP AS DECIMAL(18,2)) AS NetInvoiceGBP,
    CAST(d.StandardCostPerCaseGBP AS DECIMAL(18,2)) AS StandardCostPerCaseGBP,
    CAST(d.COGSGBP AS DECIMAL(18,2)) AS COGSGBP,
    CAST(d.FreightGBP AS DECIMAL(18,2)) AS FreightGBP,

    d.CarrierCode,
    d.DeliveryStatus

FROM dbo.DeliveryLines d

-- Bring customer/product/location information from the order line
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID;
GO

-- Confirm that adding the dimension keys did not remove any deliveries
SELECT COUNT(*) AS TotalFactDeliveryRows
FROM dbo.vw_FactDeliveries;



-- Improve the Returns fact view for a cleaner Power BI model
-- Bring Customer, Product and Warehouse keys into each return record

CREATE OR ALTER VIEW dbo.vw_FactReturns
AS

SELECT
    r.ReturnLineID,
    r.DeliveryLineID,
    d.OrderLineID,

    -- Dimension keys for direct Power BI relationships
    s.CustomerID,
    s.ProductID,
    s.WarehouseID,

    -- Return details
    r.ReturnDate,
    r.ReturnedCases,
    r.ReasonCode,

    -- Financial impact of the return
    CAST(r.CreditAmountGBP AS DECIMAL(18,2)) AS CreditAmountGBP,
    CAST(r.HandlingCostGBP AS DECIMAL(18,2)) AS HandlingCostGBP,

    r.Disposition

FROM dbo.ReturnLines r

-- Find the delivery that was returned
JOIN dbo.DeliveryLines d
    ON r.DeliveryLineID = d.DeliveryLineID

-- Find the customer, product and warehouse behind that delivery
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID;
GO




-- Confirm that no return records were lost after adding dimension keys

SELECT COUNT(*) AS TotalFactReturnRows
FROM dbo.vw_FactReturns;