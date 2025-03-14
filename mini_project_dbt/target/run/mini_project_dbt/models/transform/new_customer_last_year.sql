
  
    

        create or replace transient table MINI_PROJECT_OUTPUT_DB.transform.new_customer_last_year
         as
        (
WITH transactions AS (
    SELECT * FROM MINI_PROJECT_OUTPUT_DB.staging.staging_transactions_table
)
SELECT
    customer_id,
    COUNT(*) AS new_count_last_year
FROM transactions
WHERE transaction_date >= DATEADD(year, -1, (SELECT MAX(transaction_date) FROM transactions))
GROUP BY customer_id
        );
      
  