select prodid, count(*)
from Dim_products$
group by ProdID
having count(*) > 1
--------------------------------

select distinct *
into Temp_Sales
from Fact_sales$

select * from Temp_Sales

truncate table fact_sales$

insert into Fact_sales$
select * from Temp_Sales
drop table temp_sales

select * from Fact_sales$
----------------------------------------------------

select distinct *
into Temp_Products
from Dim_products$

select * from Temp_Products

truncate table dim_products$

insert into Dim_products$
select * from Temp_Products
drop table Temp_Products

select * from Dim_products$
---------------------------------------------------

select distinct *
into temp_customer_id
from Customers_id$

select * from temp_customer_id

truncate table customers_id$

insert into Customers_id$
select * from temp_customer_id
drop table temp_customer_id

select * from Customers_id$
---------------------------------------------------

alter table fact_sales$
add 
	constraint FK_Sales_Products foreign key (prodId) references dim_products$(prodid),
	constraint FK_Sales_Customer foreign key (custid) references customers_id$(custid)
---------------------------------------------------

select
	count(orderid) as Total_Orders,
	sum(quantity) as Total_Units_Sold,
	sum([gross revenue]) as Total_Gross_Revenue,
	sum([net revenue]) as Total_Net_Revenue,
	sum([gross revenue] - [net revenue]) as Total_Discount,
	round((sum([gross revenue] - [net revenue])/ sum([gross revenue])) * 100, 2) as Discount_Percentage
from Fact_sales$

select product_name, sum([net revenue]) as "Revenue by Product"
from Fact_sales$
join Dim_products$ on Fact_sales$.ProdID = Dim_products$.ProdID
group by Product_Name
order by [Revenue by product] desc

select customer_name, sum([net revenue]) as "Revenue by Customer"
from Fact_sales$
join Customers_id$ on Fact_sales$.CustID = Customers_id$.CustID
group by Customer_Name
order by [Revenue by Customer] desc

select customer_name, product_name, sum([net revenue]) as "Revenue"
from Fact_sales$
join Customers_id$ on Fact_sales$.CustID = Customers_id$.CustID
join Dim_products$ on Fact_sales$.ProdID = Dim_products$.ProdID
where Discount > 0
group by Customer_Name, Product_Name
order by Revenue

select month(orderdate) "Monthno", sum([net revenue]) as "Monthly Revenue"
from Fact_sales$
group by month(orderdate)
order by monthno asc