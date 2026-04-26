-- Section B: Data Exploration
-- =============================================================================

-- 1. What day of the week is used for each week_date value?
-- Business Insight: Danny chose Monday as the start of the business week. 
-- This sequencing demonstrates high data quality and consistency.
SELECT DISTINCT (DAYNAME(week_date)) AS start_of_week
FROM weekly_sales_final;

-- 2. What range of week numbers are missing from the dataset?
-- Methodology: Using a Recursive CTE to generate all 52 weeks and comparing 
-- them against our unique week_numbers to identify gaps.
WITH RECURSIVE all_weeks_cte AS (
    SELECT 1 AS week_num -- Anchor: Starting point
    UNION ALL
    SELECT week_num + 1 -- Recursive member: Generates sequence
    FROM all_weeks_cte
    WHERE week_num <= 52 -- Termination: Prevents infinite loop
),
existing_weeks_cte AS (
    SELECT DISTINCT week_number 
    FROM weekly_sales_final
),
missing_weeks_range AS (
    SELECT 
        all_weeks_cte.week_num,
        -- Applying 'Gap and Island' logic by creating a group for consecutive missing values
        all_weeks_cte.week_num - ROW_NUMBER() OVER(ORDER BY all_weeks_cte.week_num) AS gap_id
    FROM all_weeks_cte
    LEFT JOIN existing_weeks_cte ON all_weeks_cte.week_num = existing_weeks_cte.week_number
    WHERE existing_weeks_cte.week_number IS NULL
)
SELECT 
    'Missing Weeks' AS description, 
    CONCAT(MIN(week_num), '-', MAX(week_num)) AS missing_range
FROM missing_weeks_range
GROUP BY gap_id;

-- 3. How many total transactions were there for each year in the dataset?
-- Logic: Since the 'transactions' column is already a pre-aggregated count,
-- we must use SUM() to find the total volume rather than COUNT().
SELECT 
    calender_year, 
    SUM(transactions) AS total_transactions
FROM weekly_sales_final
GROUP BY calender_year;

-- 4. What is the total sales for each region for each month?
-- Logic: Leveraging the 'month_number' column created during data cleaning.
SELECT 
    region, 
    month_number, 
    SUM(sales) AS total_sales
FROM weekly_sales_final
GROUP BY region, month_number
ORDER BY region ASC, month_number ASC;

-- 5. What is the total count of transactions for each platform?
-- Note: As established in Q3, we use SUM() because 'transactions' is an aggregated field.
SELECT 
    platform, 
    SUM(transactions) AS total_transactions
FROM weekly_sales_final
GROUP BY platform;

