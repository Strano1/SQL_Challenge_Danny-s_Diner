CREATE SCHEMA dannys_diner;
GO
--SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT *
FROM SQLChallenge.dbo.sales

SELECT *
FROM SQLChallenge.dbo.menu

SELECT *
FROM SQLChallenge.dbo.members



--CASE STUDY QUESTIONS
--1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id Customer, CONCAT('$', SUM(m.price)) total_amt
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_amt DESC


--2. How many days has each customer visited the restaurant?

SELECT customer_id Customer, 
CONCAT(COUNT(DISTINCT order_date), ' ', 'days') days_visited
FROM sales
GROUP BY customer_id
ORDER BY days_visited DESC


--3. What was the first item from the menu purchased by each customer?

SELECT customer, product
FROM 
(SELECT s.customer_id customer,
s.order_date, m.product_name as product, 
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS row_num
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id) temp_table
WHERE row_num = 1


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name, COUNT(s.product_id) no_of_purchases, CONCAT('$', SUM(m.price)) total_sales
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY total_sales DESC


--5. Which item was the most popular for each customer?

SELECT customer, product_name, no_of_purchases FROM
(SELECT s.customer_id customer, m.product_name, COUNT(s.product_id) no_of_purchases,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS pop_purchase
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id, product_name, s.product_id) T1
WHERE pop_purchase = 1


--6. Which item was purchased first by the customer after they became a member?

--SELECT customer, product_name
FROM
(SELECT s.customer_id customer, m.product_name, s.order_date,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS row_num
FROM menu as m
JOIN sales as s
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date <= s.order_date
ORDER BY s.customer_id, order_date) T2
WHERE row_num = 1

SELECT Customer, Product_name
FROM 
(SELECT s.customer_id Customer, product_name, DATEDIFF (day, join_date, order_date) as diff,
RANK () OVER(PARTITION BY s.customer_id ORDER BY DATEDIFF(day, join_date, order_date)) rn
FROM Sales s
JOIN Menu M
ON S.product_id = M.product_id
JOIN Members Me
ON S.customer_id = Me.customer_id
WHERE order_date >= join_date) mn
WHERE rn = 1


--7. Which item was purchased just before the customer became a member?

SELECT Customer, Product_name
FROM 
(SELECT s.customer_id Customer, product_name, DATEDIFF (day, order_date, join_date) as diff,
RANK () OVER(PARTITION BY s.customer_id ORDER BY DATEDIFF(day, order_date,join_date)) rn
FROM Sales s
JOIN Menu M
ON S.product_id = M.product_id
JOIN Members Me
ON S.customer_id = Me.customer_id
WHERE order_date < join_date) mn
WHERE rn = 1


--8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id customer, COUNT(s.product_id) purchases, 
CONCAT('$', SUM(m.price)) amt_spent
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date > s.order_date
GROUP BY s.customer_id


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer, CONCAT(SUM(points), ' ', 'points') total_tally
FROM
(SELECT s.customer_id customer, s.product_id, m.product_name, m.price,
CASE WHEN m.product_name = 'sushi' THEN price * 20
ELSE price * 10 END AS points
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id) T4
GROUP BY customer


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT afr.customer_id, CONCAT((o_points + n_points), ' ', 'points') t_points
FROM
(SELECT customer_id, SUM(p_b) as o_points
FROM
(SELECT s.customer_id, product_name, price,
CASE WHEN product_name = 'sushi' THEN price * 20
ELSE price * 10
END p_b
FROM
members m JOIN sales s
ON m.customer_id = s.customer_id
JOIN menu mm
ON mm.product_id = s.product_id
WHERE order_date < join_date) b
GROUP BY customer_id
) bfr
JOIN
(SELECT s.customer_id, SUM(price * 20) n_points
FROM members m JOIN sales s
ON m.customer_id = s.customer_id
JOIN menu mm
ON mm.product_id = s.product_id
WHERE order_date >= join_date
AND order_date < '2021-02-01'
GROUP BY s.customer_id) afr
ON
bfr.customer_id = afr.customer_id


--BONUS QUESTIONS

--1. Recreate the table with customer_id, order_date, product_name, price and member columns

SELECT s.customer_id, order_date, product_name, price,
CASE WHEN s.customer_id IN
(SELECT customer_id FROM members)
AND order_date >= join_date
THEN 'Y' ELSE 'N'
END member
FROM sales s JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members me
ON s.customer_id = me.customer_id
ORDER BY customer_id, order_date, price DESC


--2. Rank products for customers and use null if the customer is not a member then.

WITH df AS
(SELECT s.customer_id, order_date, product_name, price,
CASE WHEN s.customer_id IN
(SELECT customer_id	FROM members)
AND order_date >= join_date
THEN 'Y' ELSE 'N'
END member
FROM sales s JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members me
ON s.customer_id = me.customer_id)
SELECT *,
CASE WHEN member = 'Y' THEN RANK()OVER(PARTITION BY customer_id, member
ORDER BY order_date)
ELSE NULL
END ranking
FROM df
ORDER BY customer_id, order_date, price DESC