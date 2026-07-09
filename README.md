# 🏗️ SQL Data Warehouse & Analytics Project

A guided end-to-end data warehousing and analytics project built on Microsoft SQL Server, following the Medallion Architecture pattern. This project covers the full data pipeline — from raw ingestion to business-ready reporting — and serves as a portfolio piece demonstrating practical skills in data engineering and SQL analytics.

> ⚠️ *This project was completed by following a guided tutorial. All scripts were written and understood independently as part of my learning process.*

---

## 🧱 Architecture Overview

This project follows the **Medallion Architecture**, organizing data across three progressive layers:

```
CRM Sources ──┐
              ├──► Bronze (Raw) ──► Silver (Clean) ──► Gold (Analytics-Ready)
ERP Sources ──┘
```

| Layer | Role |
|---|---|
| **Bronze** | Raw data loaded as-is from CSV files via `BULK INSERT` |
| **Silver** | Cleaned, standardized, and deduplicated data ready for modeling |
| **Gold** | Star schema views (fact + dimensions) built for reporting and analytics |

---

## 📖 What This Project Covers

### 1. 🔧 Data Engineering — Building the Warehouse

**Sources:** Two systems (CRM + ERP), 6 raw tables total, loaded from CSV files into SQL Server.

**Bronze Layer**
- Tables created per source system (`crm_*` and `erp_*`)
- Stored procedure (`bronze.load_bronze`) handles truncate-and-reload with `BULK INSERT`
- Includes load-time logging per table and `TRY/CATCH` error handling

**Silver Layer**
- Stored procedure (`silver.load_silver`) runs all transformations Bronze → Silver
- Key cleaning steps applied:
  - Deduplication using `ROW_NUMBER()` to keep the latest customer record
  - Normalizing coded values: gender (`M/F` → `Male/Female`), marital status (`S/M` → `Single/Married`), country codes → full names
  - Stripping invalid ID prefixes and fixing string formatting with `TRIM()` and `REPLACE()`
  - Converting integer-format dates to proper `DATE` type
  - Setting future birthdates to `NULL`
  - Recalculating sales amounts where original values were missing or inconsistent
  - Deriving product end dates using `LEAD()` window function
- Audit column `dwh_create_date` added to all silver tables

**Gold Layer**
- Built as SQL **views** (no physical tables) for always-current data
- Star schema with three objects:
  - `gold.dim_customers` — joins CRM + ERP customer data, resolves gender conflicts between sources
  - `gold.dim_products` — joins product info with category lookup, filters out historical records
  - `gold.fact_sales` — links transactions to product and customer dimension keys
- Surrogate keys generated with `ROW_NUMBER() OVER (ORDER BY ...)`

---

### 2. 📊 Analytics & Reporting — SQL Analysis

Built on top of the Gold layer, covering 60,000+ sales transactions, 18,000+ customers, and 295 products.

| Analysis | What It Does |
|---|---|
| **Change Over Time** | Monthly sales, customer count, and quantity trends |
| **Cumulative Analysis** | Running total sales and moving average price using `SUM OVER` / `AVG OVER` |
| **YoY Performance** | Product sales vs. prior year and historical average using `LAG()` |
| **Part-to-Whole** | Category % contribution to total revenue |
| **Segmentation** | Products by cost range; customers by VIP / Regular / New |
| **Customer Report** | KPIs: recency, avg order value, avg monthly spend, age group, segment |
| **Product Report** | KPIs: performance tier, recency, avg selling price, avg monthly revenue |

---

## 🗂️ Repository Structure

```
data-warehouse-project/
│
├── datasets/               # Raw CSV files (CRM and ERP sources)
│
├── docs/                   # Architecture diagrams and documentation
│   ├── data_architecture.drawio
│   ├── data_flow.drawio
│   ├── data_models.drawio
│   ├── etl.drawio
│   ├── data_catalog.md
│   └── naming-conventions.md
│
├── scripts/
│   ├── bronze/             # DDL + load stored procedure for Bronze layer
│   ├── silver/             # DDL + load stored procedure for Silver layer
│   └── gold/               # DDL views for Gold layer (dim + fact)
│
├── tests/                  # Data quality checks
├── README.md
└── .gitignore
```

---

## ⚙️ Setup Instructions

1. Install [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) and [SSMS](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
2. Run `scripts/init_database.sql` to create the `DataWarehouse` database and the three schemas
3. Run `scripts/bronze/ddl_bronze.sql` to create Bronze tables
4. Update the file paths inside `scripts/bronze/proc_load_bronze.sql` to match your local CSV locations, then execute it
5. Run `scripts/silver/ddl_silver.sql`, then `proc_load_silver.sql`
6. Run `scripts/gold/ddl_gold.sql` to create the Gold views
7. Run any of the analytics scripts against the Gold layer

---

## 🛠️ Tech Stack & Concepts Used

- **Database:** Microsoft SQL Server
- **Language:** T-SQL
- **Concepts:** Medallion Architecture, Star Schema, ETL Pipeline, Stored Procedures, Window Functions (`ROW_NUMBER`, `LAG`, `LEAD`, `SUM OVER`, `AVG OVER`), CTEs, Data Cleansing, Data Modeling, SQL Views, Error Handling
