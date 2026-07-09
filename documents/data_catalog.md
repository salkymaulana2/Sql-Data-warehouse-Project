# Gold Layer — Data Catalog

## Overview

The Gold layer is the final, analytics-ready stage of the data warehouse pipeline. Data here has been cleaned in the Silver layer and modeled into a **star schema** — two dimension tables and one fact table — designed for reporting, segmentation, and KPI analysis.

All three objects are implemented as **SQL views** built on top of the Silver layer, meaning they always reflect the latest processed data without storing duplicate physical records.

---

## 1. `gold.dim_customers`

**Purpose:** Customer dimension table enriched by joining CRM and ERP source systems. Contains demographic, geographic, and account information per customer.

**Source tables:** `silver.crm_cust_info` + `silver.erp_cust_az12` + `silver.erp_loc_a101`

| Column | Data Type | Description |
|---|---|---|
| `customer_key` | INT | Surrogate key generated with `ROW_NUMBER()` — unique identifier within this warehouse |
| `customer_id` | INT | Original numeric ID from the CRM source system |
| `customer_number` | NVARCHAR(50) | Alphanumeric business identifier used for customer tracking |
| `first_name` | NVARCHAR(50) | Customer first name, trimmed and cleaned from source |
| `last_name` | NVARCHAR(50) | Customer last name, trimmed and cleaned from source |
| `country` | NVARCHAR(50) | Country of residence, normalized from ERP location data (e.g. `'DE'` → `'Germany'`) |
| `marital_status` | NVARCHAR(50) | Marital status, normalized from coded values (e.g. `'S'` → `'Single'`, `'M'` → `'Married'`) |
| `gender` | NVARCHAR(50) | Gender, sourced primarily from CRM with ERP as fallback; normalized to `'Male'` / `'Female'` / `'n/a'` |
| `birthdate` | DATE | Date of birth — future dates were set to `NULL` during Silver cleaning |
| `create_date` | DATE | Date the customer account was originally created in the source system |

---

## 2. `gold.dim_products`

**Purpose:** Product dimension table combining product details from the CRM system with category and subcategory data from the ERP. Only current products are included — historical records (where `prd_end_dt IS NOT NULL`) are filtered out.

**Source tables:** `silver.crm_prd_info` + `silver.erp_px_cat_g1v2`

| Column | Data Type | Description |
|---|---|---|
| `product_key` | INT | Surrogate key generated with `ROW_NUMBER()` ordered by start date and product key |
| `product_id` | INT | Original numeric product ID from the CRM source system |
| `product_number` | NVARCHAR(50) | Structured alphanumeric product code extracted from the raw product key |
| `product_name` | NVARCHAR(50) | Full descriptive product name including type, color, and size where applicable |
| `category_id` | NVARCHAR(50) | Extracted category identifier derived from the raw product key during Silver transformation |
| `category` | NVARCHAR(50) | High-level product classification joined from ERP (e.g. `'Bikes'`, `'Components'`) |
| `subcategory` | NVARCHAR(50) | More specific product type within the category (e.g. `'Mountain Bikes'`, `'Helmets'`) |
| `maintenance` | NVARCHAR(50) | Whether the product requires maintenance — sourced from ERP category data |
| `cost` | INT | Base product cost in whole currency units; nulls replaced with `0` during Silver cleaning |
| `product_line` | NVARCHAR(50) | Product line normalized from coded values (e.g. `'M'` → `'Mountain'`, `'R'` → `'Road'`) |
| `start_date` | DATE | Date the product became active — used as the sort key for surrogate key generation |

---

## 3. `gold.fact_sales`

**Purpose:** Central fact table storing all sales transaction line items. Links to both dimension tables via surrogate keys. Used as the primary table for all revenue, volume, and trend analysis.

**Source tables:** `silver.crm_sales_details` joined to `gold.dim_products` and `gold.dim_customers`

| Column | Data Type | Description |
|---|---|---|
| `order_number` | NVARCHAR(50) | Unique sales order identifier (e.g. `'SO54496'`) |
| `product_key` | INT | FK → `gold.dim_products.product_key` |
| `customer_key` | INT | FK → `gold.dim_customers.customer_key` |
| `order_date` | DATE | Date the order was placed — invalid integer-format dates were cleaned in Silver |
| `shipping_date` | DATE | Date the order was shipped to the customer |
| `due_date` | DATE | Payment due date for the order |
| `sales_amount` | INT | Total sale value for the line item — recalculated in Silver where original values were missing or inconsistent |
| `quantity` | INT | Number of units ordered per line item |
| `price` | INT | Unit price per product — derived from `sales_amount / quantity` where original value was invalid |
