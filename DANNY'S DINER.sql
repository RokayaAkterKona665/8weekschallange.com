SELECT*FROM SALES;
SELECT*FROM MENU;
SELECT*FROM MEMBERS;

--1. WHAT IS THE TOTAL AMOUNT EACH CUSTOMER SPENT AT THE RESTURANT?
SELECT
	CUSTOMER_ID,
	SUM(PRICE) AS TOTAL_AMOUNT_SPENT	
FROM 
SALES JOIN MENU ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
GROUP BY
CUSTOMER_ID

--2. HOW MANY DAYS HAS EACH CUSTOMER VISITED THE RESTAURANT??
SELECT 
	CUSTOMER_ID,
	COUNT(DISTINCT ORDER_DATE) AS NUMBER_OF_DAYS_VISITED_RESTAURANT
FROM SALES
GROUP BY 
CUSTOMER_ID

--3. What was the first item from the menu purchased by each customer?
With firstorder AS(
select 
customer_id,product_name, rank() over(partition by customer_id order by order_date ) as First_purchased_item
from sales join menu on sales.product_id = menu.product_id
)
select
Customer_id,
Product_name
From firstorder
where First_purchased_item = 1



--4. what is the most purchased item on the menu and how many times was it purchased by all customers?
With most_purchased_item as (select
product_name,
count(*) over (partition by sales.product_id )as total_purchased_item
from sales join menu on sales.product_id = menu.product_id)
select top 1 product_name,
max(total_purchased_item) as no_of_purchased
from most_purchased_item
group by product_name
order by no_of_purchased desc


--5.which item was the	most popular item for each customer?
With itemCounts As(
select
customer_id,
product_name,
count(product_name)as purchase_count
from sales join menu on sales.product_id = menu.product_id
group by customer_id,
product_name
),
rankedItems as
(select 
customer_id,
product_name,
purchase_count,
DENSE_RANK() over(partition by customer_id order by purchase_count desc) As rank
from itemCounts)
select 
customer_id,
product_name,
purchase_count
from
rankedItems
where RANK =1

--6.which itme was purchased first by the customer after they became a member?
with first_purchase as (select 
sales.customer_id,
menu.product_name,order_date,
ROW_NUMBER()over(partition by sales.customer_id order by order_date) as rank
from
sales join members on sales.customer_id = members.customer_id
join menu on sales.product_id = menu.product_id
where order_date>'2021-01-07' and order_date>'2021-01-09'
group by sales.customer_id,
menu.product_name,order_date
)
select
customer_id,
product_name
from 
first_purchase
where rank =1


--7. Which item was purchased just before the customer became member?
with purchased_before_member as(
select 
sales.customer_id,
product_name,
order_date,
dense_rank()over(partition by sales.customer_id order by order_date) as rank
from sales join menu on sales.product_id =menu.product_id
join members on sales.customer_id = members.customer_id
where order_date< '2021-01-07' and order_date< '2021-01-09')
select
customer_id,
product_name
from purchased_before_member
where rank =1


--8.What is the total items and amount spent for each member before they became a member ?
Select 
sales.Customer_id,
sum(menu.price) as total_spent,
count(sales.product_id)  as total_items
from
sales join menu on sales.product_id = menu.product_id
join members on sales.customer_id =members.customer_id 
Where order_date< join_date
group by sales.customer_id


--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With each_spent AS 
(select
customer_id,
case when sales.product_id =1 then (price*2*10)
	else 10 *price
	end as points
from sales join menu on sales.product_id = menu.product_id)
select
customer_id,
SUM(points) as total_points
from each_spent
group by Customer_id

--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of january?
With valid_customer as (select
sales.customer_id,
eomonth(order_date) as end_month,
case
	when order_date>=join_date and order_date<=dateadd(dd,7,join_date) and product_name <>'shushi' then price*2*10
	when order_date>dateadd(dd,7,join_date) then price*10
	else price*10
	end as point
	from sales
		join menu on sales.product_id = menu.product_id
		join members on sales.customer_id = members.customer_id)
select
customer_id,
sum(point) total_point
from valid_customer
where end_month<= '2021-01-31' and point is not null
group by customer_id

---Bonus Questiond, JOin all the things
--The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

select
sales.customer_id,
order_date,
product_name,
price,
 case when order_date>=join_date  then 'Y'
	else 'N'
	end as member
from sales join menu on sales.product_id = menu.product_id
left join members on sales.customer_id = members.customer_id

--Rank All The Things
--Danny also requires further information about the ranking of customer products, 
--but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
with member_validation as (select 
sales.customer_id,
order_date,
product_name,
price,
case when order_date>=join_date then 'Y'
	else 'N'
	end as member

from sales join menu on sales.product_id = menu.product_id
left join members on sales.customer_id = members.customer_id
),
ranking as(select
*,
case when member ='Y' then rank() OVER (PARTITION BY customer_id,member ORDER BY order_date)
else   null
end as ranking
from member_validation
)
select* from ranking


