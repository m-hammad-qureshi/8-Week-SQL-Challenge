-- DATA PROFILING TABLE 1: customer_nodes
-- Goal: Identify anomalies, placeholders, and data distribution prior to ELT(Extract, Transform/ Load).

-- 1: SCALE & GRANULARITY CHECK
-- Determining total volume and unique customer reach.
SELECT 
    COUNT(*) AS total_transactions, 
    COUNT(DISTINCT customer_id) AS unique_customers 
FROM customer_transactions;
-- Result: 5,868 transactions for 500 unique customers. 

-- 2: DUPLICATE DETECTION
-- Identifying exact row redundancy across the financial ledger.
WITH row_cte AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY customer_id, txn_date, txn_type, txn_amount) AS row_num
    FROM customer_transactions
)
SELECT * FROM row_cte
WHERE row_num > 1;
-- Result: 0 duplicates. Transaction integrity is maintained.

-- 3: DATA TYPE & SCHEMA VALIDATION
-- Verifying internal metadata for storage efficiency and computational accuracy.
DESCRIBE customer_transactions;

-- Detailed Metadata Inspection
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer_transactions';
-- Note: Ensuring 'txn_amount' is a numeric type (INT/DECIMAL) for aggregation.

-- 4: COMPLETENESS AUDIT (NULL/BLANK/CORRUPTED DATA)
-- Using a mapping approach to identify missing or "ghost" values.
SELECT 
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN txn_date IS NULL THEN 1 ELSE 0 END) AS txn_date_nulls,
    SUM(CASE WHEN txn_type IS NULL OR txn_type = '' THEN 1 ELSE 0 END) AS txn_type_nulls,
    SUM(CASE WHEN txn_amount IS NULL THEN 1 ELSE 0 END) AS txn_amount_nulls
FROM customer_transactions;
-- Result: 0 corrupted or missing values detected.

-- 5: TEMPORAL BOUNDARY CHECK
-- Checking the timeframe of the dataset.
SELECT 
    MIN(txn_date) AS earliest_txn, 
    MAX(txn_date) AS latest_txn 
FROM customer_transactions;
-- Result: Transactions span from 2020-01-01 to 2020-04-28.

-- 6: CATEGORICAL DISTRIBUTION (TRANSACTION TYPES)
-- Identifying the diversity of financial activities.
SELECT 
    Distinct txn_type
FROM customer_transactions;
-- Result: 3 unique types (deposit, withdrawal, purchase).

-- 7: UNEXPECTED VALUES & BUSINESS LOGIC CHECK
-- Checking for zero-sum transactions which may indicate failed or test records.
SELECT * FROM customer_transactions 
WHERE txn_amount = 0;

-- Found an amount of 0 for txn_type 'deposit' customer_id 32, which can be a failed transaction, a system test record, 
-- or a promotional account opening event that didn't require an initial balance.
