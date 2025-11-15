
1.1 Customer Overview
-- Q1. How many total orders, customers, and feedbacks are recorded in the Blinkit system?

CREATE VIEW total_orders_customers_fedback as
select
(select count(*)  as total_customers  from blinkit_customer as total_customers),
(select count(*)  as total_orders from blinkit_customer as total_orders),
(select count(*) as customers_feedback from blinkit_customer_fed as customers_feedback );

select * from total_orders_customers_fedback
-- 2nd approch 
SELECT 'Orders' AS table_name, COUNT(*) AS total_count FROM blinkit_orders
UNION ALL
SELECT 'Customers', COUNT(*) FROM blinkit_customer
UNION ALL
SELECT 'Feedback', COUNT(*) FROM blinkit_customer_fed;


1.2 Customer Segmentation

-- Q2. Who are the top 10 premium customers based on their total number of orders?

-- Approach 1 – Simple Count
CREATE VIEW TOP_10_customers_orders AS 
select customer_id,count(order_id)as total_orders from blinkit_orders
group by customer_id
order by total_orders desc
limit 10

select * from top_10_customers_orders

-- Approach 2 – Join with Customer Table

select c.customer_id,
	c.customer_name,
	c.customer_segment,
	count(o.order_id) as total_order
	from blinkit_orders o
    join blinkit_customer c
on o.customer_id = c.customer_id
where c.customer_segment = 'Premium'
group by c.customer_id,
	c.customer_name,
	c.customer_segment
	order by count(o.order_id) desc
	limit 10

-- Q3. What is the average order value for each customer segment (Premium, Regular, New, Inactive)?
-- Approach 1 – Basic Group By


select c.customer_segment,
	round(avg(o.order_id),2) as total
from blinkit_orders o
inner join blinkit_customer c
on o.customer_id = c.customer_id
group by c.customer_segment



Query 4: Segmentation Value Quantification
-- How does the average `avg_order_value` differ between `customer_segment` (Premium, Regular, New, Inactive)?


SELECT
    customer_segment,
    round(AVG(avg_order_value),2) AS average_order_value
FROM
    blinkit_customer
GROUP BY
    1
ORDER BY
    average_order_value DESC;

-- Query 5: Operational Support for New Customer Acquisition Areas

WITH NewCustomerAreas AS (
    -- Step 1: Identify the top 5 areas with the highest count of 'New' customers.
    SELECT
        area,
        COUNT(customer_id) AS total_new_customer_count
    FROM
        blinkit_customer -- FIX 1: Corrected table name from blinkit_customer
    WHERE
        customer_segment = 'New'
    GROUP BY
        area
    ORDER BY
        total_new_customer_count DESC
    LIMIT 5
)
SELECT
    NCA.area, -- FIX 2: Corrected column selection/aliasing
    ROUND((SUM(CASE
        WHEN DP.delivery_status = 'On Time'
        THEN 1 ELSE 0
        END) * 100.0) / COUNT(DP.order_id),2) AS on_time_delivery_rate_percent
FROM
    NewCustomerAreas AS NCA
INNER JOIN
    blinkit_customer AS C -- FIX 3: Corrected table name from blinkit_customer
    ON NCA.area = C.area
INNER JOIN
    blinkit_customer_fed AS CF -- FIX 4: Corrected table name from blinkit_customer_fed
    ON C.customer_id = CF.customer_id
INNER JOIN
    blinkit_delivery_performance AS DP
    ON CF.order_id = DP.order_id
GROUP BY
    NCA.area
ORDER BY
    on_time_delivery_rate_percent ASC;


1.3 Customer Feedback & Behavior


-- Q6. What is the most common sentiment in customer feedback?

select sentiment,count(*)as total from blinkit_customer_fed
group by sentiment
order by count(*) desc

-- Approach 2 – Distribution in Percentage


select sentiment,count(*),
ROUND(100.0* count(*) / (select count(*) from blinkit_customer_fed),2)as persentage
from blinkit_customer_fed
group by sentiment
order by persentage desc
limit 2;


-- Q7. Which customers have given multiple negative feedbacks (more than twice)?


select f.customer_id ,c.customer_name, count(f.feedback_id) as negative_feedback 
from blinkit_customer_fed f
inner join blinkit_customer c
on f.customer_id = c.customer_id
where sentiment = 'Negative'
group by f.customer_id,c.customer_name
having count(f.feedback_id) > 1
order by negative_feedback desc;

