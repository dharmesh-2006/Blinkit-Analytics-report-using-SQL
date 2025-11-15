
create table blinkit_products(
product_id int primary key,                              product_id.pk
product_name varchar(50),
category varchar(50),
brand varchar(20)	,
price numeric(8,2)	,
mrp decimal,
margin_percentage int,
shelf_life_days int,
min_stock_level int,
max_stock_level int
);






create table blinkit_delivery_performance(
order_id bigint primary key,                          order_id.fk                   
delivery_partner_id int,
promised_time timestamp,
actual_time timestamp,
delivery_time_minutes int,
distance_km numeric(10,2),
delivery_status varchar(100),
reasons_if_delayed varchar (30)
);

create table blinkit_customer_fed(
feedback_id int primary key,                     feedback_id.pk
order_id bigint ,                               
customer_id bigint,                                 c.id .fk
rating varchar(10),
feedback_text text,
feedback_category varchar(40),	
sentiment	varchar(40),
feedback_date date,
);
-- add foreign key





create table blinkit_inventory_new(
product_id int ,                          product_id.fk{}                               
date date,
stock_received int,
damaged_stock int
)
-- add fk 







create table blinkit_customer(
customer_id int,                         customer_id _pk                      
customer_name varchar(50),
email varchar(50),
phone bigint	,
address varchar(50),	
area varchar(40)	,
pincode varchar(40),
registration_date date,
customer_segment varchar(40),
total_orders int,
avg_order_value numeric(10,2)
)




create table blinkit_ord_itm(
order_id bigint,                                  order_id{}                   
product_id int,                                    pro>{}
quantity int,
unit_price numeric
)




create table blinkit_marketing_perf(
 campaign_id int,                         campaigen pk
 campaign_name varchar(70),
 date date,
 target_audience varchar(40),
 channel varchar(20),
 impressions int,
 clicks int,
 conversions int,
 spend numeric(10,2),
 revenue_generated numeric(10,2),	
 roas numeric (10,2)
)

alter table blinkit_orders add constraint pk_order_id primary key (order_id);


-- querys from here 
How many total orders, customers, and feedbacks are recorded in the Blinkit system?

alter table blinkit_customer
add column customer_serial serial

select * from blinkit_customer

alter table blinkit_customer
add constraint pk_customer_serial
primary key (customer_serial)


alter table blinkit_customer_fed
add column customer_serial serial



alter table blinkit_customer_fed
add constraint fk_customer_serial
foreign key (customer_serial)
references blinkit_customer(customer_serial)


select * from blinkit_customer_fed


select customer_id ,count(*) from blinkit_customer
group by customer_id
having count(*) > 1

select customer_id ,count(feedback_id) from blinkit_customer_fed
group by customer_id
having count(feedback_id)> 1


