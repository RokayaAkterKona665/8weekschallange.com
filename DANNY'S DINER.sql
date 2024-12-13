--Q1. WHAT IS THE TOTAL AMOUNT EACH CUSTOMER SPENT AT THE RESTURANT?
SELECT
	CUSTOMER_ID,
	SUM(PRICE) AS TOTAL_AMOUNT	
FROM 
SALES JOIN MENU ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
GROUP BY
CUSTOMER_ID

--Q2. HOW MANY DAYS HAS EACH CUSTOMER VISITED THE RESTAURANT??
SELECT 
	CUSTOMER_ID,
	COUNT(DISTINCT ORDER_DATE) AS NO_OF_DAYS
FROM 
	SALES
GROUP BY 
	CUSTOMER_ID

--Q3. What was the first item from the menu purchased by each customer?
WITH firstorder AS(
SELECT
	customer_id,product_name, 
	rank() over(partition by customer_id order by order_date ) as First_purchased_item
FROM 
	sales join menu on sales.product_id = menu.product_id
)
SELECT
	Customer_id,
	Product_name
FROM 
	firstorder
WHERE
	First_purchased_item = 1

--Q4. what is the most purchased item on the menu and how many times was it purchased by all customers?
With most_purchased_item as 
(SELECT
	product_name,
	count(*) over (partition by sales.product_id )as total_purchased_item
FROM sales join menu on sales.product_id = menu.product_id)
SELECT top 1 
	product_name,
	max(total_purchased_item) as no_of_purchased
FROM most_purchased_item
GROUP BY product_name
order by no_of_purchased desc


--5.which item was the	most popular item for each customer?
With itemCounts As(
SELECT
customer_id,
product_name,
count(product_name)as purchase_count
FROM sales join menu on sales.product_id = menu.product_id
GROUP BY customer_id,
product_name
),
rankedItems as
(SELECT 
	customer_id,
	product_name,
	purchase_count,
	DENSE_RANK() over(partition by customer_id order by purchase_count desc) As rank
FROM itemCounts)
SELECT 
	customer_id,
	product_name,
FROM
rankedItems
WHERE RANK =1

--6.which itme was purchased first by the customer after they became a member?
with first_purchase as
(SELECT 
	sales.customer_id,
	menu.product_name,order_date,
	ROW_NUMBER()over(partition by sales.customer_id order by order_date) as rank
FROM
	sales join members on sales.customer_id = members.customer_id
	join menu on sales.product_id = menu.product_id
WHERE 
order_date>'2021-01-07' and order_date>'2021-01-09'
GROUP BY
	sales.customer_id,
	menu.product_name,order_date
)
SELECT
	customer_id,
	product_name
FROM 
first_purchase
WHERE rank =1

--7. Which item was purchased just before the customer became member?
with purchased_before_member as(
SELECT 
	sales.customer_id,
	product_name,
	order_date,
	dense_rank()over(partition by sales.customer_id order by order_date) as rank
FROM 
	sales join menu on sales.product_id =menu.product_id
	join members on sales.customer_id = members.customer_id
where
order_date< '2021-01-07' and order_date< '2021-01-09')
SELECT
	customer_id,
	product_name
FROM purchased_before_member
where rank =1


--8.What is the total items and amount spent for each member before they became a member ?
SELECT 
	sales.Customer_id,
	sum(menu.price) as total_spent,
	count(sales.product_id) as total_items
FROM
	sales join menu on sales.product_id = menu.product_id
	join members on sales.customer_id =members.customer_id 
WHERE order_date< join_date
GROUP BY sales.customer_id

--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With each_spent AS 
(SELECT
	customer_id,
case
	when sales.product_id =1 then (price*2*10)
	else 10 *price
	end as points
FROM
sales join menu on sales.product_id = menu.product_id)
SELECT
	customer_id,
	SUM(points) as total_points
from each_spent
GROUP BY Customer_id

--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of january?
With valid_customer as 
(SELECT
	sales.customer_id,
	eomonth(order_date) as end_month,
	case
		when order_date>=join_date and order_date<=dateadd(dd,7,join_date) and product_name <>'shushi' then price*2*10
		when order_date>dateadd(dd,7,join_date) then price*10
		else price*10
		end as point
FROM sales
		join menu on sales.product_id = menu.product_id
		join members on sales.customer_id = members.customer_id)
SELECT
	customer_id,
	sum(point) total_point
FROM valid_customer
WHERE end_month<= '2021-01-31' and point is not null
GROUP BY customer_id

---Bonus Questiond, JOin all the things
--The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

SELECT
	sales.customer_id,
	order_date,
	product_name,
	price,
	 case when order_date>=join_date  then 'Y'
		else 'N'
		end as member
FROM
sales join menu on sales.product_id = menu.product_id
left join members on sales.customer_id = members.customer_id

--Rank All The Things
--Danny also requires further information about the ranking of customer products, 
--but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
with member_validation as
(SELECT 
	sales.customer_id,
	order_date,
	product_name,
	price,
	case when order_date>=join_date then 'Y'
		else 'N'
		end as member
FROM 
	sales join menu on sales.product_id = menu.product_id
	left join members on sales.customer_id = members.customer_id),
ranking as
(SELECT *,
	case 
	when member ='Y' then rank() OVER (PARTITION BY customer_id,member ORDER BY order_date)
	else   null
	end as ranking
FROM 
member_validation
)
SELECT* FROM ranking


