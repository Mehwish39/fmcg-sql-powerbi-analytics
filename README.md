# FMCG ERP Analytics | SQL Server + Power BI

End-to-end analytics portfolio project using **SQL Server, Power BI, DAX, Power Query and Python** to analyse sales, profitability, customer service, manufacturing and supplier performance.

> **Portfolio note:** All data is synthetic. This is an independent analytics project created to demonstrate technical and business-analysis skills.

---

## Project Overview

This project simulates an FMCG ERP reporting environment covering **2024–2025**.

The objective was to transform raw ERP-style data into a structured reporting model and management-facing Power BI dashboards.

### Technology Stack

- **SQL Server** — profiling, validation, cleaning and reporting views
- **Power BI** — data model, dashboards and interactive analysis
- **DAX** — business KPIs and analytical measures
- **Power Query** — transformation and fact enrichment
- **Python** — synthetic data generation
- **Git / GitHub** — project documentation and version control

### Quick Links

- [Download / view the Power BI PBIX](powerbi/FMCG%20ERP%20Analytics.pbix)
- [View the project presentation](presentation/FMCG_ERP_Analytics_Portfolio_Presentation.pptx)
- [View SQL scripts](sql/)
- [View data dictionary](docs/DATA_DICTIONARY.md)
- [View business rules](docs/BUSINESS_RULES.md)

---

## What I Built

- Built a SQL Server reporting layer from **7 ERP-style source datasets**
- Profiled and validated keys, dates, inventory movements and transactional behaviour
- Created cleaning and analytical SQL views
- Designed a **star-schema Power BI model**
- Built reusable DAX measures for profitability, service, demand, manufacturing and procurement
- Used Power Query to enrich fact tables with analytical fields
- Created **4 management-facing Power BI report pages**
- Reconciled important Power BI results back to SQL
- Documented assumptions, business rules and analytical limitations

---

## Key Business Results

The completed report highlights several operational and commercial findings:

- **73.10K** total orders analysed
- **£358.12M** net sales
- **£114.50M** contribution
- **31.97%** contribution margin
- **61.14%** overall LINE OTIF
- **£531.80K** unfulfilled order value
- 2025 net sales are higher than 2024 across all product categories
- **WH03** has the lowest LINE OTIF at **53.58%**
- **WH03** contributes **45.26% (£240.68K)** of total unfulfilled order value
- **CAR03** has the highest late-delivery share at **40.86%**
- **PL03** shows the weakest production-plan attainment and a noticeable downtime increase from approximately **June to September**

> Results are generated from synthetic data and should not be interpreted as industry benchmarks or causal findings.

---

## Power BI Dashboard

The Power BI report contains four management-focused analytical pages.

### 1. Executive Overview

Provides a high-level view of:

- Total Orders
- Net Sales
- Contribution
- Contribution Margin
- LINE OTIF
- Unfulfilled Order Value
- Monthly sales performance
- Product-category performance
- Warehouse service performance
- Customer-channel mix

### 2. Sales & Customers

Analyses:

- Customer contribution
- Large-account profitability
- Product sales and gross-margin performance
- Regional and channel sales drivers
- Customer segmentation

### 3. Supply & Service

Focuses on:

- LINE OTIF by warehouse
- Carrier delivery performance
- Late vs on-time delivery share
- Unfulfilled cases
- Unfulfilled order value
- Products driving unfulfilled demand
- Warehouse inventory write-offs

### 4. Manufacturing & Suppliers

Analyses:

- Production plan attainment
- Production rejection rates
- Downtime trends
- Production output by plant
- Supplier on-time receipt performance
- Supplier reject rates
- Purchase Price Variance (PPV)

---

## Analytical Workflow

```text
Synthetic ERP CSV Data
        ↓
SQL Server
        ↓
Data Profiling & Validation
        ↓
Cleaning / Reporting Views
        ↓
Power BI Star Schema
        ↓
Power Query Transformations
        ↓
DAX Measures
        ↓
Interactive Management Dashboards
