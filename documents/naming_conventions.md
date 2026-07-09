# Naming Conventions

This document explains the naming standards followed across all layers of this data warehouse — schemas, tables, views, columns, and stored procedures. Keeping these consistent makes the codebase easier to read, debug, and extend.

---

## General Principles

- Use **snake_case** throughout — lowercase letters with underscores separating words
- All names written in **English**
- Never use SQL reserved words as object names

---

## Table & View Naming

### Bronze & Silver Layers

Both layers preserve the original source system name as a prefix, keeping traceability back to where the data came from. Table names are not renamed from their source.

**Pattern:** `<sourcesystem>_<entity>`

| Part | Description |
|---|---|
| `<sourcesystem>` | Name of the source system: `crm` or `erp` |
| `<entity>` | Original table name from that source system |

**Examples:**
- `crm_cust_info` → customer info from the CRM system
- `erp_px_cat_g1v2` → product category data from the ERP system

> The same pattern applies to both Bronze and Silver — Silver tables mirror Bronze names since they represent the same entities, just cleaned.

---

### Gold Layer

Gold uses business-friendly names instead of source system names. Tables (implemented as views here) are prefixed by their role in the star schema.

**Pattern:** `<category>_<entity>`

| Part | Description |
|---|---|
| `<category>` | Role of the object in the data model (see glossary below) |
| `<entity>` | Business domain name, readable and descriptive |

**Examples:**
- `dim_customers` → customer dimension table
- `dim_products` → product dimension table
- `fact_sales` → sales fact table

#### Category Prefix Glossary

| Prefix | Role | Examples |
|---|---|---|
| `dim_` | Dimension table | `dim_customers`, `dim_products` |
| `fact_` | Fact table | `fact_sales` |
| `report_` | Reporting table | `report_customers`, `report_sales_monthly` |

---

## Column Naming

### Surrogate Keys

Every dimension table has a surrogate key generated within the warehouse (using `ROW_NUMBER()`). These always follow the pattern:

**Pattern:** `<table_name>_key`

**Examples:**
- `customer_key` → surrogate key in `dim_customers`
- `product_key` → surrogate key in `dim_products`

---

### Technical / Audit Columns

System-generated metadata columns are prefixed with `dwh_` to clearly separate them from business data columns.

**Pattern:** `dwh_<column_name>`

**Examples:**
- `dwh_create_date` → timestamp of when the record was loaded into the warehouse layer

> In this project, `dwh_create_date` is added to all Silver tables with `DEFAULT GETDATE()` so every row carries a load timestamp automatically.

---

## Stored Procedure Naming

Load procedures follow a simple, consistent pattern tied to the layer they populate:

**Pattern:** `load_<layer>`

| Procedure | What it does |
|---|---|
| `bronze.load_bronze` | Truncates and reloads all Bronze tables from CSV source files |
| `silver.load_silver` | Transforms and loads cleaned data from Bronze into Silver |
