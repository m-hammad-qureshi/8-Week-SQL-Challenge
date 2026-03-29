CREATE DATABASE if NOT EXISTS dannys_diner;
use dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INT
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

select * from information_schema.columns
where table_name = "members";

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    s.customer_id, 
    SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
  
-- 2. How many days has each customer visited the restaurant?  
select customer_id, count(DISTINCT order_date) as visited_date
from sales
GROUP BY customer_id;  


-- 3. What was the first item from the menu purchased by each customer?
with cte as (
select *,
dense_rank() over(PARTITION BY customer_id order by order_date) as rn
from sales
)
select cte.customer_id, m.product_name
from cte
JOIN menu as m
on cte.product_id = m.product_id
where rn = 1
GROUP BY cte.customer_id, m.product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) as total_sales
from menu as m
join sales as s
on m.product_id = s.product_id
group by m.product_name
ORDER BY total_sales desc
limit 1;


with order_count as(
select m.product_name, count(s.product_id) as total_sales
from sales as s
join menu as m
on s.product_id = m.product_id
group by m.product_name
),
item_rank as(
select *,
DENSE_RANK() over(ORDER BY total_sales desc) as rn 
from order_count
)
select * from item_rank;


-- 5. Which item was the most popular for each customer?
with order_count as(
select s.customer_id, m.product_name, count(s.product_id) as total_sales
from sales as s 
join menu as m
on s.product_id = m.product_id
group by s.customer_id, m.product_name
),
item_rank as(
select *,
DENSE_RANK() over(PARTITION BY customer_id ORDER BY total_sales desc) as rn
from order_count
)
SELECT customer_id, product_name, total_sales
from item_rank
where rn = 1;


-- 6. Which item was purchased first by the customer after they became a member?
with order_cte as(
select s.customer_id, m.product_name,
DENSE_RANK() over(PARTITION BY s.customer_id order by s.order_date) as first_order
from sales as s
join menu as m on s.product_id = m.product_id
join members as me on s.customer_id = me.customer_id
where me.join_date >= s.order_date
)
SELECT customer_id, product_name
from order_cte
where first_order = 1;


-- 7. Which item was purchased just before the customer became a member?
with order_cte as(
select s.customer_id, m.product_name,
DENSE_RANK() over(PARTITION BY s.customer_id order by s.order_date) as first_order
from sales as s
join menu as m on s.product_id = m.product_id
join members as me on s.customer_id = me.customer_id
where me.join_date < s.order_date
)
SELECT customer_id, product_name
from order_cte
where first_order = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
with order_cte as(
select s.customer_id,count(s.product_id) as total_items, sum(m.price) as total_amount
from sales as s
join menu as m on s.product_id = m.product_id
join members as me on s.customer_id = me.customer_id
where me.join_date < s.order_date
group by customer_id
)
SELECT customer_id, total_items, total_amount
from order_cte;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points_cte as(
select s.customer_id,
SUM(CASE	
	WHEN m.product_name = 'sushi' then m.price * 20
    ELSE m.price * 10
	END) as points
from sales as s 
join menu as m
on s.product_id = m.product_id
GROUP BY s.customer_id
)
select customer_id, points
from points_cte;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
WITH points_cte AS(
	SELECT s.customer_id,
	SUM(CASE	
		WHEN s.order_date BETWEEN me.join_date AND date_add(me.join_date, INTERVAL 6 DAY) THEN m.price * 20
		WHEN m.product_name = 'sushi' THEN m.price * 20
		ELSE m.price * 10
		END) AS points
FROM sales AS s 
JOIN menu AS m 
ON s.product_id = m.product_id
JOIN members AS me 
ON s.customer_id = me.customer_id
WHERE 
	me.customer_id IN ('A','B') AND
	s.order_date <= '2021-01-31'
GROUP BY s.customer_id
)
SELECT customer_id, points
FROM points_cte;


-- Bonus Question: Merge all tables data in a single table to avoid using Join everytime.
select s.customer_id, s.order_date, m.product_name, m.price, 
	CASE
		WHEN s.order_date < me.join_date THEN 'N'
        WHEN s.order_date >= me.join_date THEN 'Y'
        else 'N'
        END as members
from sales as s
join menu as m on s.product_id = m.product_id
left join members as me on s.customer_id = me.customer_id
ORDER BY s.customer_id, s.order_date, m.price desc;


CREATE TABLE IF NOT EXISTS dannys_sales(
customer_id varchar(5),
order_date DATE,
product_name VARCHAR(20) CHARACTER SET utf8mb4,
price INT,
members varchar(1)
); 


INSERT INTO dannys_sales(customer_id, order_date, product_name, price, members)
select 
	s.customer_id, 
	s.order_date, 
	m.product_name, 
	m.price, 
	CASE
		WHEN s.order_date < me.join_date THEN 'N'
        WHEN s.order_date >= me.join_date THEN 'Y'
        else 'N'
        END as members
from sales as s
join menu as m on s.product_id = m.product_id
left join members as me on s.customer_id = me.customer_id;


-- ranking the members on the basis of their memberships and orders after becoming a member
select *,
	CASE
		WHEN members = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, members ORDER BY order_date)
        ELSE NULL
		END as ranking
from dannys_sales;


-- inserting some dummy data for testing rankings
INSERT INTO dannys_sales(customer_id, order_date, product_name, price, members) values 
("A", "2021-01-18", "sushi", "10", "Y"),
("D", "2021-01-02", "sushi", "10", "N"),
("B", "2021-02-02", "curry", "15","Y");

