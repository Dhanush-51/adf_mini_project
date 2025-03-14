
  
    

        create or replace transient table MINI_PROJECT_OUTPUT_DB.transform.new_logos_fiscal_year
         as
        (WITH customer_first_purchase AS (
    SELECT
        customer_id,
        MIN(transaction_date) AS first_purchase_date
    FROM MINI_PROJECT_OUTPUT_DB.staging.staging_transactions_table  -- Reference to the transactions staging table
    GROUP BY customer_id
),
fiscal_years AS (
    SELECT
        customer_id,
        first_purchase_date,
        CASE 
            WHEN EXTRACT(MONTH FROM first_purchase_date) >= 4 THEN EXTRACT(YEAR FROM first_purchase_date)  -- FY starts in April
            ELSE EXTRACT(YEAR FROM first_purchase_date) - 1
        END AS fiscal_year
    FROM customer_first_purchase
)
SELECT
    fiscal_year,
    COUNT(customer_id) AS new_logos
FROM fiscal_years
GROUP BY fiscal_year
ORDER BY fiscal_year
        );
      
  