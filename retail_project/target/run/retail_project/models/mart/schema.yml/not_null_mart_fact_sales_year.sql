
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select year
from "retail_db"."public"."mart_fact_sales"
where year is null



  
  
      
    ) dbt_internal_test