# Analysis assignment

For each answer save a SQL query, reconcile the result, select a useful visual, write two evidence-based observations and recommend one action with an owner and a limitation. Do not invent findings before running the analysis.

1. **Sales growth:** How did monthly net sales change in 2025 versus 2024, and which categories, regions and channels contributed most to the change?
2. **Margin pressure:** Which products gained sales but lost gross margin, and how did selling prices, discounts and standard costs change?
3. **Customer profitability:** Which customers generate the most contribution after product cost, freight, return credits and return handling, and which large accounts deserve review?
4. **Promotion performance:** How do promoted and non-promoted sales compare on case volume, realized price and contribution within the same SKU, channel and month? Is increased volume accompanied by lower margins?
5. **Customer service:** What proportion of eligible order lines arrived on time and in full, and which warehouses and carriers are associated with failures?
6. **Unfulfilled demand:** Where are short shipments concentrated, and how much unfulfilled order value is associated with those shortages?
7. **Inventory deployment:** Which SKUs and warehouses are below safety stock or carry excessive days of cover, and how much stock value is tied up at the reporting cutoff?
8. **Manufacturing performance:** Which plants and lines have the greatest production-plan shortfall, rejection rate and downtime, and when did performance deteriorate?
9. **Supplier performance:** Which suppliers have the poorest receipt timeliness, quality and purchase-price variance, assessed within comparable materials and units?
10. **Returns:** Which products, customers and regions drive return credits and return rates, and what actions should management investigate first?

## Metric specifications

| Question | Calculation and scope | Suggested visual / SQL skill |
|---|---|---|
| 1 | Net sales = dispatch-date NetInvoiceGBP minus return-date CreditAmountGBP. Compare the same calendar months. Attribute returns to the original customer and SKU. | Monthly trend and category change bars; CTEs, LAG |
| 2 | Gross profit = net sales minus dispatch COGS. Gross margin = gross profit / net sales; NULL when denominator is zero. Weighted price and cost = relevant amount / shipped cases. | Sales versus margin scatter; weighted aggregation |
| 3 | Contribution = gross profit - dispatch freight - return-date handling. Includes only these specified costs. Rank with DENSE_RANK, compare absolute and percentage contribution. | Ranked accounts and drill-through |
| 4 | Compare like SKU-channel-month groups; require both promo and non-promo observations. Use orders as cohorts and match their dispatches and credits through cutoff. No causal ROI or incremental-sales claim. | Comparison matrix; conditional aggregates |
| 5 | Eligible = noncancelled lines with PromisedDate <= cutoff. Pass if cumulative cases with DeliveredDate <= PromisedDate equals net ordered cases. Denominator includes short and undelivered due lines. Call this LINE OTIF, not order OTIF. | Warehouse matrix; preaggregation and conditional logic |
| 6 | For due noncancelled lines: max(net ordered - total shipped by cutoff, 0). Value at rounded discounted order price. This is unfulfilled order value, not proven lost revenue or a measured cause of shortage. | SKU/warehouse Pareto; window running totals |
| 7 | Ending value sums only latest common snapshot date. Cover = closing cases / (cases dispatched over the last 28 calendar days / 28). Zero demand yields NULL plus a no-demand flag. Cover >60 days is an analyst-selected review threshold. | Cover versus stock value; rolling date window |
| 8 | Plan attainment = sum GoodCases / sum PlannedCases; quality yield = sum GoodCases / sum ProducedCases; downtime share = sum DowntimeMinutes / sum ScheduledMinutes. Do not call these OEE. | Plant/month trends; grouped ratios |
| 9 | Receipt on time = ActualReceiptDate <= PromisedReceiptDate, divided by receipt count. Reject rate weighted within MaterialID/UOM. PPV = sum((ActualUnitPriceGBP - ContractUnitPriceGBP) * ReceivedQty), positive unfavorable. | Supplier scorecard; grouped rates and ranking |
| 10 | Operational return quantity rate uses dispatch cohorts with DispatchDate <= cutoff - 35 days, and their linked returns through cutoff, to reduce recent-cohort bias. Credits posted in a month are a separate period-flow measure. | Reason Pareto and cohort matrix; multi-table joins |

For carrier OTIF investigation, an order line may have multiple carrier allocations. Use carrier shipment lateness rates alongside line OTIF, or assign a documented primary-carrier rule. Do not duplicate the line denominator across carriers and then sum it.

Avoid a flat join of order lines to deliveries and returns before summing order demand: split dispatches multiply order quantities. Aggregate each child to its parent grain first. Join procurement and production through shared dimensions for side-by-side analysis, never by raw date/plant row matching.
