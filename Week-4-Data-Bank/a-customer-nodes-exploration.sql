-- Section A: Customer Nodes Exploration

-- 1: How many unique nodes are there on the Data Bank system?
-- Logic: Basic distinct count to identify the breadth of the network infrastructure.
SELECT COUNT(DISTINCT node_id) AS unique_nodes 
FROM customer_nodes; 

-- 2: What is the number of nodes per region?
-- Logic: Grouping by region to see infrastructure density. 
-- Note: DISTINCT is required to count the unique nodes available in each region, 
-- rather than every historical allocation event.
SELECT 
    region_id, 
    COUNT(DISTINCT node_id) AS nodes_per_region
FROM customer_nodes 
GROUP BY region_id
ORDER BY region_id ASC;


-- 3: How many customers are allocated to each region?
-- Logic: Determining the user-base distribution across the 5 regions. 
-- Using DISTINCT ensures we count individual customers, not their movement history.
SELECT 
    region_id, 
    COUNT(DISTINCT customer_id) AS total_customers
FROM customer_nodes
GROUP BY region_id
ORDER BY region_id ASC;


-- 4: How many days on average are customers reallocated to a different node?
-- Logic: Calculating the duration of stay per node using DATEDIFF.
-- Data Cleansing: Filtered out '9999-12-31' sentinel values discovered during profiling.
-- Including these would skew the average to several thousand years.
WITH date_cte AS (
    SELECT 
        DATEDIFF(end_date, start_date) AS duration
    FROM customer_nodes
    WHERE end_date != '9999-12-31'
)
SELECT 
    ROUND(AVG(duration), 0) AS avg_reallocation_days
FROM date_cte;

