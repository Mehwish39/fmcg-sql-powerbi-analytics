-- Check how many return lines were imported
-- This confirms that all return records from the source file reached SQL Server

SELECT COUNT(*) AS TotalReturnLines
FROM dbo.ReturnLines;

SELECT * FROM dbo.ReturnLines;


-- Preview return records
-- This helps us understand what information is captured for each customer return

SELECT TOP 10 *
FROM dbo.ReturnLines;


-- Check for missing values in important return fields
-- Missing return details could affect return-cost and profitability analysis

SELECT
    SUM(CASE WHEN DeliveryLineID IS NULL THEN 1 ELSE 0 END) AS MissingDeliveryLineID,
    SUM(CASE WHEN ReturnDate IS NULL THEN 1 ELSE 0 END) AS MissingReturnDate,
    SUM(CASE WHEN ReturnedCases IS NULL THEN 1 ELSE 0 END) AS MissingReturnedCases,
    SUM(CASE WHEN ReasonCode IS NULL THEN 1 ELSE 0 END) AS MissingReasonCode,
    SUM(CASE WHEN CreditAmountGBP IS NULL THEN 1 ELSE 0 END) AS MissingCreditAmount,
    SUM(CASE WHEN HandlingCostGBP IS NULL THEN 1 ELSE 0 END) AS MissingHandlingCost,
    SUM(CASE WHEN Disposition IS NULL THEN 1 ELSE 0 END) AS MissingDisposition
FROM dbo.ReturnLines;


-- Review the different reasons customers returned products
-- This helps identify the main causes of returns in the business

SELECT
    ReasonCode,
    COUNT(*) AS ReturnLineCount
FROM dbo.ReturnLines
GROUP BY ReasonCode
ORDER BY ReturnLineCount DESC;


-- Observation:
-- Damaged products are the most common return reason.
-- However, return volumes are fairly spread across all four reason categories,
-- so there is no single overwhelming cause of returns.


-- Review how returned products are handled after return
-- This helps understand whether returned stock is destroyed, restocked, or handled another way

SELECT
    Disposition,
    COUNT(*) AS ReturnLineCount
FROM dbo.ReturnLines
GROUP BY Disposition
ORDER BY ReturnLineCount DESC;


-- Observation:
-- All returned products are marked as Destroyed.
-- This means returns create a full product loss rather than recoverable stock.
-- Return-related profitability should therefore consider both customer credit and handling cost.

-- Check whether every return links to a valid delivery
-- This confirms that each return can be traced back to the original shipment

SELECT COUNT(*) AS InvalidDeliveryLinks
FROM dbo.ReturnLines r
LEFT JOIN dbo.DeliveryLines d
    ON r.DeliveryLineID = d.DeliveryLineID
WHERE d.DeliveryLineID IS NULL;


-- Check whether customers returned more cases than were originally shipped
-- A return quantity should never exceed the quantity delivered

SELECT COUNT(*) AS InvalidReturnQuantities
FROM dbo.ReturnLines r
JOIN dbo.DeliveryLines d
    ON r.DeliveryLineID = d.DeliveryLineID
WHERE r.ReturnedCases <= 0
   OR r.ReturnedCases > d.ShippedCases;


-- Check whether returns happened after the original delivery
-- A customer should not be able to return goods before receiving them

SELECT COUNT(*) AS InvalidReturnDates
FROM dbo.ReturnLines r
JOIN dbo.DeliveryLines d
    ON r.DeliveryLineID = d.DeliveryLineID
WHERE d.DeliveredDate IS NULL
   OR r.ReturnDate < d.DeliveredDate;


-- Check whether return credit matches ReturnedCases × original NetUnitPriceGBP
-- This confirms that customer refunds/credits have been calculated correctly

SELECT COUNT(*) AS InvalidCreditRows
FROM dbo.ReturnLines r
JOIN dbo.DeliveryLines d
    ON r.DeliveryLineID = d.DeliveryLineID
WHERE ABS(
        r.CreditAmountGBP - (r.ReturnedCases * d.NetUnitPriceGBP)
      ) > 0.01;


-- Check for invalid financial values in return records
-- Credits and handling costs should never be negative

SELECT COUNT(*) AS InvalidReturnCostRows
FROM dbo.ReturnLines
WHERE CreditAmountGBP < 0
   OR HandlingCostGBP < 0;


-- Summarise the financial impact of returns
-- Return credits reduce sales, while handling costs create extra operating cost

SELECT
    CAST(SUM(CreditAmountGBP) AS DECIMAL(18,2)) AS TotalReturnCreditGBP,
    CAST(SUM(HandlingCostGBP) AS DECIMAL(18,2)) AS TotalHandlingCostGBP,
    CAST(SUM(CreditAmountGBP + HandlingCostGBP) AS DECIMAL(18,2)) AS TotalReturnImpactGBP
FROM dbo.ReturnLines;


-- Observation:
-- Returns created a direct financial impact of approximately £2.79m.
-- Most of this impact comes from customer credits (£2.71m),
-- while handling costs contributed about £75k.


-- Compare the financial impact of each return reason
-- This helps identify which return problems cost the business the most

SELECT
    ReasonCode,
    COUNT(*) AS ReturnLineCount,
    SUM(ReturnedCases) AS ReturnedCases,

    CAST(SUM(CreditAmountGBP) AS DECIMAL(18,2)) AS ReturnCreditGBP,

    CAST(SUM(HandlingCostGBP) AS DECIMAL(18,2)) AS HandlingCostGBP,

    CAST(
        SUM(CreditAmountGBP + HandlingCostGBP)
        AS DECIMAL(18,2)
    ) AS TotalReturnImpactGBP

FROM dbo.ReturnLines
GROUP BY ReasonCode
ORDER BY TotalReturnImpactGBP DESC;



-- Observation:
-- Damaged products create the highest return-related financial impact at about £773k.
-- Short Shelf Life is the second-largest return cost.
-- This suggests damage prevention may be an important area for investigation.


-- Compare return impact by product category
-- This helps identify which parts of the product portfolio are most affected by returns

SELECT
    s.Category,
    SUM(r.ReturnedCases) AS ReturnedCases,

    CAST(
        SUM(r.CreditAmountGBP + r.HandlingCostGBP)
        AS DECIMAL(18,2)
    ) AS TotalReturnImpactGBP

FROM dbo.ReturnLines r

-- Connect each return back to its original delivery
JOIN dbo.DeliveryLines d
    ON r.DeliveryLineID = d.DeliveryLineID

-- Connect the delivery back to the product that was ordered
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID

GROUP BY s.Category
ORDER BY TotalReturnImpactGBP DESC;



-- Observation:
-- Packaged Foods has the highest financial impact from returns,
-- while Beverages has the highest number of returned cases.
-- Return volume and financial impact should therefore be analysed separately.



-- Compare returned cases with shipped cases by category
-- This gives a fairer return-rate comparison across product categories

SELECT
    s.Category,

    SUM(d.ShippedCases) AS ShippedCases,

    SUM(COALESCE(r.ReturnedCases, 0)) AS ReturnedCases,

    CAST(
        100.0 * SUM(COALESCE(r.ReturnedCases, 0))
        / NULLIF(SUM(d.ShippedCases), 0)
        AS DECIMAL(5,2)
    ) AS ReturnRatePct

FROM dbo.DeliveryLines d

JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID

LEFT JOIN dbo.ReturnLines r
    ON d.DeliveryLineID = r.DeliveryLineID

GROUP BY s.Category

ORDER BY ReturnRatePct DESC;