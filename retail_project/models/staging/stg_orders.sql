-- Staging: clean and rename raw order fields
-- Adds total_amount as a derived column
SELECT
    order_id,
    customer_id,
    customer_name,
    country,
    product_id,
    product_name,
    category,
    unit_price,
    quantity,
    order_date,
    store_id,
    store_city,
    unit_price * quantity AS total_amount
FROM {{ source('retail', 'raw_orders') }}
