{{
    config(
        tags = ["transform", "customer_revenue_ranking"]
    )
}}


WITH customer_transactions AS (
    SELECT
        customer_id,
        MIN(transaction_date) AS first_purchase_date,
        MAX(transaction_date) AS last_purchase_date
    FROM (
        SELECT
            customer_id,
            transaction_date
        FROM {{ ref('staging_transactions_table') }}  
    ) AS transactions
    GROUP BY customer_id
),
max_transaction_date AS (
    SELECT MAX(transaction_date) AS max_date
    FROM {{ ref('staging_transactions_table') }}  
),
monthly_customers AS (
    SELECT
        DATE_TRUNC('month', first_purchase_date) AS month,
        COUNT(customer_id) AS new_customers
    FROM customer_transactions
    GROUP BY month
),
churned_customers AS (
    SELECT
        DATE_TRUNC('month', last_purchase_date) AS month,
        COUNT(customer_id) AS churned_customers_1_month
    FROM customer_transactions
    WHERE last_purchase_date < DATEADD(month, -1, (SELECT max_date FROM max_transaction_date))  
),
churned_customers_3_months AS (
    SELECT
        DATE_TRUNC('month', last_purchase_date) AS month,
        COUNT(customer_id) AS churned_customers_3_months
    FROM customer_transactions
    WHERE last_purchase_date < DATEADD(month, -3, (SELECT max_date FROM max_transaction_date))  
),
churned_customers_12_months AS (
    SELECT
        DATE_TRUNC('month', last_purchase_date) AS month,
        COUNT(customer_id) AS churned_customers_12_months
    FROM customer_transactions
    WHERE last_purchase_date < DATEADD(month, -12, (SELECT max_date FROM max_transaction_date))
    GROUP BY month
)
SELECT
    COALESCE(n.month, c1.month, c3.month, c12.month) AS month,
    COALESCE(n.new_customers, 0) AS new_customers,
    COALESCE(c1.churned_customers_1_month, 0) AS churned_customers_1_month,
    COALESCE(c3.churned_customers_3_months, 0) AS churned_customers_3_months,
    COALESCE(c12.churned_customers_12_months, 0) AS churned_customers_12_months
FROM monthly_customers n
FULL OUTER JOIN churned_customers c1 ON n.month = c1.month
FULL OUTER JOIN churned_customers_3_months c3 ON n.month = c3.month
FULL OUTER JOIN churned_customers_12_months c12 ON n.month = c12.month
ORDER BY month