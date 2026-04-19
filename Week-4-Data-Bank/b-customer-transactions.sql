-- Section B: Customer Transactions

-- 1: What is the unique count and total amount for each transaction type?
-- Logic: Grouping by transaction type to see the volume and monetary value of each activity.
SELECT 
    txn_type,
    COUNT(*) AS transaction_count, 
    SUM(txn_amount) AS total_amount 
FROM customer_transactions
GROUP BY txn_type;

