
  create view "retail_db"."public"."int_orders_joined__dbt_tmp"
    
    
  as (
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
FROM "retail_db"."public"."stg_orders" o
LEFT JOIN "retail_db"."public"."stg_customers" c
    ON o.customer_id = c.customer_id
  );