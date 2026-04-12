C. CHALLENGE PAYMENT QUESTION
-- THE FOODIE-FI TEAM WANTS YOU TO CREATE A NEW PAYMENTS TABLE FOR THE YEAR 2020
-- THAT INCLUDES AMOUNTS PAID BY EACH CUSTOMER IN THE SUBSCRIPTIONS TABLE WITH THE FOLLOWING REQUIREMENTS:

-- MONTHLY PAYMENTS ALWAYS OCCUR ON THE SAME DAY OF MONTH AS THE ORIGINAL START_DATE OF ANY MONTHLY PAID PLAN
-- UPGRADES FROM BASIC TO MONTHLY OR PRO PLANS ARE REDUCED BY THE CURRENT PAID AMOUNT IN THAT MONTH AND START IMMEDIATELY
-- UPGRADES FROM PRO MONTHLY TO PRO ANNUAL ARE PAID AT THE END OF THE CURRENT BILLING PERIOD AND ALSO STARTS AT THE END OF THE MONTH PERIOD
-- ONCE A CUSTOMER CHURNS THEY WILL NO LONGER MAKE PAYMENTS

WITH RECURSIVE BASE_DATA_CTE AS (
    SELECT 
        SUB.customer_id,
        SUB.plan_id, 
        SUB.start_date,
        P.plan_name, 
        P.price
    FROM subscriptions AS SUB
    JOIN plans AS P ON SUB.plan_id = P.plan_id 
    WHERE SUB.plan_id IN (1, 2, 3)
),
STOP_DATE_CTE AS (
    SELECT 
        customer_id, 
        plan_id, 
        COALESCE(LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date), '2020-12-31') AS NEXT_PLAN
    FROM subscriptions
),
RECURSIVE_MONTH_ADD_CTE AS (
    SELECT 
        BDC.customer_id, 
        BDC.plan_id, 
        BDC.start_date, 
        SD.NEXT_PLAN
    FROM BASE_DATA_CTE AS BDC
    JOIN STOP_DATE_CTE AS SD ON BDC.customer_id = SD.customer_id AND BDC.plan_id = SD.plan_id
    
    UNION ALL
    
    SELECT 
        RMAC.customer_id, 
        RMAC.plan_id, 
        DATE_ADD(RMAC.start_date, INTERVAL 1 MONTH) AS start_date, 
        RMAC.NEXT_PLAN
    FROM RECURSIVE_MONTH_ADD_CTE AS RMAC
    WHERE RMAC.start_date < RMAC.NEXT_PLAN AND RMAC.plan_id != 3
),
MID_TABLE_CTE AS (
    SELECT 
        RMAC.customer_id, 
        RMAC.plan_id, 
        RMAC.start_date, 
        P.plan_name, 
        P.price, 
        ROW_NUMBER() OVER(PARTITION BY RMAC.customer_id ORDER BY RMAC.start_date ASC) AS RANK_PLANS
    FROM RECURSIVE_MONTH_ADD_CTE AS RMAC
    JOIN plans AS P ON RMAC.plan_id = P.plan_id
    WHERE RMAC.start_date <= RMAC.NEXT_PLAN
),
FINAL_PAYMENTS_CTE AS (
    SELECT 
        *,	
        CASE 
            WHEN LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date ASC) != plan_id 
            THEN (price - (LAG(price) OVER(PARTITION BY customer_id ORDER BY start_date ASC))) 
            ELSE price 
        END AS FINAL_PRICE 
    FROM MID_TABLE_CTE
)
SELECT 
    customer_id, 
    plan_id, 
    start_date, 
    plan_name, 
    FINAL_PRICE, 
    RANK_PLANS
FROM FINAL_PAYMENTS_CTE
ORDER BY customer_id, start_date;
