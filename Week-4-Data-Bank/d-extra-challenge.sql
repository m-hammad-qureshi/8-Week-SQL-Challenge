-- SECTION D: Extra Challenge
-- Interest-Based Data Allocation
-- ============================================
-- Business Context:
-- Data Bank wants to reward customers by allocating cloud storage
-- based on daily interest earned on their running balance.
-- Annual interest rate: 6%
-- Interest is calculated daily: balance * 0.06 / 365
-- This section implements the SIMPLE INTEREST version.
-- Compound interest version is pending implementation.
-- ============================================

WITH RECURSIVE signed_cte AS (
    -- Step 1: Assign signed values to each transaction
    -- Deposits are positive (+), purchases and withdrawals are negative (-)
    -- This allows accurate running balance calculation
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        CASE WHEN txn_type = 'deposit' 
             THEN txn_amount 
             ELSE -txn_amount 
        END AS signed_amount
    FROM customer_transactions
),

running_cte AS (
    -- Step 2: Calculate cumulative running balance per customer
    -- SUM() OVER() with ORDER BY txn_date creates a running total
    -- Each row shows the exact balance AFTER that transaction
    SELECT *, 
        SUM(signed_amount) OVER(
            PARTITION BY customer_id 
            ORDER BY txn_date
        ) AS running_balance
    FROM signed_cte
),

plan_cte AS (
    -- Step 3: Find the next transaction date per customer
    -- LEAD() looks at the next row's date for the same customer
    -- COALESCE handles the last transaction — defaults to end of dataset (2020-04-30)
    -- This gives us the date range each balance remains unchanged
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        COALESCE(
            LEAD(txn_date) OVER(PARTITION BY customer_id ORDER BY txn_date), 
            '2020-04-30'
        ) AS plan_date
    FROM customer_transactions
),

day_add_cte AS (
    -- Step 4: Generate a row for every single day per customer
    -- ANCHOR: Start from each transaction date with its running balance
    -- RECURSIVE: Add 1 day at a time carrying balance forward
    -- Stop condition: stop when we reach the next transaction date (plan_date)
    -- This fills the gaps between transactions with the last known balance
    SELECT 
        rc.customer_id, 
        rc.txn_date, 
        rc.running_balance, 
        pc.plan_date
    FROM running_cte AS rc
    JOIN plan_cte AS pc 
        ON rc.customer_id = pc.customer_id 
        AND rc.txn_date = pc.txn_date

    UNION ALL

    SELECT 
        customer_id, 
        DATE_ADD(txn_date, INTERVAL 1 DAY) AS txn_date, 
        running_balance, 
        plan_date
    FROM day_add_cte
    WHERE txn_date < plan_date
),

interest_rate_cte AS (
    -- Step 5: Calculate daily simple interest for each customer per day
    -- Formula: balance * annual_rate / days_in_year
    -- = running_balance * 0.06 / 365
    -- Only positive balances earn interest — negative balances excluded
    SELECT *, 
        (running_balance * 0.06) / 365 AS interest_rate
    FROM day_add_cte
    WHERE txn_date <= plan_date 
    AND running_balance > 0
)

-- Final Output: Total data allocation per month based on simple interest
-- Summing daily interest across all customers gives monthly storage requirement
-- Note: Compound interest version pending — formula: balance * POWER((1 + 0.06/365), elapsed_days) - balance
SELECT 
    DATE_FORMAT(txn_date, '%Y-%m-01') AS date_month, 
    ROUND(SUM(interest_rate), 2) AS total_interest
FROM interest_rate_cte
GROUP BY date_month
ORDER BY date_month;

-- ============================================
-- RESULTS (Simple Interest):
-- January 2020:  845.13
-- February 2020: 1487.86
-- March 2020:    1609.25
-- April 2020:    1478.14
-- ============================================
-- Insight: Interest grows from January to March as customer balances
-- accumulate over time. April drops slightly as dataset ends on April 28(still 2 days remaining)
-- and some customers may have reduced balances.
