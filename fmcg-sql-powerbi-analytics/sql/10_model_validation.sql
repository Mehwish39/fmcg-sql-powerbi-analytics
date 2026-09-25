-- Final check of the SQL reporting model
-- Confirms that all dimensions and fact views are ready for Power BI

SELECT 'Customers' AS TableName, COUNT(*) AS RecordCount
FROM dbo.vw_Customers_Clean

UNION ALL

SELECT 'Products', COUNT(*)
FROM dbo.vw_Products

UNION ALL

SELECT 'Dates', COUNT(*)
FROM dbo.DimDate

UNION ALL

SELECT 'Locations', COUNT(*)
FROM dbo.vw_Locations

UNION ALL

SELECT 'Suppliers', COUNT(*)
FROM dbo.vw_Suppliers

UNION ALL

SELECT 'Materials', COUNT(*)
FROM dbo.vw_Materials

UNION ALL

SELECT 'Sales Orders', COUNT(*)
FROM dbo.vw_FactSalesOrders

UNION ALL

SELECT 'Deliveries', COUNT(*)
FROM dbo.vw_FactDeliveries

UNION ALL

SELECT 'Returns', COUNT(*)
FROM dbo.vw_FactReturns

UNION ALL

SELECT 'Production', COUNT(*)
FROM dbo.vw_FactProduction

UNION ALL

SELECT 'Inventory', COUNT(*)
FROM dbo.vw_FactInventory

UNION ALL

SELECT 'Procurement', COUNT(*)
FROM dbo.vw_FactProcurement;