-- Query 8: Loyalty Impact of Positive vs. Neutral Experience
-- Compare the average total orders for customers who gave Positive feedback vs. Neutral feedback.


select
		c_f.sentiment,
		avg(o.order_total) as avg_orders
from blinkit_customer_fed c_f
join blinkit_orders o
on c_f.customer_id = o.customer_id
where c_f.sentiment in ('Neutral','Positive')
group by 1


2.1 Delivery Speed & Timing

-- Q9. What is the percentage of on-time vs delayed deliveries?


select delivery_status, 
					count(*) as total_delivery,
					round(100.0 * count(*) /(select count(*) from blinkit_delivery_performance) ,2) as persentage
from blinkit_delivery_performance
group by delivery_status

-- 2nd approch

select  
	ROUND(100.0*AVG(case 
		when delivery_status = 'On Time' then 1 else 0 end),2) AS ON_TIME_PER,
	ROUND(100.0*AVG(case
		when delivery_status = 'Slightly Delayed' then 1 else 0 end ),2)AS DELAYED_PER,
	ROUND(100.0*AVG(case 
		when delivery_status = 'Significantly Delayed' then 1 else 0 end),2)AS Significantly_DELAYED_PER

from blinkit_delivery_performance

-- Q10. What is the average delivery distance and delivery time across all orders?

select 
		round(avg(delivery_time_minutes),2) as avg_delivery_tie_min , round(avg(distance_km),2) as avg_distance_km
from blinkit_delivery_performance


-- Approach 2 – Averages by City

CREATE VIEW avg_time_and_distance AS
select b_c.area, 
			round(avg(b_d_p.delivery_time_minutes),2) as avg_delivery_tie_min ,
			round(avg(b_d_p.distance_km),2)as avg_distance_km
			
from blinkit_delivery_performance b_d_p
inner join blinkit_orders b_o
on b_d_p.order_id = b_o.order_id
inner join blinkit_customer b_c
on b_o.customer_id = b_c.customer_id

group by b_c.area
order by avg_distance_km desc


-- Query 11: Delivery Status Distribution by Peak/Off-Peak Hour
-- What is the delivery status distribution during peak hours (e.g., 7 PM - 10 PM) compared to off-peak hours?


with timesoltsumary as(
select
	case
		when 
			EXTRACT(HOUR from  promised_time) between 19 and 22 then 'peak hour (7PM-10PM)'
			else 'off_peak hour'
			end as time_window,
			delivery_status,
			count(order_id) as status_count
	
	from blinkit_delivery_performance
	group by 1,2
),
total_orders as(
	
	select 
	count(order_id) as total_orders,
	case
		when 
			EXTRACT(HOUR from  promised_time) between 19 and 22 then 'peak hour (7PM-10PM)'
			else 'off_peak hour'
			end as time_window
	from blinkit_delivery_performance
	
	group by 2
)
select 
	t1.time_window,
	t1.delivery_status,
	round((t1.status_count)*100.0/t2.total_orders,2) as total_persentage

	from timesoltsumary t1
	inner join total_orders t2
	on t1.time_window = t2.time_window
	

2.2 Delay Causes & Trends


-- Q12 total persentage of reasons of delayed
create view delayed as
SELECT reasons_if_delayed ,
		COUNT(*),
		round(100.0 * count(*)/(select count(*) from blinkit_delivery_performance),2) as persantage
FROM blinkit_delivery_performance
GROUP BY reasons_if_delayed

-- 2nd approch 
select
	round(100.0*avg(case 
	 					when reasons_if_delayed = 'Traffic' then 1 else 0 end),2),
	round(100.0*avg(case 
						when reasons_if_delayed is nuLL then 1 else 0 end),2)
from blinkit_delivery_performance

--Q13. Which types of complaints (like delivery or quality) are increasing month by month?

-- 1ST APPROCH BY MONTH NUMBER 

select extract ('month' from feedback_date) as month,
		  count(feedback_id) as negative_fed,
		  feedback_category
		  
from blinkit_customer_fed
where sentiment = 'Negative'
group by 1,3

-- 2nd approch 
select to_char(feedback_date, 'month') as month_name,
		count(feedback_id) as total_delivery,
		feedback_category,
		feedback_text
