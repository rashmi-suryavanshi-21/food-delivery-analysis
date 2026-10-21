-- setup for the food delivery project (mysql 8)
--
-- before running this I imported the excel sheets into mysql as csv files using
-- the table data import wizard in workbench:
--   january_24, february_24, march_24, april_24  (the monthly orders)
--   `other data-customer details`, `other data-food_details`, `other data-resturant_details`
--
-- the tables below are cleaned up versions of those, which queries.sql uses

CREATE DATABASE IF NOT EXISTS food_delivery;
USE food_delivery;


-- customers
-- member type had "G" and "R" in some rows, so I changed them to Gold and Regular
DROP TABLE IF EXISTS customers;
CREATE TABLE customers AS
SELECT customer_id,
       customer_name,
       CASE member_Type
           WHEN 'G' THEN 'Gold'
           WHEN 'R' THEN 'Regular'
           ELSE member_Type
       END AS member_type
FROM `other data-customer details`;


-- food items
DROP TABLE IF EXISTS food;
CREATE TABLE food AS
SELECT ItemCode AS food_id, `Food Name` AS food_name, Food_Type AS food_type
FROM `other data-food_details`;


-- restaurants
DROP TABLE IF EXISTS restaurants;
CREATE TABLE restaurants AS
SELECT Resturant_Code AS restaurant_id,
       Resturant_Name AS restaurant_name,
       Resturant_type AS restaurant_type
FROM `other data-resturant_details`;


-- orders
-- the four months are in separate tables, so I joined them with UNION ALL
-- (same idea as append queries in power query)
-- the dates came in as text like 1/22/2024 (month/day/year). My first try used
-- day/month/year and it failed on 1/13/2024, so I switched the format
DROP TABLE IF EXISTS orders;
CREATE TABLE orders AS
SELECT order_id, STR_TO_DATE(orderDate, '%m/%d/%Y') AS order_date, customer_id,
       Resturant_ID AS restaurant_id, Fooditem AS food_id, quantity,
       deliver_status AS delivery_status, payment_method
FROM january_24
UNION ALL
SELECT order_id, STR_TO_DATE(orderDate, '%m/%d/%Y'), customer_id, Resturant_ID,
       Fooditem, quantity, deliver_status, payment_method
FROM february_24
UNION ALL
SELECT order_id, STR_TO_DATE(orderDate, '%m/%d/%Y'), customer_id, Resturant_ID,
       Fooditem, quantity, deliver_status, payment_method
FROM march_24
UNION ALL
SELECT order_id, STR_TO_DATE(orderDate, '%m/%d/%Y'), customer_id, Resturant_ID,
       Fooditem, quantity, deliver_status, payment_method
FROM april_24;


-- quick checks, these should match the power bi numbers
SELECT COUNT(*) FROM orders;        -- 2746
SELECT COUNT(*) FROM customers;     -- 30
SELECT COUNT(*) FROM food;          -- 23
SELECT COUNT(*) FROM restaurants;   -- 6

-- gold 20, regular 10
SELECT member_type, COUNT(*) FROM customers GROUP BY member_type;

-- 626, 792, 765, 563
SELECT MONTH(order_date) AS month_no, COUNT(*)
FROM orders
GROUP BY month_no
ORDER BY month_no;

-- should be 0 (no dates failed to convert)
SELECT COUNT(*) FROM orders WHERE order_date IS NULL;