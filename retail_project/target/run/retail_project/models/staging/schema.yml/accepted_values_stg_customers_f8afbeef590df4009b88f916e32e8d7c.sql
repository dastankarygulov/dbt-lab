
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

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



  
  
      
    ) dbt_internal_test