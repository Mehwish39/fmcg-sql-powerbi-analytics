# FMCG ERP Analytics | SQL Server + Power BI

A portfolio case study analysing a synthetic FMCG ERP dataset across **sales, customer profitability, service, inventory operations, manufacturing and supplier performance**.

> **Portfolio note:** All data is synthetic. This is an independent learning project, not client or employment work.
>
> ## Dashboard Preview

![FMCG ERP Analytics Executive Overview](screenshots/executive-overview.png)

## Project highlights

- Built a reporting layer in **SQL Server** from 7 ERP-style source tables.
- Profiled and validated data quality, keys, date logic, inventory reconciliation and transaction behaviour.
- Designed a **Power BI star schema** with shared dimensions and separate fact tables.
- Created DAX measures for profitability, LINE OTIF, unfulfilled demand, manufacturing performance and supplier KPIs.
- Built four management-facing report pages with drillable and interactive visuals.
- Reconciled important Power BI totals back to SQL and documented modeling assumptions and limitations.

## Dashboard pages

### 1. Executive Overview
Management-level summary of sales, contribution, service and operational risk.

Key headline metrics in the completed report include:
- **Total Orders:** 73.10K
- **Net Sales:** £358.12M
- **Contribution:** £114.50M
- **Contribution Margin:** 31.97%
- **LINE OTIF:** 61.14%
- **Unfulfilled Order Value:** £531.80K

### 2. Sales & Customers
Explores sales drivers, customer contribution, large-account profitability and product sales versus gross-margin performance.

### 3. Supply & Service
Focuses on LINE OTIF, carrier lateness, unfulfilled demand and warehouse inventory write-offs.

### 4. Manufacturing & Suppliers
Compares plan attainment, rejection rates, downtime deterioration, supplier delivery reliability, supplier quality and purchase-price variance.

## Selected findings

- 2025 net sales are higher than 2024 across all product categories in the report.
- **WH03** has the lowest LINE OTIF at **53.58%** and accounts for **45.26% (£240.68K)** of unfulfilled order value.
- **CAR03** has the highest late-delivery share at **40.86%**.
- **PL03** has the weakest production-plan attainment and shows a major downtime increase from roughly **June to September**.
- Supplier receipt reliability varies materially; the supplier scorecard highlights low-performing suppliers and the PPV visual surfaces suppliers driving unfavorable purchase-price variance.

These are findings from a reproducible synthetic simulation, not industry benchmarks or causal claims.

## Data model

The Power BI model uses shared dimensions filtering separate fact tables in one-to-many, single-direction relationships.

**Dimensions**
- DimDate
- DimCustomer
- DimProduct
- DimLocation
- DimSupplier
- DimMaterial
- DimPromotion

**Facts**
- FactSalesOrders
- FactDeliveries
- FactReturns
- FactProduction
- FactInventory
- FactProcurement

Date roles follow the business process: order date for demand, dispatch date for invoiced sales/COGS, return date for credits, production date, inventory snapshot date and procurement receipt date.

## Tools & skills demonstrated

**SQL Server**
- Source profiling and validation
- Data cleaning and reporting views
- Grain-aware joins and reconciliation
- Dimension/fact preparation
- Inventory and operational validation

**Power BI / DAX**
- Star-schema modeling
- Explicit measures and KPI logic
- Date modeling and filter context
- LINE OTIF logic
- Profitability and contribution analysis
- Unfulfilled-demand analysis
- Manufacturing and supplier performance
- Interactive decomposition, scatter, lollipop, scorecard and service visuals

**Power Query**
- Fact enrichment using order-line keys
- Promotion classification
- Delivery timeliness classification
- Inventory operational fields

## Repository structure

```text
.
├── README.md
├── data/                    # 7 synthetic ERP CSV extracts
├── docs/                    # business rules, dictionary, questions, validation
├── sql/                     # SQL profiling, cleaning and model validation scripts
├── scripts/                 # reproducible synthetic-data generator
├── powerbi/                 # Power BI PBIX report file
├── screenshots/             # dashboard and model screenshots
└── presentation/            # recruiter-friendly project presentation
```

## Data

The project contains seven synthetic ERP-style extracts covering 2024–2025:

| Source | Rows |
|---|---:|
| Customers | 12,000 |
| SalesOrderLines | 145,527 |
| DeliveryLines | 168,005 |
| ReturnLines | 20,188 |
| ProductionBatches | 58,480 |
| InventoryDaily | 175,440 |
| ProcurementReceipts | 17,544 |

See [`docs/DATA_DICTIONARY.md`](docs/DATA_DICTIONARY.md) and [`docs/BUSINESS_RULES.md`](docs/BUSINESS_RULES.md) for definitions and modeling rules.

## Power BI report

- **PBIX:** [`powerbi/FMCG ERP Analytics.pbix`](powerbi/FMCG%20ERP%20Analytics.pbix)
- **Portfolio presentation:** [`presentation/FMCG_ERP_Analytics_Portfolio_Presentation.pptx`](presentation/FMCG_ERP_Analytics_Portfolio_Presentation.pptx)

The report was developed against a local SQL Server instance and uses **Import mode**. Recruiters can open the PBIX and inspect the report, model and imported data without access to the original server. Refreshing the report requires recreating the SQL Server source from the supplied data/scripts or changing the data-source connection.


## Reproduce the synthetic dataset

The source dataset can be regenerated with:

```bash
python scripts/generate_data.py
```

The reporting database used for the portfolio is `FMCG_Analytics`. SQL scripts are stored in execution order under [`sql/`](sql/).

## Important analytical boundaries

- Inventory closing balances are snapshots and are not summed across dates.
- In-transit deliveries can have blank delivered dates by design.
- Returns reduce revenue through credits and add handling cost; returned product cost is not subtracted twice.
- Supplier performance covers received purchase orders only.
- No BOM or shipment-to-production-batch bridge exists, so supplier-to-finished-product causality and batch recall traceability are not claimed.
- Some advanced analyses in the original management brief (for example full days-of-cover and cohort-based return-rate extensions) are documented as future enhancements rather than overstated as completed findings.

## Supporting documentation

- [`docs/MANAGEMENT_QUESTIONS.md`](docs/MANAGEMENT_QUESTIONS.md)
- [`docs/BUSINESS_RULES.md`](docs/BUSINESS_RULES.md)
- [`docs/DATA_DICTIONARY.md`](docs/DATA_DICTIONARY.md)
- [`docs/VALIDATION_REPORT.md`](docs/VALIDATION_REPORT.md)

---

**Built as a portfolio project to demonstrate SQL, Power BI, DAX, Power Query, data modeling, validation and business storytelling.**
