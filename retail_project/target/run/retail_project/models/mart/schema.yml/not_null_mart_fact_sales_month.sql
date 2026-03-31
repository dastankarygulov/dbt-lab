
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month
from "retail_db"."public"."mart_fact_sales"
where month is null



  
  
      
    ) dbt_internal_test