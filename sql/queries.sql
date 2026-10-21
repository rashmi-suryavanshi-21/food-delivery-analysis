-- food delivery analysis, jan to apr 2024
-- same questions I answered in the power bi dashboard, now in sql (mysql 8)
-- run setup.sql first so the tables exist

USE food_delivery;


-- 1. how many orders and how much quantity in total?
-- should be 2746 and 15103
SELECT COUNT(*) AS total_orders, SUM(quantity) AS total_quantity
FROM orders;


-- 2. orders per month
-- 626, 792, 765, 563
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, COUNT(*) AS orders
FROM orders
GROUP BY month
ORDER BY month;


-- 3. cancellation rate for each restaurant
-- karavalli is the highest (9.2%), dakshin the lowest (3.3%)
SELECT r.restaurant_name,
       COUNT(*) AS orders,
       SUM(o.delivery_status = 'Cancelled') AS cancelled,
       ROUND(SUM(o.delivery_status = 'Cancelled') * 100.0 / COUNT(*), 1) AS cancel_pct
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY cancel_pct DESC;


-- 4. what share of the quantity does each food type make up?
-- main course 45.7%, snack 29.7%
SELECT f.food_type,
       SUM(o.quantity) AS qty,
       ROUND(SUM(o.quantity) * 100.0 / (SELECT SUM(quantity) FROM orders), 1) AS pct
FROM orders o
JOIN food f ON o.food_id = f.food_id
GROUP BY f.food_type
ORDER BY qty DESC;


-- 5. top 5 food items by quantity
-- samosa, butter chicken, chole bhature, masala dosa, gulab jamun
SELECT f.food_name, SUM(o.quantity) AS qty
FROM orders o
JOIN food f ON o.food_id = f.food_id
GROUP BY f.food_name
ORDER BY qty DESC
LIMIT 5;


-- 6. how are people paying?
-- upi 62.6%, cod 27.3%, card 10.1%
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM orders
GROUP BY payment_method
ORDER BY orders DESC;


-- 7. the two customers who order the most, and how much of the total they make up
-- customer 25 (468 orders) and customer 4 (422 orders), about 32% together
SELECT customer_id,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM orders
GROUP BY customer_id
ORDER BY orders DESC
LIMIT 2;


-- 8. do gold members cancel more than regular ones?
-- gold 6.4%, regular 4.8%
SELECT c.member_type,
       COUNT(*) AS orders,
       ROUND(SUM(o.delivery_status = 'Cancelled') * 100.0 / COUNT(*), 1) AS cancel_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.member_type;


-- 9. change in orders compared to the month before
-- feb +26.5%, mar -3.4%, apr -26.4%
-- used LAG to get last month's number on the same row
WITH monthly AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, COUNT(*) AS orders
    FROM orders
    GROUP BY month
)
SELECT month,
       orders,
       LAG(orders) OVER (ORDER BY month) AS prev_orders,
       ROUND((orders - LAG(orders) OVER (ORDER BY month)) * 100.0
             / LAG(orders) OVER (ORDER BY month), 1) AS mom_pct
FROM monthly;


-- 10. which restaurants cancel more than the overall average (5.8%)?
-- karavalli (9.2%) and saravana bhavan (6.6%)
SELECT r.restaurant_name,
       ROUND(SUM(o.delivery_status = 'Cancelled') * 100.0 / COUNT(*), 1) AS cancel_pct
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
HAVING cancel_pct > (SELECT SUM(delivery_status = 'Cancelled') * 100.0 / COUNT(*) FROM orders)
ORDER BY cancel_pct DESC;