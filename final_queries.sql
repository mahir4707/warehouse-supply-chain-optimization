CREATE TABLE warehouse_details (

-- Base Columns
Warehouse_ID VARCHAR(20),
Location VARCHAR(50),
Current_Stock INT,
Demand_Forecast INT,
Lead_Time_Days INT,
Shipping_Time_Days INT,
Stockout_Risk INT,
Operational_Cost DECIMAL(12,2),
Supplier_ID VARCHAR(10),
Product_Category VARCHAR(50),
Monthly_Sales INT,
Order_Processing_Time DECIMAL(10,2),
Return_Rate DECIMAL(10,4),
Customer_Rating DECIMAL(5,2),
Warehouse_Capacity INT,
Storage_Cost DECIMAL(12,2),
Transportation_Cost DECIMAL(12,2),
Backorder_Quantity INT,
Damaged_Goods INT,
Employee_Count INT,

-- Derived Columns (no logic here, only structure)
total_time DECIMAL(10,2),
sales_per_employee DECIMAL(12,4),
processing_per_unit DECIMAL(12,4),
demand_gap INT,
inventory_status VARCHAR(20),
warehouse_utilization DECIMAL(10,4),
utilization_category VARCHAR(20),
inventory_turnover DECIMAL(10,4),
turnover_category VARCHAR(20),
damage_rate DECIMAL(10,4),
forecast_error INT,
forecast_category VARCHAR(30),
accuracy DECIMAL(10,4),
accuracy_category VARCHAR(30),
demand_sales_zone VARCHAR(30),
total_cost DECIMAL(12,2),
Monthly_Revenue DECIMAL(12,2),
profit_margin DECIMAL(10,4),
estimated_profit DECIMAL(12,2),
risk_score DECIMAL(10,4),
salary_cost DECIMAL(12,2),
salary_per_employee DECIMAL(12,2),
revenue_per_employee DECIMAL(12,4),
stock_per_employee DECIMAL(12,4),
required_emp_sales DECIMAL(10,2),
required_emp_stock DECIMAL(10,2),
ideal_employee_count DECIMAL(10,2)

);

select * from warehouse_details

--1. Top Delayed Warehouses (Delivery Performance)

--Top 10 warehouses with highest average delivery time
select warehouse_id, avg(total_time) as avg_delivery_time
from warehouse_details
group by warehouse_id
order by avg_delivery_time desc
limit 10;

--Warehouses where actual delivery time exceeds expected lead time
select warehouse_id, avg(total_time) as avg_delivery_time, avg(lead_time_days) as avg_exp_time
from warehouse_details
group by warehouse_id
having avg(total_time) > avg(lead_time_days)


--Whether delay is due to processing time or shipping time
select warehouse_id, avg(order_processing_time) - avg(shipping_time_days) as diff,
case
when avg(order_processing_time) > avg(shipping_time_days)
then 'processing_delay'
else 'shipping_delay'
end as delay_type
from warehouse_details
group by warehouse_id


--Comparison of delayed vs on-time warehouses
SELECT 
    delay_flag,
    COUNT(*) AS warehouse_count
FROM (
    SELECT 
        Warehouse_ID,
        CASE 
            WHEN AVG(total_time) > AVG(lead_time_days)
            THEN 'Delayed'
            ELSE 'On Time / Faster'
        END AS delay_flag
    FROM warehouse_details
    GROUP BY Warehouse_ID
) t
GROUP BY delay_flag;

--Best-performing warehouses to set benchmark
SELECT 
    Warehouse_ID,
    AVG(total_time) AS avg_delivery_time,
    AVG(Lead_Time_Days) AS avg_expected_time,
    AVG(total_time) - AVG(Lead_Time_Days) AS gap
FROM warehouse_details
GROUP BY Warehouse_ID
HAVING AVG(total_time) <= AVG(Lead_Time_Days)
ORDER BY gap ASC
LIMIT 10;


--2. High Stockout Risk Locations (Inventory Risk)

--Top locations with highest stockout risk
select location, avg(stockout_risk) as total_stockout_risk
from warehouse_details
group by location
order by avg(stockout_risk) desc

--Warehouses with highest demand gap (demand > stock)
select warehouse_id, 
		sum(demand_forecast) as demand,
		sum(current_stock) as stock,
		sum(demand_forecast - current_stock) as demand_gap
from warehouse_details
group by warehouse_id
having sum(demand_forecast) > sum(current_stock) 
order by demand_gap desc

--Warehouses with highest backorder quantities
select warehouse_id, sum(backorder_quantity) as total_returned_order
from warehouse_details
group by warehouse_id
order by sum(backorder_quantity) desc

--Product categories contributing most to stockouts
select product_category, sum(demand_forecast - current_stock) as demand_gap
from warehouse_details
group by product_category 
order by sum(demand_forecast - current_stock) desc

--Locations consistently facing unmet demand
select location, sum(demand_forecast - current_stock) as demand_gap
from warehouse_details
group by location 
order by sum(demand_forecast - current_stock) desc

--3. Product-wise Sales Performance

--Top-selling and lowest-selling product categories
select product_category, 
		sum(monthly_sales) as total_sales
from warehouse_details
group by product_category
order by total_sales desc

