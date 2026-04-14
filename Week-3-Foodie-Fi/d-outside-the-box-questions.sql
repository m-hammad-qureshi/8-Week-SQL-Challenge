-- D: Outside The Box Questions

-- ## Q1: How would you calculate the rate of growth for Foodie-Fi?

-- Growth rate is measured month over month using only paying customers (plan_id 1, 2, 3).

-- Formula:

-- Growth Rate = ((Current Month - Previous Month) / Previous Month) * 100

-- Approach: Group active paid subscriptions by month, use `LAG()` to get the previous month's count, then apply the growth formula.

sql
WITH month_cte AS (
  SELECT DATE_FORMAT(start_date, '%Y-%m-01') AS group_by_month,
         COUNT(DISTINCT customer_id) AS total
  FROM subscriptions
  WHERE plan_id IN (1, 2, 3)
  GROUP BY group_by_month
),
rate_cte AS (
  SELECT MONTHNAME(group_by_month) AS month_name, total,
         COALESCE(LAG(total) OVER (ORDER BY group_by_month), 0) AS prev_total
  FROM month_cte
)
SELECT *,
  CASE WHEN prev_total = 0 THEN 'First Month'
       ELSE ROUND(((total - prev_total) / prev_total) * 100.0, 2)
  END AS growth_rate
FROM rate_cte;

-- Key findings: Strong early growth, peak in March (~32%), slowdown in Q4, negative growth in early 2021 indicating a retention problem.


-- ## Q2: What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

-- | Metric | Description |
-- |---|---|
-- | Monthly Growth Rate | New paying customers joining each month |
-- | Churn Rate | % of customers cancelling each month |
-- | MRR (Monthly Recurring Revenue) | Total revenue from active subscriptions per month |
-- | Trial Conversion Rate | % of trial customers converting to paid plans |
-- | Engagement | Watch history, login frequency, content interactions (requires additional data capture) |

-- Churn Rate Query:
sql
WITH churned_cte AS (
  SELECT
    SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) AS churned_customers,
    COUNT(DISTINCT customer_id) AS total
  FROM subscriptions
)
SELECT ROUND((churned_customers / total) * 100.0, 1) AS churn_percent
FROM churned_cte;
  
-- > Foodie-Fi's overall churn rate: ~30.7% — significantly above the healthy range of 5-7%.


-- ## Q3: What are some key customer journeys or experiences that you would analyse further to improve customer retention?

-- 1. Churned after trial
-- Customers who left within 7 days never found value in the product. This is the most critical journey — it suggests the product didn't deliver on its promise. To investigate properly, behaviour data is needed: login events, content watched, watch duration.

-- 2. Downgraded customers
-- Customers who moved from pro to basic suggest a price vs value mismatch or loss of interest. Analysing when in their journey this happened can reveal content or pricing issues.

-- 3. Customers who never upgraded from basic
-- These customers are satisfied with basic but see no reason to pay more. Understanding what features or content would push them to upgrade can drive revenue growth.

-- 4. Customers who upgraded quickly
-- Understanding what drove fast upgrades can help replicate that experience for new customers.

-- Data engineering note: The current schema only tracks subscriptions. To fully analyse these journeys, additional tables are needed 
--   — login events, watch history, content interactions. "Build event tracking tables to capture login events, content interactions and watch duration during trial. 
--   Cross reference with exit survey responses to identify the real churn drivers."


-- ## Q4: If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

-- 1. Content — Are you satisfied with our content library? How can we improve it?
-- 2. App Experience — Did you face any technical issues or UX problems that contributed to leaving?
-- 3. Price vs Value — Did you feel the subscription price matched the value you received?
-- 4. Personal Reasons — Were there any personal reasons unrelated to Foodie-Fi behind your decision?
-- 5. Main Reason Selector — A multiple choice landing page where customers select their primary reason, followed by a specific follow-up question per reason.
-- 6. NPS — On a scale of 1-10, how likely are you to recommend Foodie-Fi to a friend?

-- > Exit survey responses should be stored in a dedicated table linked to customer_id and their subscription history for deeper churn analysis.


-- ## Q5: What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

-- | Lever | Action |
-- |---|---|
-- | Price | Offer targeted discounts to price-sensitive customers identified through exit surveys |
-- | Content | Launch new shows and improve existing ones based on content feedback |
-- | App/UX | Fix reported technical issues and improve the user experience |
-- | Trial Experience | Proactive engagement during the 7-day trial — personalised onboarding, content recommendations, reminder emails before trial ends |

-- Validation Method:
-- Measure churn rate before and after implementing each lever:
-- Before lever → measure churn rate
-- Implement lever → wait 1-2 months
-- After lever → measure churn rate again


-- If churn rate drops → lever is working ✅  
-- If churn rate stays the same → revisit the approach ❌

-- > The goal is to move Foodie-Fi's churn rate from ~30.7% toward the industry healthy range of 5-7
-- Measure churn rate before and after implementing each lever:
