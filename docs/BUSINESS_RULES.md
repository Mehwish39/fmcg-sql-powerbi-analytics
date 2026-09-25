# Business rules and modeling decisions

## Reporting scope

- Fictional multi-category manufacturer; four factory/warehouse pairs: PL01/WH01 through PL04/WH04. Regions map in order to North, South, East, West.
- Historical coverage: 2024-01-01 through 2025-12-31. Cutoff: 2025-12-31 end of day. Some purchase orders were raised in 2023 and some promises extend into 2026. No future actual transactions are included.
- All amounts GBP, excluding VAT. Finished goods measured in cases; SKU UnitsPerCase supports conversion to eaches. Do not treat one case of every SKU as identical consumption or weight.
- Product, customer and location attributes are static in this exercise. Customers are outlet accounts; all predate the reporting window. No personal contact details.

## Transaction behavior

- Order header values repeat on order lines. OrderID and LineNumber form a unique business key. Customers, order dates and promised dates are shared across each order's lines.
- Cancellations are whole lines and excluded from service demand. Once a scheduled dispatch attempt occurs, any unshipped balance is closed short; no retry/backorder process is simulated. Lines awaiting an attempt at cutoff remain Open. InTransit status takes precedence when any shipment has not arrived, so calculate shortages from quantities, not status alone.
- DeliveryLines are dispatch allocations and may split one order line. All shipped goods are invoiced at dispatch for this exercise; arrival timing is used for service metrics. No invoice header, taxes or receivables are modeled.
- NetUnitPriceGBP is rounded to two decimals before multiplying by cases. Credits use the original invoice price. Always use decimal monetary types in SQL.
- In-transit goods have blank DeliveredDate. They have left stock and were invoiced. A blank arrival is not bad data.
- Returns are non-resaleable and destroyed immediately after receipt. They reduce revenue through credits; there is no stock restoration or COGS reversal. Original dispatch COGS already contains the product cost. Do not subtract the returned product cost twice. Handling is additional expense.
- There is at most one return credit per delivery allocation. Only returns received by cutoff exist. Short Shelf Life is a supplied reason, not independently verifiable expiry data.

## Production and inventory

- Every SKU can be produced at each site. Good output transfers into its co-located warehouse on production date, with no transfer lead time.
- Production includes completed batches only. ProducedCases = GoodCases + RejectedCases. Planned output need not equal produced output. LineCode is unique only within a plant.
- Initial opening inventory is 300 cases per SKU/warehouse. No purchases of finished goods, inter-warehouse transfers, restored returns or adjustments outside WriteOffCases are modeled.
- Opening + good production receipts - dispatches - warehouse writeoffs = closing stock every day. Closing values use the current standard cost, so value movements also reflect standard cost revaluation.
- Warehouse writeoffs are separate from production rejects and customer returns. They are not included in the defined gross-profit KPI; show writeoff cost separately if extending operational contribution.
- Inventory is semi-additive: sum across SKUs and warehouses on one date, never sum daily closing balances as total stock.
- ActualConversionCostGBP is batch labour and overhead only. It is not a full actual unit manufacturing cost and must not be added to dispatch COGS to calculate gross profit.
- No shipment-to-production-batch bridge exists. Do not claim batch recall traceability, validated shelf-life aging, or supplier-to-finished-product causality.

## Procurement

- Materials are ingredients (KG) and packaging (PCS), not finished-goods products. The 20 materials and 24 suppliers are intentionally repeated on receipt exports.
- One completed PO line per receipt; OrderedQty = ReceivedQty includes rejected units. No supplier credit accounting or open purchase orders are included.
- Supplier performance describes received POs only. It cannot measure overdue unreceived orders or full procurement backlog.
- No bill of materials or raw-material consumption exists, so procurement cannot be reconciled directly to production output. Do not join raw receipts to production rows on plant/date.

## Intentional data preparation

- A small number of Channel labels contain uppercase text and surrounding spaces. Preserve raw values, clean with TRIM/UPPER or a mapping, and document affected counts.
- Some sales rep assignments are missing. Keep these as Unassigned in reporting and do not invent rep codes.
- Empty PromoCode means no promotion. Empty DeliveredDate means still in transit. Treat NULL according to the field meaning rather than replacing every missing value with zero.
- Structural keys and numeric balances are valid. Operational exceptions (late arrivals, shortages, rejects) should remain in the data.

## Planned Power BI model

Derive DimProduct from distinct stable SKU attributes in SalesOrderLines, DimCustomer from cleaned Customers, DimLocation from warehouse/plant codes, DimSupplier and DimMaterial from receipts, and a continuous DimDate. The seven-source-table minimum does not apply to derived dimensions.

Create separate facts for orders, dispatches, returns, production, inventory and procurement. Enrich dispatches with customer/product/location keys through their order line; enrich returns through dispatch/order lookups in SQL. Keep unique row keys. Use one-to-many, single-direction dimension-to-fact relationships. Do not link facts directly in the Power BI model.

Use explicit date roles: order date for demand, dispatch date for invoiced sales/COGS, return date for credits, production date, snapshot date and receipt date. Alternative date roles need inactive relationships with explicit measures, or separate role-playing date dimensions. Date selection for service and return cohorts must follow the question specifications.

## Simulation boundaries

The source is reproducible pseudo-random data with planted patterns, not a statistically representative industry benchmark. It contains seasonal beverage demand, promotional discounting, a standard-cost increase, a period of plant disruption and supplier/carrier differences. Investigate these patterns; correlation is not proof of business causation. This package does not yet contain a live refresh pipeline or a completed report.