--Supplier contribution to each product category
select product_category, 
		supplier_id,
		sum(monthly_sales) as total_sales
from warehouse_details
group by supplier_id, product_category
order by product_category, total_sales desc

--Categories with high returns or damaged goods
select product_category, 
		avg(return_rate) as avg_return_rate,
		sum(damaged_goods) as total_damaged
from warehouse_details
group by product_category
order by total_damaged desc

--Location-wise high-performing product categories
select location,
		product_category,
		sum(monthly_sales) as total_sales
from warehouse_details
group by location, product_category
order by location, total_sales desc

--Categories with high demand but low sales
SELECT 
    Product_Category,
    SUM(Demand_Forecast) AS total_demand,
    SUM(Monthly_Sales) AS total_sales,
    SUM(Demand_Forecast - Monthly_Sales) AS demand_gap
FROM warehouse_details
GROUP BY Product_Category
HAVING SUM(Demand_Forecast - Monthly_Sales) > 0
ORDER BY demand_gap DESC


--4. Cost vs Profit Analysis
--Warehouses with highest cost and lowest profit
SELECT 
    Warehouse_ID,
    SUM(total_cost) AS total_cost,
    SUM(estimated_profit) AS total_profit
FROM warehouse_details
GROUP BY Warehouse_ID
ORDER BY total_cost DESC, total_profit ASC;

--Warehouses with high cost but low sales (inefficient)
SELECT 
    Warehouse_ID,
    SUM(total_cost) AS total_cost,
    SUM(Monthly_Sales) AS total_sales
FROM warehouse_details
GROUP BY Warehouse_ID
ORDER BY total_cost DESC, total_sales ASC;

--Warehouses with low cost and high sales (efficient)
SELECT 
    Warehouse_ID,
    SUM(total_cost) AS total_cost,
    SUM(Monthly_Sales) AS total_sales
FROM warehouse_details
GROUP BY Warehouse_ID
ORDER BY total_cost ASC, total_sales DESC;

--Cost per unit across warehouses and categories
SELECT 
    Warehouse_ID,
    SUM(total_cost) * 1.0 / SUM(Monthly_Sales) AS cost_per_unit
FROM warehouse_details
GROUP BY Warehouse_ID
ORDER BY cost_per_unit DESC;

--category level cost per unit
SELECT 
    Product_Category,
    SUM(total_cost) * 1.0 / SUM(Monthly_Sales) AS cost_per_unit
FROM warehouse_details
GROUP BY Product_Category
ORDER BY cost_per_unit DESC;

--Benchmark warehouses with highest profit margins
SELECT 
    Warehouse_ID,
    AVG(profit_margin) AS avg_profit_margin
FROM warehouse_details
GROUP BY Warehouse_ID
ORDER BY avg_profit_margin DESC
LIMIT 10;



--5. Demand vs Stock Comparison
--Warehouses with highest shortage (demand > stock)
SELECT 
    Warehouse_ID,
    SUM(Demand_Forecast - Current_Stock) AS demand_gap
FROM warehouse_details
GROUP BY Warehouse_ID
HAVING SUM(Demand_Forecast - Current_Stock) > 0
ORDER BY demand_gap DESC;

--Warehouses with highest overstock
SELECT 
    Warehouse_ID,
    SUM(Current_Stock - Demand_Forecast) AS overstock
FROM warehouse_details
GROUP BY Warehouse_ID
HAVING SUM(Current_Stock - Demand_Forecast) > 0
ORDER BY overstock DESC;

--Category-wise demand vs stock imbalance
SELECT 
    Product_Category,
    SUM(Demand_Forecast) AS total_demand,
    SUM(Current_Stock) AS total_stock,
    SUM(Demand_Forecast - Current_Stock) AS demand_gap
FROM warehouse_details
GROUP BY Product_Category
ORDER BY demand_gap DESC;

--Location-wise demand vs stock imbalance
SELECT 
    Location,
    SUM(Demand_Forecast) AS total_demand,
    SUM(Current_Stock) AS total_stock,
    SUM(Demand_Forecast - Current_Stock) AS demand_gap
FROM warehouse_details
GROUP BY Location
ORDER BY demand_gap DESC;

--Identification of high-demand vs low-demand zones
select warehouse_id,
		sum(demand_forecast) as total_demand,
		sum(current_stock) as total_stock,
		demand_sales_zone
from warehouse_details
group by warehouse_id, demand_sales_zone
order by total_demand desc

--OR
WITH thresholds AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Demand_Forecast) AS median_demand,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Current_Stock) AS median_stock
    FROM warehouse_details
)

SELECT 
    Warehouse_ID,
    SUM(Demand_Forecast) AS total_demand,
    SUM(Current_Stock) AS total_stock,
    
    CASE 
        WHEN SUM(Demand_Forecast) > t.median_demand 
             AND SUM(Current_Stock) < t.median_stock 
        THEN 'High Demand Zone'
        
        WHEN SUM(Demand_Forecast) < t.median_demand 
             AND SUM(Current_Stock) > t.median_stock 
        THEN 'Low Demand Zone'
        
        ELSE 'Balanced Zone'
        
    END AS demand_zone

FROM warehouse_details w
CROSS JOIN thresholds t
GROUP BY Warehouse_ID, t.median_demand, t.median_stock;

