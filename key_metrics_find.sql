CREATE TABLE warehouse_operations (
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
    
    Order_Processing_Time DECIMAL(5,2),
    Return_Rate DECIMAL(5,2),
    Customer_Rating DECIMAL(3,2),
    
    Warehouse_Capacity INT,
    
    Storage_Cost DECIMAL(12,2),
    Transportation_Cost DECIMAL(12,2),
    
    Backorder_Quantity INT,
    Damaged_Goods INT,
    
    Employee_Count INT
);

select * from warehouse_operations



--creating total cost column
alter table warehouse_operations
add total_cost numeric

update warehouse_operations
set total_cost = transportation_cost + storage_cost


--delay from which warehouse is high
alter table warehouse_operations
add total_time int

update warehouse_operations
set total_time = shipping_time_days + order_processing_time



--problem 1 
--Improving delivery performance - 
--warehouses with highest average delivery time taken - means they are comparitively slow in delivery
select warehouse_id, avg(total_time) as avg_delivery_time 
from warehouse_operations
group by warehouse_id
order by avg_delivery_time desc


--comparing which part is taking more time for the each warehouse - if diff > 0 (+ve) then more processing delay
																	--diff < 0 (-ve) then more shipping delay
select warehouse_id, 
		avg(shipping_time_days) as avg_ship_days, 
		avg(order_processing_time) as avg_process_day, 	
		AVG(Order_Processing_Time) - AVG(Shipping_Time_Days) AS diff
from warehouse_operations
group by warehouse_id

--finding gap between lead time days and actual execution 
		-- if avg_gap > 0 +ve then delay (bad)
		-- 		avg_gap < 0 -ve then faster (good)
select warehouse_id, 
		avg(lead_time_days) as avg_expected_time,
		avg(total_time) as avg_actual_time,
		avg(total_time) - avg(lead_time_days) as avg_gap
from warehouse_operations
group by warehouse_id
order by avg_gap 


--does product category affecting delivery performance - no
select product_category, 
		avg(total_time) as avg_delivery_time
from warehouse_operations
group by product_category
order by avg(total_time) desc

--does it affected by location - almost not
select location, 
		avg(total_time) as avg_delivery_time
from warehouse_operations
group by location
order by avg(total_time) desc


--Problem 2 Inventory Management

--demand vs current stock
select warehouse_id, 
		sum(demand_forecast) as demand,
		sum(current_stock) as supply,
		sum(demand_forecast) - sum(current_stock) as demand_gap
from warehouse_operations
group by warehouse_id
order by demand_gap desc

-- warehouse utilization
select warehouse_id, 
		sum(current_stock) as supply,
		sum(warehouse_capacity) as capacity, 
		100* (sum(current_stock) * 1.0 / sum(warehouse_capacity)) as warehouse_utilization_percent
from warehouse_operations
group by warehouse_id
order by warehouse_utilization_percent desc

--backorder quantity
select warehouse_id, 
		sum(backorder_quantity) as total_backorder_units
from warehouse_operations
group by warehouse_id
order by total_backorder_units desc

-- inventory efficiency
select warehouse_id, 
		sum(monthly_sales) as units_sold,
		sum(current_stock) as stock_present,
		sum(monthly_sales)*1.0 / sum(current_stock) as inventory_turnover
from warehouse_operations
group by warehouse_id
order by inventory_turnover desc

--damaged goods finding rate
SELECT 
    Warehouse_ID,
    100*(SUM(Damaged_Goods)*1.0 / SUM(Current_Stock)) AS damage_rate
FROM warehouse_operations
GROUP BY Warehouse_ID
ORDER BY damage_rate DESC;


--damaged goods by supplier
select supplier_id,
		sum(damaged_goods) as total_damaged_units
from warehouse_operations
group by supplier_id
order by total_damaged_units desc

--damaged goods by product category
select product_category,
		sum(damaged_goods) as total_damaged_units
