-- Check how many delivery lines were imported
SELECT COUNT(*) AS TotalDeliveryLines
FROM dbo.DeliveryLines;


-- Preview delivery data
SELECT TOP 10 *
FROM dbo.DeliveryLines;


-- Check the imported column data types
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DeliveryLines'
ORDER BY ORDINAL_POSITION;


-- Check whether DeliveryLineID can safely be treated as a number
-- This matters because ReturnLines will later link back to deliveries using this ID
SELECT COUNT(*) AS NonNumericDeliveryIDs
FROM dbo.DeliveryLines
WHERE TRY_CONVERT(INT, DeliveryLineID) IS NULL;



-- Review the different delivery statuses used in the dataset
-- This helps us understand whether deliveries are completed or still in progress
SELECT
    DeliveryStatus,
    COUNT(*) AS DeliveryLineCount
FROM dbo.DeliveryLines
GROUP BY DeliveryStatus
ORDER BY DeliveryLineCount DESC;


-- Check for inconsistent delivery status and delivery date
-- Delivered rows should have a date; InTransit rows should normally have no delivered date
SELECT COUNT(*) AS InvalidDeliveryStatusRows
FROM dbo.DeliveryLines
WHERE (DeliveryStatus = 'Delivered' AND DeliveredDate IS NULL)
   OR (DeliveryStatus = 'InTransit' AND DeliveredDate IS NOT NULL);


-- Check that delivered dates are not earlier than dispatch dates
-- A delivery cannot arrive before it was dispatched
SELECT COUNT(*) AS InvalidDeliveryDates
FROM dbo.DeliveryLines
WHERE DeliveredDate IS NOT NULL
  AND DeliveredDate < DispatchDate;



-- Check for impossible shipped quantities
-- Shipped cases should always be greater than zero
SELECT COUNT(*) AS InvalidShippedCases
FROM dbo.DeliveryLines
WHERE ShippedCases <= 0;


-- Check whether NetInvoiceGBP matches ShippedCases × NetUnitPriceGBP
-- This confirms that delivery revenue has been calculated correctly
SELECT COUNT(*) AS InvalidInvoiceRows
FROM dbo.DeliveryLines
WHERE ABS(
        NetInvoiceGBP - (ShippedCases * NetUnitPriceGBP)
      ) > 0.01;



-- Check whether COGS matches ShippedCases × StandardCostPerCaseGBP
-- This confirms that the cost of delivered goods has been calculated correctly
SELECT COUNT(*) AS InvalidCOGSRows
FROM dbo.DeliveryLines
WHERE ABS(
        COGSGBP - (ShippedCases * StandardCostPerCaseGBP)
      ) > 0.01;



-- Check whether every delivery links to a valid sales order line
-- This confirms that shipped goods can be traced back to the original customer order
SELECT COUNT(*) AS InvalidOrderLineLinks
FROM dbo.DeliveryLines d
LEFT JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID
WHERE s.OrderLineID IS NULL;


-- Check whether any order line was shipped more than the customer actually requested
-- Deliveries are grouped first because one order line can have multiple shipments
SELECT COUNT(*) AS OverShippedOrderLines
FROM (
    SELECT
        d.OrderLineID,
        SUM(d.ShippedCases) AS TotalShippedCases
    FROM dbo.DeliveryLines d
    GROUP BY d.OrderLineID
) d
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID
WHERE d.TotalShippedCases > (s.OrderedCases - s.CancelledCases);


-- Check how many sales order lines were fulfilled using more than one delivery
-- This is important because one order line can be split across several shipments
SELECT COUNT(*) AS OrderLinesWithMultipleDeliveries
FROM (
    SELECT
        OrderLineID
    FROM dbo.DeliveryLines
    GROUP BY OrderLineID
    HAVING COUNT(*) > 1
) x;


-- Show how many deliveries were needed per sales order line
-- This helps us understand how often customer demand was split across shipments
SELECT
    DeliveryCount,
    COUNT(*) AS OrderLineCount
FROM (
    SELECT
        OrderLineID,
        COUNT(*) AS DeliveryCount
    FROM dbo.DeliveryLines
    GROUP BY OrderLineID
) x
GROUP BY DeliveryCount
ORDER BY DeliveryCount;


