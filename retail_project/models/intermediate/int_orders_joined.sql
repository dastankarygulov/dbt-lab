-- Intermediate: join orders with deduplicated customer info
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.customer_name,
    c.country,
    o.product_id,
    o.product_name,
    o.category,
    o.store_id,
    o.store_city,
    o.quantity,
    o.unit_price,
    o.total_amount
FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('stg_customers') }} c
    ON o.customer_id = c.customer_id