from blinkit_customer_fed
where rating < 3 
group by 1,3,4
having count(feedback_id) >= 5
order by total_delivery desc

-- Q14. Which `area` (city/locality) has the highest concentration of 'Significantly Delayed' deliveries and a high proportion of Premium customers?


select c.area, count(f.order_id) as Significantly_Delayed_count
from blinkit_delivery_performance p
inner join blinkit_customer_fed f
on p.order_id = f.order_id 
inner join blinkit_customer c
on f.customer_id = c.customer_id

where c.customer_segment = 'Premium'
	and delivery_status = 'Significantly Delayed'

group by 1
order by Significantly_Delayed_count desc
limit 10;

-- Query 15: Root Causes of Negative Delivery Experiences
-- For orders with Negative sentiment, what are the top 3 most cited `reasons_if_delayed`?

select
		count(*) as count_of_negative_fed,
		reasons_if_delayed

from blinkit_delivery_performance p
inner join blinkit_customer_fed f on p.order_id = f.order_id  
where reasons_if_delayed is not null
and reasons_if_delayed != ''
and sentiment = 'Negative'
group by 2

2.3 Delivery Partner Performance

Query 16: Segmentation Value Quantification
-- How does the average `avg_order_value` differ between `customer_segment` (Premium, Regular, New, Inactive)?


SELECT
    customer_segment,
    round(AVG(avg_order_value),2) AS average_order_value
FROM
    blinkit_customer
GROUP BY
    1
ORDER BY
    average_order_value DESC;

3. Product & Inventory Analytics
3.1 Product Quality & Issues


Query 17: Failure Mode Diagnosis for Popular Products
-- For the top 5 most popular products, compare the rate of Negative feedback for 'Product Quality' vs. 'Delivery'.

WITH TopProducts AS (
    SELECT product_id
    FROM blinkit_ord_itm
    GROUP BY 1
    ORDER BY SUM(quantity) DESC
    LIMIT 5
)
SELECT
    T4.product_name,
    SUM(CASE WHEN T2.feedback_category = 'Product Quality' AND T2.sentiment = 'Negative' THEN 1 ELSE 0 END) AS quality_neg_count,
    SUM(CASE WHEN T2.feedback_category = 'Delivery' AND T2.sentiment = 'Negative' THEN 1 ELSE 0 END) AS delivery_neg_count
FROM
    TopProducts AS T1
JOIN
    blinkit_ord_itm AS T3 ON T1.product_id = T3.product_id
JOIN
    blinkit_customer_fed AS T2 ON T3.order_id = T2.order_id
JOIN
    blinkit_products AS T4 ON T1.product_id = T4.product_id
GROUP BY
    1
ORDER BY
    (2 + 3) DESC;

-- Question: 18
-- Which products get negative reviews for quality the most?


select p.product_name,
		count(f.feedback_id),
		f.feedback_category
	
from blinkit_customer_fed f	
inner join blinkit_ord_itm o on f.order_id = o.order_id
inner join blinkit_products p on p.product_id = o.product_id

where f.sentiment = 'Negative' and f.rating < 3 and f.feedback_category = 'Product Quality'
group by 1,3

3.2 Sales & Demand

-- Q19. Which products have high demand based on total quantity sold?
select count(o.order_id) as total_orders,p.product_id,p.product_name,sum(o.quantity)as total_quantity_sold
from blinkit_products p
inner join blinkit_ord_itm o
on p.product_id = o.product_id
group by 2,3
having sum(o.quantity) >= 50
order by 4 desc

3.3 Inventory Risk
-- Query 20: Inventory vs. Demand Risk for Quality Issues?


WITH problem_matrix AS(

	SELECT o.product_id , count(c.order_id) as negative_order_count
	FROM blinkit_ord_itm o
	inner join blinkit_customer_fed c
	on o.order_id = c.order_id

where 
	c.sentiment = 'Negative'
	and c.feedback_category = 'Delivery'
	and o.quantity > (select min_stock_level from blinkit_products where product_id = o.product_id)

group by 1
)

select 
    bp.product_name,bp.category,		
	pm.negative_order_count

	from problem_matrix pm
	inner join blinkit_products bp
	on pm.product_id = bp.product_id

order by pm.negative_order_count desc
limit 5;

3.4 Product Margins

-- Query 21: Average Margin of Problematic Products

