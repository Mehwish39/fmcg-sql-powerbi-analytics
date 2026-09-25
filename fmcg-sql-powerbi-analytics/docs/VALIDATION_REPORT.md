# Dataset validation

Validated in Python before delivery; SQL Server import has not yet been run.

- Customers >10000 rows: PASS
- Customers unique non-null primary key: PASS
- SalesOrderLines >10000 rows: PASS
- SalesOrderLines unique non-null primary key: PASS
- DeliveryLines >10000 rows: PASS
- DeliveryLines unique non-null primary key: PASS
- ReturnLines >10000 rows: PASS
- ReturnLines unique non-null primary key: PASS
- ProductionBatches >10000 rows: PASS
- ProductionBatches unique non-null primary key: PASS
- InventoryDaily >10000 rows: PASS
- InventoryDaily unique non-null primary key: PASS
- ProcurementReceipts >10000 rows: PASS
- ProcurementReceipts unique non-null primary key: PASS
- Order and line number unique: PASS
- Sales customer foreign keys valid: PASS
- Delivery dates, foreign keys and invoice arithmetic valid: PASS
- No overshipment: PASS
- Daily inventory continuity, production receipts, dispatch issues and values reconcile: PASS
- Return dates credits and quantities valid: PASS
- Procurement dates quantities invoices valid: PASS
- Customers CSV roundtrip row count: PASS
- SalesOrderLines CSV roundtrip row count: PASS
- DeliveryLines CSV roundtrip row count: PASS
- ReturnLines CSV roundtrip row count: PASS
- ProductionBatches CSV roundtrip row count: PASS
- InventoryDaily CSV roundtrip row count: PASS
- ProcurementReceipts CSV roundtrip row count: PASS

Intentional source-quality exercises: 123 channel labels may need case/space review; 106 missing sales rep assignments. Missing promotion codes and in-transit arrival dates are valid NULLs. No duplicate keys or orphan foreign keys were deliberately inserted.

## Analytical coverage checks

- SKU/channel/month groups containing both promoted and non-promoted order lines: 469.
- Order status counts: {"Closed": 141601, "Cancelled": 2794, "ClosedShort": 295, "InTransit": 443, "Open": 394}.
- Inventory snapshot coverage: {"below_safety": 971, "over_1000_cases": 158796}.
These checks establish exercise coverage, not completed management findings.
