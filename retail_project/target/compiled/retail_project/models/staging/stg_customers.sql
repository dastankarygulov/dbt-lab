-- Staging: deduplicate customers, keep latest country per customer
SELECT DISTINCT ON (customer_id)
    customer_id,
    customer_name,
    country
FROM "retail_db"."public"."raw_orders"
ORDER BY customer_id, order_date DESC