from warehouse_operations
group by product_category
order by total_damaged_units desc

--problem 3 Demand forecasting
SELECT 
    Warehouse_ID,
    Demand_Forecast,
    Monthly_Sales,
    Demand_Forecast - Monthly_Sales AS forecast_gap
FROM warehouse_operations;

SELECT 
    CASE 
        WHEN Demand_Forecast > Monthly_Sales THEN 'Unmet Demand'
        WHEN Demand_Forecast < Monthly_Sales THEN 'Under-Forecast'
        ELSE 'Accurate'
    END AS Forecast_Status,
    COUNT(*) AS count
FROM warehouse_operations
GROUP BY Forecast_Status;

--forecasting error
SELECT 
    Warehouse_ID,
    Demand_Forecast,
    Monthly_Sales,
    Demand_Forecast - Monthly_Sales AS forecast_error
FROM warehouse_operations;

--biggest unmet demand warehouses
SELECT 
    Warehouse_ID,
    SUM(Demand_Forecast - Monthly_Sales) AS total_error
FROM warehouse_operations
GROUP BY Warehouse_ID
ORDER BY total_error DESC;

--biggest underforecasting problem
SELECT 
    Warehouse_ID,
    SUM(Demand_Forecast - Monthly_Sales) AS total_error
FROM warehouse_operations
GROUP BY Warehouse_ID
ORDER BY total_error ASC;

--system behaviour 
-- it shows -ve value means system is underestimating demand 
SELECT 
    SUM(Demand_Forecast - Monthly_Sales) AS total_error
FROM warehouse_operations;

--accuracy
select warehouse_id, 
		avg(monthly_sales *1.0  / demand_forecast) as avg_accuracy
from warehouse_operations
group by warehouse_id 
order by accuracy desc

SELECT 
    Warehouse_ID,
    AVG(Monthly_Sales * 1.0 / Demand_Forecast) AS avg_accuracy,
    CASE 
        WHEN AVG(Monthly_Sales * 1.0 / Demand_Forecast) < 0.9 THEN 'Underperforming'
        WHEN AVG(Monthly_Sales * 1.0 / Demand_Forecast) < 1 THEN 'Slightly Under'
        WHEN AVG(Monthly_Sales * 1.0 / Demand_Forecast) <= 1.2 THEN 'Accurate'
        WHEN AVG(Monthly_Sales * 1.0 / Demand_Forecast) <= 2 THEN 'Overperforming'
        ELSE 'Highly Overperforming'
    END AS Accuracy_Category
FROM warehouse_operations
GROUP BY Warehouse_ID;

--category wise sales
SELECT 
    Product_Category,
    SUM(Monthly_Sales) AS total_sales,
    AVG(Monthly_Sales) AS avg_sales
FROM warehouse_operations
GROUP BY Product_Category
ORDER BY total_sales DESC;

--location wise sales trend
SELECT 
    Location,
    SUM(Demand_Forecast) AS total_demand,
    SUM(Monthly_Sales) AS total_sales
FROM warehouse_operations
GROUP BY Location
ORDER BY total_demand DESC;


--for future prediction
WITH thresholds AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Demand_Forecast) AS median_demand,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Monthly_Sales) AS median_sales
    FROM warehouse_operations
)

SELECT 
    w.Warehouse_ID,
    SUM(w.Demand_Forecast) AS total_demand,
    SUM(w.Monthly_Sales) AS total_sales,
    
    CASE 
        WHEN SUM(w.Demand_Forecast) > t.median_demand 
             AND SUM(w.Monthly_Sales) > t.median_sales 
        THEN 'Future Demand Zone'
        
        WHEN SUM(w.Demand_Forecast) > t.median_demand 
             AND SUM(w.Monthly_Sales) <= t.median_sales 
        THEN 'Unmet Demand Zone'
        
        WHEN SUM(w.Demand_Forecast) <= t.median_demand 
             AND SUM(w.Monthly_Sales) > t.median_sales 
        THEN 'Under-Forecast Zone'
        
        ELSE 'Low Demand Zone'
        
    END AS Demand_Sales_Category

