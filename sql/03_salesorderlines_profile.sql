-- Check how many sales order lines were imported
SELECT COUNT(*) AS TotalSalesOrderLines
FROM dbo.SalesOrderLines;

-- Preview sales order data
SELECT TOP 10 *
FROM dbo.SalesOrderLines;

-- Check for missing values in important sales order fields
SELECT
    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS MissingOrderID,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS MissingProductID,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS MissingOrderDate,
    SUM(CASE WHEN PromisedDate IS NULL THEN 1 ELSE 0 END) AS MissingPromisedDate,
    SUM(CASE WHEN OrderedCases IS NULL THEN 1 ELSE 0 END) AS MissingOrderedCases,
    SUM(CASE WHEN CancelledCases IS NULL THEN 1 ELSE 0 END) AS MissingCancelledCases,
    SUM(CASE WHEN ListPricePerCaseGBP IS NULL THEN 1 ELSE 0 END) AS MissingPrice,
    SUM(CASE WHEN DiscountRate IS NULL THEN 1 ELSE 0 END) AS MissingDiscountRate,
    SUM(CASE WHEN PromoCode IS NULL THEN 1 ELSE 0 END) AS MissingPromoCode,
    SUM(CASE WHEN OrderStatus IS NULL THEN 1 ELSE 0 END) AS MissingOrderStatus
FROM dbo.SalesOrderLines;


-- Check how sales order lines are distributed by status
SELECT
    OrderStatus,
    COUNT(*) AS OrderLineCount
FROM dbo.SalesOrderLines
GROUP BY OrderStatus
ORDER BY OrderLineCount DESC;



-- Check for impossible order quantities
SELECT COUNT(*) AS InvalidQuantityRows
FROM dbo.SalesOrderLines
WHERE OrderedCases <= 0
   OR CancelledCases < 0
   OR CancelledCases > OrderedCases;



-- Check the sales order date range
SELECT
    MIN(OrderDate) AS EarliestOrderDate,
    MAX(OrderDate) AS LatestOrderDate
FROM dbo.SalesOrderLines;


-- Check whether promised dates make sense
SELECT COUNT(*) AS InvalidPromisedDates
FROM dbo.SalesOrderLines
WHERE PromisedDate < OrderDate;


-- Check for invalid discount rates
SELECT COUNT(*) AS InvalidDiscountRows
FROM dbo.SalesOrderLines
WHERE DiscountRate < 0
   OR DiscountRate > 1;



-- Check how many unique products exist
SELECT COUNT(DISTINCT ProductID) AS UniqueProducts
FROM dbo.SalesOrderLines;


-- Check how many unique products exist in each category
SELECT
    Category,
    COUNT(DISTINCT ProductID) AS UniqueProducts
FROM dbo.SalesOrderLines
GROUP BY Category
ORDER BY Category;


-- Check how many unique brands exist in the sales data
SELECT
    Brand,
    COUNT(DISTINCT ProductID) AS UniqueProducts
FROM dbo.SalesOrderLines
GROUP BY Brand
ORDER BY Brand;


-- Check whether any ProductID has inconsistent product details
SELECT
    ProductID
FROM dbo.SalesOrderLines
GROUP BY ProductID
HAVING COUNT(DISTINCT ProductName) > 1
    OR COUNT(DISTINCT Category) > 1
    OR COUNT(DISTINCT Brand) > 1
    OR COUNT(DISTINCT UnitsPerCase) > 1;



-- Check for sales orders linked to unknown customers
SELECT COUNT(*) AS InvalidCustomerLinks
FROM dbo.SalesOrderLines s
LEFT JOIN dbo.Customers c
    ON s.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;



-- Count the number of unique customer orders
SELECT
    COUNT(DISTINCT OrderID) AS TotalOrders
FROM dbo.SalesOrderLines;


-- Calculate the average number of product lines per order
SELECT
    CAST(COUNT(*) * 1.0 / COUNT(DISTINCT OrderID) AS DECIMAL(10,2)) AS AvgLinesPerOrder
FROM dbo.SalesOrderLines;