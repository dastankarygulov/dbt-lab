
    
    

with all_values as (

    select
        country as value_field,
        count(*) as n_records

    from "retail_db"."public"."stg_customers"
    group by country

)

select *
from all_values
where value_field not in (
    'Cambodia','Thailand','Vietnam','Singapore'
)


