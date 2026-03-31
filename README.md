# 🏭 dbt Retail Data Warehouse Lab

### *"Why did the data engineer break up with the spreadsheet? It couldn't handle relationships."*

A hands-on lab building a star schema data warehouse with dbt, PostgreSQL, SCD Type 2, and a full 3-layer transformation pipeline.

---

## 🚀 How to Run This Lab

### 1. Start PostgreSQL
```bash
docker-compose up -d
```

### 2. Load the raw data and create the star schema
```bash
# Get your container name first
docker ps

# Run the schema file
docker exec -i <container_name> psql -U dbtuser -d retail_db < schema.sql
```

### 3. Set up dbt
```bash
python -m venv dbt-env
source dbt-env/bin/activate
pip install dbt-postgres

dbt init retail_project
# When prompted: localhost / 5432 / dbtuser / dbtpass / retail_db / public
```

### 4. Run dbt models
```bash
cd retail_project
dbt debug       # confirm connection
dbt run         # build all models
dbt test        # run all tests
dbt docs generate && dbt docs serve   # open lineage graph at localhost:8080
```

---

## 📁 Project Structure

```
dbt-lab/
├── docker-compose.yml
├── schema.sql                        ← Parts 1 & 2: DDL + SCD logic
├── screenshots/                      ← ERD + terminal screenshots
└── retail_project/
    ├── dbt_project.yml
    └── models/
        ├── sources.yml
        ├── staging/
        │   ├── stg_orders.sql
        │   ├── stg_customers.sql
        │   └── schema.yml
        ├── intermediate/
        │   └── int_orders_joined.sql
        └── mart/
            ├── mart_fact_sales.sql
            └── schema.yml
```

---

## 🤔 Part 3 — Reflection

### *"I asked my database a question. It said it needed more normal form."* 🥁

---

### 1. 📋 Star Schema — What is the grain and why does it matter?

The grain of `fact_sales` is **one row per order line**. This means every row represents a single product purchased in a single transaction. Choosing the right grain is the most important decision in dimensional modeling — too coarse and you lose detail, too fine and queries become slow and hard to reason about.

The four dimension tables each answer a specific question: `dim_customer` (who?), `dim_product` (what?), `dim_store` (where?), `dim_date` (when?). The fact table only stores foreign keys to these dimensions plus the numeric measures (quantity, price, total). This separation makes aggregations like "total revenue by country per month" a simple GROUP BY instead of a complex subquery.

---

### 2. 🔄 SCD Type 2 — Why track history instead of just updating?

A simple UPDATE would overwrite Alice's country from Cambodia to Singapore — and all her old orders would suddenly look like Singapore orders. That's wrong.

SCD Type 2 solves this by never deleting old data. Instead it:
- Sets `is_current = FALSE` and `valid_to = '2024-01-16'` on the old record
- Inserts a brand new row with `is_current = TRUE` and `valid_from = '2024-01-16'`

Now you can ask: *"What country was this customer in when they placed this order?"* by joining on `valid_from <= order_date < valid_to`. Historical reporting stays accurate. This matters in retail, finance, and anywhere customer attributes change over time.

---

### 3. 🏗️ dbt 3-Layer Architecture — Why not just write one big SQL query?

| Layer | Purpose | Why it exists |
|---|---|---|
| **Staging** | Clean + rename raw fields | Isolates raw source changes — if a column renames, you fix it in one place |
| **Intermediate** | Join and enrich | Business logic lives here, reusable across multiple mart models |
| **Mart** | Final analytics-ready table | What BI tools and analysts actually query |

One big SQL query works fine for 8 rows. It becomes unmaintainable at 8 million rows across 20 source tables. The layered approach means each model has one job, tests can target each layer independently, and the lineage graph shows exactly how data flows from raw to report.

---

### 4. 🧪 dbt Tests — What do they catch?

- `unique` + `not_null` on `order_id` catches duplicate inserts or ETL bugs
- `accepted_values` on `country` catches typos like "Cambodi" or a new country being added without updating downstream logic
- Running `dbt test` after every `dbt run` means broken data never silently reaches the mart layer

*"Why do data engineers make great detectives? They always follow the lineage."* 🔍

---

## 📚 References
- [dbt Documentation](https://docs.getdbt.com/)
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