select product_name ,category, avg(margin_percentage),rating,sentiment 
from blinkit_customer_fed f
inner join blinkit_ord_itm o
on f.order_id = o.order_id
inner join blinkit_products p
on o.product_id = p.product_id

where  rating < 3
group by 1,2,4,5

Geographic Insights
4.1 Area-Based Performance

-- Q22. Which cities or areas have the highest number of total orders?

select count(o.order_id) as total_orders ,c.area
from blinkit_customer c
inner join blinkit_orders o
on c.customer_id = o.customer_id
group by c.area
order by total_orders desc 

-- Approach 2 – Add Share Percentage

select  c.area,count(order_id),
round(100.0*count(*)/(select count(*) from blinkit_orders),2) as per_of_total_order
from blinkit_customer c
inner join blinkit_orders o
on c.customer_id = o.customer_id
group by c.area
order by per_of_total_order desc
limit 5


-- Q23. Which `area` (city/locality) has the highest concentration of 'Significantly Delayed' deliveries and a high proportion of Premium customers?


select c.area, count(f.order_id) as Significantly_Delayed_count
from blinkit_delivery_performance p
inner join blinkit_customer_fed f
on p.order_id = f.order_id 
inner join blinkit_customer c
on f.customer_id = c.customer_id

where c.customer_segment = 'Premium'
	and delivery_status = 'Significantly Delayed'

group by 1
order by Significantly_Delayed_count desc
limit 10;


-- Query 24: Operational Support for New Customer Acquisition Areas




WITH NewCustomerAreas AS (
    -- Step 1: Identify the top 5 areas with the highest count of 'New' customers.
    SELECT
        area,
        COUNT(customer_id) AS total_new_customer_count
    FROM
        blinkit_customer -- FIX 1: Corrected table name from blinkit_customer
    WHERE
        customer_segment = 'New'
    GROUP BY
        area
    ORDER BY
        total_new_customer_count DESC
    LIMIT 5
)
SELECT
    NCA.area, -- FIX 2: Corrected column selection/aliasing
    ROUND((SUM(CASE
        WHEN DP.delivery_status = 'On Time'
        THEN 1 ELSE 0
        END) * 100.0) / COUNT(DP.order_id),2) AS on_time_delivery_rate_percent
FROM
    NewCustomerAreas AS NCA
INNER JOIN
    blinkit_customer AS C -- FIX 3: Corrected table name from blinkit_customer
    ON NCA.area = C.area
INNER JOIN
    blinkit_customer_fed AS CF -- FIX 4: Corrected table name from blinkit_customer_fed
    ON C.customer_id = CF.customer_id
INNER JOIN
    blinkit_delivery_performance AS DP
    ON CF.order_id = DP.order_id
GROUP BY
    NCA.area
ORDER BY
    on_time_delivery_rate_percent ASC;

5. Marketing & Performance Analytics
5.1 Campaign Performance

--q25. Compare the conversion rate and Return on Ad Spend (RoAS) between campaigns targeting Inactive and New Users.
-- Which audience type performs better

select target_audience,
		sum(conversions)*100/sum(clicks) as conversion_rate,
		round(sum(revenue_generated)/sum(spend),2) as Return_on_Ad_Spend
from blinkit_marketing_perf
where target_audience in ('Inactive' , 'New Users')
group by 1;


-- Q26: Most Profitable Campaign Setup (Revenue/Conversion)
-- Identify the top 3 `channel` and `target_audience` combinations that yielded the highest


SELECT
    channel,
    target_audience,
    SUM(revenue_generated) / SUM(conversions) AS avg_revenue_per_conversion
FROM
    blinkit_marketing_perf
WHERE
    conversions > 0
GROUP BY
    1, 2
ORDER BY
    avg_revenue_per_conversion DESC
LIMIT 3;


Summary Metrics

-- Q27. How many total orders, customers, and feedbacks are recorded in the Blinkit system?

CREATE VIEW total_orders_customers_fedback as
select
(select count(*)  as total_customers  from blinkit_customer as total_customers),
(select count(*)  as total_orders from blinkit_customer as total_orders),
(select count(*) as customers_feedback from blinkit_customer_fed as customers_feedback );

select * from total_orders_customers_fedback

-- Q28. What is the average customer rating under each sentiment type?


select avg(cast(rating as int)),
		sentiment 
from blinkit_customer_fed
group by sentiment

alter table blinkit_customer_fed
alter column feedback_id type int
using rating :: integer;