-- Check for missing values in important delivery fields
-- DeliveredDate can be NULL when a shipment is still InTransit
SELECT
    SUM(CASE WHEN OrderLineID IS NULL THEN 1 ELSE 0 END) AS MissingOrderLineID,
    SUM(CASE WHEN DispatchDate IS NULL THEN 1 ELSE 0 END) AS MissingDispatchDate,
    SUM(CASE WHEN DeliveredDate IS NULL THEN 1 ELSE 0 END) AS MissingDeliveredDate,
    SUM(CASE WHEN ShippedCases IS NULL THEN 1 ELSE 0 END) AS MissingShippedCases,
    SUM(CASE WHEN NetInvoiceGBP IS NULL THEN 1 ELSE 0 END) AS MissingInvoice,
    SUM(CASE WHEN COGSGBP IS NULL THEN 1 ELSE 0 END) AS MissingCOGS,
    SUM(CASE WHEN FreightGBP IS NULL THEN 1 ELSE 0 END) AS MissingFreight,
    SUM(CASE WHEN CarrierCode IS NULL THEN 1 ELSE 0 END) AS MissingCarrier,
    SUM(CASE WHEN DeliveryStatus IS NULL THEN 1 ELSE 0 END) AS MissingStatus
FROM dbo.DeliveryLines;


-- Check how deliveries are distributed across carriers
-- This helps us understand which transport providers handle the shipment volume
SELECT
    CarrierCode,
    COUNT(*) AS DeliveryLineCount
FROM dbo.DeliveryLines
GROUP BY CarrierCode
ORDER BY DeliveryLineCount DESC;


-- Compare average delivery time by carrier
-- This helps us see whether some carriers take longer to deliver than others
SELECT
    CarrierCode,
    AVG(CAST(DATEDIFF(DAY, DispatchDate, DeliveredDate) AS DECIMAL(10,2))) AS AvgDeliveryDays
FROM dbo.DeliveryLines
WHERE DeliveredDate IS NOT NULL
GROUP BY CarrierCode
ORDER BY AvgDeliveryDays;


-- Compare late deliveries by carrier
-- A delivery is late when it arrives after the promised customer date
SELECT
    d.CarrierCode,
    COUNT(*) AS DeliveredLines,
    SUM(
        CASE
            WHEN d.DeliveredDate > s.PromisedDate THEN 1
            ELSE 0
        END
    ) AS LateDeliveries
FROM dbo.DeliveryLines d
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID
WHERE d.DeliveredDate IS NOT NULL
GROUP BY d.CarrierCode
ORDER BY d.CarrierCode;



-- Calculate the late-delivery percentage for each carrier
-- Percentage is fairer than raw counts when comparing carrier performance
SELECT
    d.CarrierCode,
    COUNT(*) AS DeliveredLines,

    SUM(
        CASE
            WHEN d.DeliveredDate > s.PromisedDate THEN 1
            ELSE 0
        END
    ) AS LateDeliveries,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN d.DeliveredDate > s.PromisedDate THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct

FROM dbo.DeliveryLines d

JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID

WHERE d.DeliveredDate IS NOT NULL

GROUP BY d.CarrierCode
ORDER BY LateDeliveryRatePct DESC;



-- Compare late-delivery rates by carrier and warehouse
-- This helps check whether CAR03 is slower everywhere or only in certain locations
SELECT
    s.WarehouseID,
    d.CarrierCode,
    COUNT(*) AS DeliveredLines,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN d.DeliveredDate > s.PromisedDate THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct

FROM dbo.DeliveryLines d
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID

WHERE d.DeliveredDate IS NOT NULL

GROUP BY
    s.WarehouseID,
    d.CarrierCode

ORDER BY
    s.WarehouseID,
    LateDeliveryRatePct DESC;



-- Compare carrier late rates after excluding WH03
-- This checks whether CAR03's poor result is mainly caused by the WH03 combination
SELECT
    d.CarrierCode,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN d.DeliveredDate > s.PromisedDate THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct

FROM dbo.DeliveryLines d
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID

WHERE d.DeliveredDate IS NOT NULL
  AND s.WarehouseID <> 'WH03'

GROUP BY d.CarrierCode
ORDER BY LateDeliveryRatePct DESC;


-- Insight:
-- CAR03 has a higher overall late-delivery rate,
-- but the issue is mainly concentrated in the WH03 + CAR03 combination.


-- Compare average freight cost by carrier
-- This helps us see whether slower delivery performance is also costing more

SELECT
    CarrierCode,
    CAST(AVG(FreightGBP) AS DECIMAL(10,2)) AS AvgFreightGBP
FROM dbo.DeliveryLines
GROUP BY CarrierCode
ORDER BY AvgFreightGBP DESC;


