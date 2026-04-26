-- Section B: Data Exploration
-- =============================================================================

-- 1. What day of the week is used for each week_date value?
-- Business Insight: Danny chose Monday as the start of the business week. 
-- This sequencing demonstrates high data quality and consistency.
SELECT DISTINCT (DAYNAME(week_date)) AS start_of_week
FROM weekly_sales_final;
