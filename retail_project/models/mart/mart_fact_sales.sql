-- Mart: final fact table ready for analytics and BI tools
SELECT
    order_id                              AS sale_id,
    customer_id,
    customer_name,
    country,
    product_id,
    product_name,
    category,
    store_id,
    store_city,
    order_date,
    EXTRACT(YEAR  FROM order_date)::INT   AS year,
    EXTRACT(MONTH FROM order_date)::INT   AS month,
    quantity,
    unit_price,
    total_amount
FROM {{ ref('int_orders_joined') }}