-- Observation:
-- CAR03 and CAR02 have similar average freight cost,
-- while CAR01 is noticeably cheaper.
-- Carrier performance should be compared using both service and cost.

-- Compare average freight cost by warehouse and carrier
-- This helps identify whether higher freight cost is linked to specific locations

SELECT
    s.WarehouseID,
    d.CarrierCode,
    CAST(AVG(d.FreightGBP) AS DECIMAL(10,2)) AS AvgFreightGBP
FROM dbo.DeliveryLines d
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID
GROUP BY
    s.WarehouseID,
    d.CarrierCode
ORDER BY
    s.WarehouseID,
    AvgFreightGBP DESC;


-- Observation:
-- CAR01 is consistently the lowest-cost carrier across all warehouses.
-- CAR02 and CAR03 have similar freight costs.
-- CAR03's higher late-delivery issue appears concentrated at WH03, not across all warehouses.


-- Compare total freight spend by carrier
-- This shows the overall logistics cost impact, not just the average cost per delivery

SELECT
    CarrierCode,
    CAST(SUM(FreightGBP) AS DECIMAL(18,2)) AS TotalFreightGBP
FROM dbo.DeliveryLines
GROUP BY CarrierCode
ORDER BY TotalFreightGBP DESC;


-- Compare freight cost per shipped case by carrier
-- This gives a fairer cost comparison by adjusting for shipment size

SELECT
    CarrierCode,
    CAST(
        SUM(FreightGBP) / NULLIF(SUM(ShippedCases), 0)
        AS DECIMAL(10,2)
    ) AS FreightCostPerCaseGBP
FROM dbo.DeliveryLines
GROUP BY CarrierCode
ORDER BY FreightCostPerCaseGBP DESC;


-- Observation:
-- CAR01 has the lowest freight cost per shipped case at £0.47.
-- CAR02 and CAR03 are both higher at £0.62 per case.
-- This suggests CAR01 is more cost-efficient on freight.


-- Compare freight cost per shipped case by warehouse and carrier
-- This checks whether carrier cost efficiency is consistent across locations

SELECT
    s.WarehouseID,
    d.CarrierCode,
    CAST(
        SUM(d.FreightGBP) / NULLIF(SUM(d.ShippedCases), 0)
        AS DECIMAL(10,2)
    ) AS FreightCostPerCaseGBP
FROM dbo.DeliveryLines d
JOIN dbo.SalesOrderLines s
    ON d.OrderLineID = s.OrderLineID
GROUP BY
    s.WarehouseID,
    d.CarrierCode
ORDER BY
    s.WarehouseID,
    FreightCostPerCaseGBP DESC;


    -- Observation:
-- CAR01 remains the lowest-cost carrier per shipped case across all warehouses.
-- CAR02 and CAR03 are consistently more expensive at roughly £0.61-£0.62 per case.
-- This suggests the carrier cost difference is systematic rather than location-specific.


-- Compare revenue and gross profit by carrier
-- This helps assess carrier activity from a commercial perspective, not only cost

SELECT
    CarrierCode,

    -- Revenue generated from delivered goods
    CAST(SUM(NetInvoiceGBP) AS DECIMAL(18,2)) AS NetRevenueGBP,

    -- Gross profit before freight cost
    CAST(SUM(NetInvoiceGBP - COGSGBP) AS DECIMAL(18,2)) AS GrossProfitGBP,

    -- Profit remaining after freight cost
    CAST(SUM(NetInvoiceGBP - COGSGBP - FreightGBP) AS DECIMAL(18,2)) AS ProfitAfterFreightGBP

FROM dbo.DeliveryLines
GROUP BY CarrierCode
ORDER BY ProfitAfterFreightGBP DESC;


-- Compare profit margin after freight by carrier
-- This shows how much profit remains from each £100 of dispatch revenue

SELECT
    CarrierCode,

    CAST(
        100.0 * SUM(NetInvoiceGBP - COGSGBP - FreightGBP)
        / NULLIF(SUM(NetInvoiceGBP), 0)
        AS DECIMAL(5,2)
    ) AS ProfitAfterFreightMarginPct

FROM dbo.DeliveryLines
GROUP BY CarrierCode
ORDER BY ProfitAfterFreightMarginPct DESC;


-- Observation:
-- CAR01 has the highest profit-after-freight margin at 32.80%.
-- CAR02 and CAR03 are slightly lower at about 32.34%-32.36%.
-- The difference is mainly linked to CAR01's lower freight cost.