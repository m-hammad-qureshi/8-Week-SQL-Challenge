-- SECTION A: Data Cleansing & Transformation
-- ============================================
-- Goal: Create a clean, analysis-ready version of weekly_sales
-- with corrected data types, derived columns, and standardized values.
-- Original table is preserved — all changes applied to copies only.
-- ============================================

-- ============================================
-- STEP 1: CREATE BACKUP TABLE
-- ============================================
-- Before any cleaning — create a duplicate of the original table.
-- This ensures zero data loss if anything goes wrong during transformation.
CREATE TABLE weekly_sales_clean AS
SELECT * FROM weekly_sales;
-- Result: weekly_sales_clean created as exact copy of weekly_sales.

-- ============================================
-- STEP 2: FIX week_date DATA TYPE
-- ============================================
-- Problem: week_date is VARCHAR with format 'DD/MM/YY' (e.g. '31/8/20')
-- This is not SQL standard DATE format and cannot be used in date functions.
-- Solution: Add new DATE column, populate with STR_TO_DATE, drop original.

-- Step 2a: Add new DATE column after existing week_date
ALTER TABLE weekly_sales_clean
ADD COLUMN week_date_new DATE AFTER week_date;
-- Note: Cannot directly modify VARCHAR to DATE when values are non-standard.
--       Creating a new column avoids the 'Data Too Long' error.

-- Step 2b: Populate new column using STR_TO_DATE conversion
-- Format: %d = day, %m = month, %y = 2-digit year (20 → 2020)
UPDATE weekly_sales_clean
SET week_date_new = STR_TO_DATE(week_date, '%d/%m/%y');
-- Note: Use lowercase %y for 2-digit year. Capital %Y expects 4-digit year.

-- Step 2c: Drop original VARCHAR week_date column
ALTER TABLE weekly_sales_clean
DROP COLUMN week_date;

-- Step 2d: Rename new column back to week_date for clarity
ALTER TABLE weekly_sales_clean
RENAME COLUMN week_date_new TO week_date;
-- Result: week_date is now proper DATE type with format YYYY-MM-DD.

-- ============================================
-- STEP 3: CREATE FINAL CLEAN TABLE
-- ============================================
-- Building the final analysis-ready table with all required transformations:
-- 1. week_number  → calendar week number from week_date
-- 2. month_number → calendar month number from week_date
-- 3. calendar_year → year extracted from week_date
-- 4. segment      → 'null' strings replaced with 'Unknown'
-- 5. demographic  → derived from segment letter (C=Couples, F=Families)
-- 6. age_band     → derived from segment number (1-4 → age categories)
-- 7. avg_transaction → sales / transactions per row

CREATE TABLE clean_weekly_sales AS
SELECT 
    week_date,

    -- Extracting time dimensions from week_date
    WEEK(week_date) AS week_number,         -- Week number of the year (1-53)
    MONTH(week_date) AS month_number,       -- Month number (1=Jan, 12=Dec)
    YEAR(week_date) AS calendar_year,       -- Year (2018, 2019, 2020)

    region,
    platform,

    -- Standardizing segment: replacing 'null' string with 'Unknown'
    CASE WHEN segment = 'null' THEN 'Unknown' 
         ELSE segment 
    END AS segment,

    -- Deriving demographic from segment letter
    -- C = Couples, F = Families, 'null' = Unknown
    -- Note: 'null' checked FIRST to avoid LEFT() on invalid value
    CASE 
        WHEN segment = 'null' THEN 'Unknown'
        WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
        WHEN LEFT(segment, 1) = 'F' THEN 'Families'
        ELSE 'Unknown'
    END AS demographic,

    -- Deriving age_band from segment number
    -- 1 = Young Adults, 2 = Middle Aged, 3 or 4 = Retirees, 'null' = Unknown
    -- Note: 'null' checked FIRST to avoid RIGHT() on invalid value
    CASE 
        WHEN segment = 'null' THEN 'Unknown'
        WHEN RIGHT(segment, 1) = 1 THEN 'Young Adults'
        WHEN RIGHT(segment, 1) = 2 THEN 'Middle Aged'
        WHEN RIGHT(segment, 1) = 3 OR RIGHT(segment, 1) = 4 THEN 'Retirees'
        ELSE 'Unknown'
    END AS age_band,

    customer_type,
    transactions,
    sales,

    -- Calculating average transaction value per row
    -- Note: 1 record with sales = 0 exists (South America region)
    -- Kept here — can be filtered in analysis queries with WHERE cluase: sales > 0
    ROUND(sales / transactions, 2) AS avg_transaction

FROM weekly_sales_clean;

-- ============================================
-- STEP 4: VERIFY CLEAN TABLE
-- ============================================
SELECT * FROM clean_weekly_sales LIMIT 10;

-- ============================================
-- TRANSFORMATION SUMMARY
-- ============================================
-- | Column          | Change Applied                          |
-- |-----------------|-----------------------------------------|
-- | week_date       | VARCHAR → DATE (STR_TO_DATE %d/%m/%y)  |
-- | week_number     | NEW — WEEK() from week_date             |
-- | month_number    | NEW — MONTH() from week_date            |
-- | calendar_year   | NEW — YEAR() from week_date             |
-- | segment         | 'null' string → 'Unknown'               |
-- | demographic     | NEW — derived from segment letter       |
-- | age_band        | NEW — derived from segment number       |
-- | avg_transaction | NEW — ROUND(sales/transactions, 2)      |
-- ============================================
