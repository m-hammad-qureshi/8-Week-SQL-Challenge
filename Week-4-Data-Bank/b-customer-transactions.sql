-- Section B: Customer Transactions

-- 1: What is the unique count and total amount for each transaction type?
-- Logic: Grouping by transaction type to see the volume and monetary value of each activity.
SELECT 
    txn_type,
    COUNT(*) AS transaction_count, 
    SUM(txn_amount) AS total_amount 
FROM customer_transactions
GROUP BY txn_type;


-- 2: What is the average total historical deposit counts and amounts for all customers?
-- Logic: Creating a CTE to aggregate deposits per customer first, then averaging those totals.
WITH customer_deposit_summary AS (
    SELECT 
        customer_id,
        COUNT(*) AS deposit_count, 
        SUM(txn_amount) AS total_deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(deposit_count), 0) AS avg_deposit_count,  
    ROUND(AVG(total_deposit_amount), 0) AS avg_deposit_amount
FROM customer_deposit_summary;


-- 3: For each month - how many Data Bank customers make more than 1 deposit 
-- and either 1 purchase or 1 withdrawal in a single month?
-- Logic: Using a CTE to count specific transaction types per customer per month.
WITH monthly_activity AS (
    SELECT 
        customer_id, 
        DATE_FORMAT(txn_date, '%Y-%m-01') AS txn_month, 
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count, 
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, txn_month
)
SELECT 
    txn_month,
    COUNT(*) AS customer_count
FROM monthly_activity
WHERE deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY txn_month
ORDER BY txn_month;


-- 4: What is the closing balance for each customer at the end of the month?
-- Logic: Calculating monthly net flow (Deposits - Spendings). 
-- Spendings include both purchases and withdrawals.
WITH monthly_cash_flow AS (
    SELECT 
        customer_id, 
        DATE_FORMAT(txn_date, '%Y-%m-01') AS txn_month, 
        COALESCE(SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount END), 0) AS total_deposited,
        COALESCE(SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount END), 0) + 
        COALESCE(SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount END), 0) AS total_spent
    FROM customer_transactions
    GROUP BY customer_id, txn_month
)
SELECT 
    customer_id, 
    txn_month, 
    (total_deposited - total_spent) AS net_monthly_balance
FROM monthly_cash_flow
ORDER BY customer_id, txn_month;

