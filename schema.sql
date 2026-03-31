-- ============================================================
--  schema.sql
--  Run this inside psql after docker-compose up -d
--  Command: docker exec -it <container> psql -U dbtuser -d retail_db -f /schema.sql
-- ============================================================

-- ── Raw source table ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw_orders (
  order_id      SERIAL PRIMARY KEY,
  customer_id   INT,
  customer_name VARCHAR(100),
  country       VARCHAR(50),
  product_id    INT,
  product_name  VARCHAR(100),
  category      VARCHAR(50),
  unit_price    NUMERIC(10,2),
  quantity      INT,
  order_date    DATE,
  store_id      INT,
  store_city    VARCHAR(100)
);

INSERT INTO raw_orders
  (customer_id, customer_name, country, product_id, product_name, category, unit_price, quantity, order_date, store_id, store_city)
VALUES
  (1, 'Alice',  'Cambodia',  101, 'Laptop', 'Electronics', 1200.00, 1, '2024-01-10', 1, 'Phnom Penh'),
  (2, 'Bob',    'Thailand',  102, 'Phone',  'Electronics',  800.00, 2, '2024-01-11', 2, 'Bangkok'),
  (1, 'Alice',  'Cambodia',  103, 'Mouse',  'Accessories',   25.00, 3, '2024-01-12', 1, 'Phnom Penh'),
  (3, 'Carol',  'Vietnam',   101, 'Laptop', 'Electronics', 1100.00, 1, '2024-01-13', 3, 'Hanoi'),
  (2, 'Bob',    'Thailand',  104, 'Tablet', 'Electronics',  600.00, 1, '2024-01-14', 2, 'Bangkok'),
  (4, 'David',  'Cambodia',  102, 'Phone',  'Electronics',  800.00, 1, '2024-01-15', 1, 'Phnom Penh'),
  (3, 'Carol',  'Vietnam',   103, 'Mouse',  'Accessories',   25.00, 5, '2024-01-15', 3, 'Hanoi'),
  (1, 'Alice',  'Singapore', 101, 'Laptop', 'Electronics', 1200.00, 1, '2024-01-16', 4, 'Singapore');


-- ============================================================
--  PART 1 — Star Schema DDL
-- ============================================================

-- Dimension: Customer
CREATE TABLE IF NOT EXISTS dim_customer (
  customer_key  SERIAL PRIMARY KEY,
  customer_id   INT,
  customer_name VARCHAR(100),
  country       VARCHAR(50),
  -- SCD Type 2 columns (added here for Part 2)
  is_current    BOOLEAN DEFAULT TRUE,
  valid_from    DATE,
  valid_to      DATE
);

-- Dimension: Product
CREATE TABLE IF NOT EXISTS dim_product (
  product_key  SERIAL PRIMARY KEY,
  product_id   INT,
  product_name VARCHAR(100),
  category     VARCHAR(50)
);

-- Dimension: Store
CREATE TABLE IF NOT EXISTS dim_store (
  store_key   SERIAL PRIMARY KEY,
  store_id    INT,
  store_city  VARCHAR(100),
  country     VARCHAR(50)
);

-- Dimension: Date
CREATE TABLE IF NOT EXISTS dim_date (
  date_key     INT PRIMARY KEY,   -- format YYYYMMDD e.g. 20240110
  full_date    DATE,
  day          INT,
  month        INT,
  month_name   VARCHAR(20),
  quarter      INT,
  year         INT,
  day_of_week  VARCHAR(20)
);

-- Fact: Sales
CREATE TABLE IF NOT EXISTS fact_sales (
  sale_id       SERIAL PRIMARY KEY,
  customer_key  INT REFERENCES dim_customer(customer_key),
  product_key   INT REFERENCES dim_product(product_key),
  store_key     INT REFERENCES dim_store(store_key),
  date_key      INT REFERENCES dim_date(date_key),
  quantity      INT,
  unit_price    NUMERIC(10,2),
  total_amount  NUMERIC(10,2)
);


-- ============================================================
--  PART 1 — Populate dimension + fact tables from raw_orders
-- ============================================================

-- dim_customer (unique customers, latest country)
INSERT INTO dim_customer (customer_id, customer_name, country, is_current, valid_from, valid_to)
SELECT DISTINCT ON (customer_id)
  customer_id, customer_name, country, TRUE, MIN(order_date) OVER (PARTITION BY customer_id), NULL
FROM raw_orders
ORDER BY customer_id, order_date ASC;

-- dim_product
INSERT INTO dim_product (product_id, product_name, category)
SELECT DISTINCT product_id, product_name, category FROM raw_orders;

-- dim_store
INSERT INTO dim_store (store_id, store_city, country)
SELECT DISTINCT store_id, store_city, country FROM raw_orders;

-- dim_date (one row per unique order_date)
INSERT INTO dim_date (date_key, full_date, day, month, month_name, quarter, year, day_of_week)
SELECT DISTINCT
  TO_CHAR(order_date, 'YYYYMMDD')::INT,
  order_date,
  EXTRACT(DAY   FROM order_date)::INT,
  EXTRACT(MONTH FROM order_date)::INT,
  TO_CHAR(order_date, 'Month'),
  EXTRACT(QUARTER FROM order_date)::INT,
  EXTRACT(YEAR  FROM order_date)::INT,
  TO_CHAR(order_date, 'Day')
FROM raw_orders;

-- fact_sales
INSERT INTO fact_sales (customer_key, product_key, store_key, date_key, quantity, unit_price, total_amount)
SELECT
  dc.customer_key,
  dp.product_key,
  ds.store_key,
  TO_CHAR(r.order_date, 'YYYYMMDD')::INT,
  r.quantity,
  r.unit_price,
  r.unit_price * r.quantity
FROM raw_orders r
JOIN dim_customer dc ON r.customer_id = dc.customer_id AND dc.is_current = TRUE
JOIN dim_product  dp ON r.product_id  = dp.product_id
JOIN dim_store    ds ON r.store_id    = ds.store_id;


-- ============================================================
--  PART 2 — SCD Type 2 on dim_customer
-- ============================================================

-- First, fix Alice's initial record to show Cambodia with correct valid_from
UPDATE dim_customer
SET is_current = TRUE,
    valid_from = '2024-01-10',
    valid_to   = NULL
WHERE customer_id = 1 AND country = 'Cambodia';

-- Step A: Expire Alice's Cambodia record
UPDATE dim_customer
SET    is_current = FALSE,
       valid_to   = '2024-01-16'
WHERE  customer_id = 1
  AND  country     = 'Cambodia'
  AND  is_current  = TRUE;

-- Step B: Insert Alice's new Singapore record
INSERT INTO dim_customer
  (customer_id, customer_name, country, is_current, valid_from, valid_to)
VALUES
  (1, 'Alice', 'Singapore', TRUE, '2024-01-16', NULL);

-- Verify — should show 2 rows for Alice
SELECT
  customer_key,
  customer_id,
  customer_name,
  country,
  is_current,
  valid_from,
  valid_to
FROM dim_customer
WHERE customer_id = 1
ORDER BY valid_from;