FROM warehouse_operations w
CROSS JOIN thresholds t
GROUP BY w.Warehouse_ID, t.median_demand, t.median_sales;

--problem 4
--Cost optimization

--1. total cost 
select warehouse_id, 
		sum(total_cost) as total_money_spent, 
		avg(total_cost) as avg_money_spent
from warehouse_operations
group by warehouse_id
order by total_money_spent desc

--2. cost distribution - which cost is dominating for the each warehouse
select warehouse_id,
 		avg(storage_cost) as avg_storage_cost, 
		avg(transportation_cost) as avg_transportation_cost,
		avg(storage_cost) - avg(transportation_cost) as cost_distribution
from warehouse_operations
group by warehouse_id

--3. cost vs monthly sales

--finding thresholds
SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (Storage_Cost + Transportation_Cost)) AS median_cost,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_revenue) AS median_sales
FROM warehouse_operations

--categorizing them with the use of thresholds
WITH thresholds AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (total_cost)) AS median_cost,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_revenue) AS median_sales
    FROM warehouse_operations
)

SELECT 
    w.Warehouse_ID,
    SUM(w.total_Cost) AS total_cost,
    SUM(w.Monthly_revenue) AS total_sales,

    CASE 
        WHEN SUM(w.total_cost) > t.median_cost 
             AND SUM(w.monthly_revenue) <= t.median_sales 
        THEN 'High Cost - Low Sales (Inefficient)'
        
        WHEN SUM(w.total_cost) <= t.median_cost 
             AND SUM(w.Monthly_revenue) > t.median_sales 
        THEN 'Low Cost - High Sales (Efficient)'
        
        WHEN SUM(w.total_cost) > t.median_cost 
        THEN 'High Cost - High Sales'
        
        ELSE 'Low Cost - Low Sales'
        
    END AS Efficiency_Category

FROM warehouse_operations w
CROSS JOIN thresholds t
GROUP BY w.Warehouse_ID, t.median_cost, t.median_sales;

--cost per unit
select warehouse_id, 
		sum(total_cost) as total_cost,
		sum(monthly_sales) as total_monthly_sales,
		sum(total_cost) * 1.0 / sum(monthly_sales) as cost_per_unit
from warehouse_operations
group by warehouse_id
order by cost_per_unit desc


--category level cost
select product_category,
		sum(total_cost) as total_cost,
		sum(monthly_sales) as total_sales,
		sum(total_cost) / sum(monthly_sales) as cost_per_unit
from warehouse_operations
group by product_category
order by cost_per_unit


--location level cost
select location,
		sum(total_cost) as total_cost,
		sum(monthly_revenue) as total_revenue
from warehouse_operations
group by location

--profit and profit margin
SELECT 
    Warehouse_ID,
    SUM(Monthly_Revenue) AS revenue,
    SUM(total_cost) AS cost,
    SUM(Monthly_Revenue) - SUM(total_cost) AS profit
FROM warehouse_operations
GROUP BY Warehouse_ID;

SELECT 
    Warehouse_ID,
    SUM(Monthly_Revenue) AS revenue,
    SUM(total_cost) AS cost,
    100* (SUM(Monthly_Revenue) - SUM(total_cost)) 
        / SUM(Monthly_Revenue) AS profit_margin
FROM warehouse_operations
GROUP BY Warehouse_ID;

select warehouse_id,
		sum(operational_cost) - sum(total_cost) as overhead_cost
from warehouse_operations
group by warehouse_id

alter table warehouse_operations
add overhead_cost decimal

update warehouse_operations
set overhead_cost = operational_cost - total_cost

select * from warehouse_operations


select warehouse_id,
		