# Data dictionary

All records are synthetic. UTF-8 comma-delimited CSV, header row, LF endings. Dates use YYYY-MM-DD. Empty CSV cells load as NULL in staging. All money is GBP excluding VAT. Quantity is cases unless specified. No thousands separators. SQL types below are suggested clean-layer types; initially stage raw columns as text.

## Customers

One retail outlet / customer account; CustomerID is the primary key.

Rows: 12,000

| Column | Meaning / suggested SQL type |
|---|---|
| CustomerID | int; primary key |
| CustomerName | varchar(80); fictional outlet name |
| Region | varchar(20); geographic sales region |
| Channel | varchar(30); raw ERP channel label; trim and standardize case |
| CustomerSegment | varchar(20); outlet size |
| OnboardDate | date; account activation |
| CreditLimitGBP | decimal(18,2); approved credit, not receivables |
| PaymentTermsDays | int; contractual credit days |
| SalesRepCode | varchar(20); blank means unassigned |

## SalesOrderLines

One order line; OrderLineID is primary key; OrderID has 1-3 lines.

Rows: 145,527

| Column | Meaning / suggested SQL type |
|---|---|
| OrderLineID | int; primary key |
| OrderID | varchar(20); order identifier |
| LineNumber | int; unique within order |
| OrderDate | date; order cohort date |
| PromisedDate | date; requested complete arrival |
| CustomerID | int; FK Customers |
| ProductID | varchar(12); finished-goods SKU |
| ProductName | varchar(80); stable SKU description |
| Category | varchar(30); product category |
| Brand | varchar(30); fictional brand |
| UnitsPerCase | int; eaches in one case |
| WarehouseID | varchar(12); ship-from co-located factory warehouse |
| OrderedCases | int; gross demand before cancellation |
| CancelledCases | int; cancelled demand, not service failure |
| ListPricePerCaseGBP | decimal(18,2); ex VAT price |
| DiscountRate | decimal(9,4); fraction, not percent points |
| PromoCode | varchar(20); blank means no promotion |
| OrderStatus | varchar(20); Cancelled, Open, InTransit, Closed or ClosedShort |

## DeliveryLines

One dispatch allocation against an order line; split dispatch records are possible.

Rows: 168,005

| Column | Meaning / suggested SQL type |
|---|---|
| DeliveryLineID | int; primary key |
| OrderLineID | int; FK SalesOrderLines |
| DispatchDate | date; stock issue and invoice recognition date |
| DeliveredDate | date nullable; blank means in transit at cutoff |
| ShippedCases | int; dispatched quantity |
| NetUnitPriceGBP | decimal(18,2); discounted invoice price per case |
| NetInvoiceGBP | decimal(18,2); shipped cases times net unit price |
| StandardCostPerCaseGBP | decimal(18,2); frozen dispatch-date standard cost |
| COGSGBP | decimal(18,2); shipped cases times standard cost |
| FreightGBP | decimal(18,2); shipment freight expense |
| CarrierCode | varchar(20); carrier identifier |
| DeliveryStatus | varchar(20); Delivered or InTransit |

## ReturnLines

One return credit against a delivery line; at most one in this simulation.

Rows: 20,188

| Column | Meaning / suggested SQL type |
|---|---|
| ReturnLineID | int; primary key |
| DeliveryLineID | int; FK DeliveryLines |
| ReturnDate | date; goods received and credit posted |
| ReturnedCases | int; not more than delivered cases |
| ReasonCode | varchar(30); return cause |
| CreditAmountGBP | decimal(18,2); quantity times original net invoice unit price |
| HandlingCostGBP | decimal(18,2); incremental return handling expense |
| Disposition | varchar(20); Destroyed; zero recovery value |

## ProductionBatches

One completed finished-goods production batch; no open work in progress.

Rows: 58,480

| Column | Meaning / suggested SQL type |
|---|---|
| BatchID | int; primary key |
| ProductionDate | date; completion and warehouse receipt date |
| ProductID | varchar(12); shared SKU key |
| PlantID | varchar(12); manufacturing site |
| WarehouseID | varchar(12); destination co-located warehouse |
| LineCode | varchar(20); plant-local line |
| PlannedCases | int; target batch quantity |
| ProducedCases | int; good plus rejected output |
| GoodCases | int; saleable quantity received |
| RejectedCases | int; production scrap |
| ScheduledMinutes | int; scheduled batch slot |
| DowntimeMinutes | int; within scheduled slot |
| DowntimeReason | varchar(30); dominant downtime reason |
| StandardCostPerCaseGBP | decimal(18,2); same cost schedule as dispatch |
| ActualConversionCostGBP | decimal(18,2); labour and overhead only, excludes materials |

## InventoryDaily

One end-of-day date x warehouse x SKU snapshot; SnapshotID is primary key.

Rows: 175,440

| Column | Meaning / suggested SQL type |
|---|---|
| SnapshotID | int; primary key |
| SnapshotDate | date; end of day |
| WarehouseID | varchar(12); shared location key |
| ProductID | varchar(12); shared SKU key |
| OpeningCases | int; previous day closing, except seeded opening |
| ProductionReceiptCases | int; good production received |
| ShippedCases | int; dispatch quantity; not arrival quantity |
| WriteOffCases | int; damaged warehouse stock removed |
| ClosingCases | int; opening + receipts - shipped - writeoffs |
| StandardCostPerCaseGBP | decimal(18,2); end-of-day standard cost |
| ClosingValueGBP | decimal(18,2); closing cases times standard cost |
| SafetyStockCases | int; operating policy threshold |

## ProcurementReceipts

One fully received PO line; POReceiptID is primary key. Received-PO cohort only.

Rows: 17,544

| Column | Meaning / suggested SQL type |
|---|---|
| POReceiptID | int; primary key |
| PONumber | varchar(20); one line per PO in simulation |
| SupplierID | varchar(12); shared supplier code |
| SupplierName | varchar(80); fictional supplier |
| MaterialID | varchar(12); raw material or packaging, not finished-goods SKU |
| MaterialName | varchar(80); material description |
| MaterialUOM | varchar(12); KG or PCS; never sum across UOM |
| PlantID | varchar(12); receiving site |
| PODate | date; purchase order date |
| PromisedReceiptDate | date; due date |
| ActualReceiptDate | date; actual receipt |
| OrderedQty | int; fully received gross quantity |
| ReceivedQty | int; includes rejected quantity |
| RejectedQty | int; supplier quality rejects |
| ContractUnitPriceGBP | decimal(18,2); agreed material rate |
| ActualUnitPriceGBP | decimal(18,2); invoiced material rate |
| InvoiceAmountGBP | decimal(18,2); gross receipt times actual price; no supplier credits modeled |
