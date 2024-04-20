
-- ==================================================================
-- STUFF / PLAYGROUND:

-- select distinct product_category_name from products -- 74 entries
-- select * from order_items -- 112650
-- select * from order_items -- 12650
-- select * from product_category_name_translation -- 74 
-- select distinct product_category_name from products -- 74 entries
-- ====================================================================

-- ===============================================================================
-- 3.1. In relation to the products:
-- ===============================================================================

-- What categories of tech products does Magist have?
-- select * from product_category_name_translation
-- manual selection by name => audio, cds_dvds_musicals, cine_photo, consoles_games, dvds_blu_ray, electronics, computers_accessories, pc_gamer, computers, tablets_printing_image, telephony,  fixed_telephony

-- How many products of these tech categories have been sold (within the time window of the database snapshot)? 
-- Returns 17349 rows: 
/*
select * from order_items as o 
left join products as p 
on o.product_id = p.product_id
left join product_category_name_translation as e
on p.product_category_name = e.product_category_name
where product_category_name_english in ("audio", "cds_dvds_musicals", "cine_photo", "consoles_games", "dvds_blu_ray", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony", "fixed_telephony")
*/

-- ------------------------------------------------------------------------------------

-- What percentage does that represent from the overall number of products sold?
-- => Returns "15,5..." => 17349 / 112650 = 15.4 - TO DO: WHY THE DIFFERENCE??!
/*
WITH filtered_orders AS (
  SELECT DISTINCT order_id
  FROM order_items AS o
  LEFT JOIN products AS p ON o.product_id = p.product_id
  LEFT JOIN product_category_name_translation AS e ON p.product_category_name = e.product_category_name
  WHERE e.product_category_name_english IN ("audio", "cds_dvds_musicals", "cine_photo", "consoles_games", "dvds_blu_ray", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony", "fixed_telephony")
),
total_orders AS (
    SELECT COUNT(DISTINCT order_id) AS num_of_orders
  FROM orders
),
aggregate_data AS (
  SELECT CAST(COUNT(*) OVER () AS float)/(SELECT num_of_orders FROM total_orders) * 100 AS percentage
  FROM filtered_orders
)
SELECT MIN(percentage) AS percentage
FROM aggregate_data;
*/

-- ------------------------------------------------------------------------------------

-- What’s the average price of the products being sold?
-- => Returns 110.05
/*
SELECT AVG(o.price) AS avg_price
FROM order_items AS o
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS e ON p.product_category_name = e.product_category_name
WHERE e.product_category_name_english IN ("audio", "cds_dvds_musicals", "cine_photo", "consoles_games", "dvds_blu_ray", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony", "fixed_telephony");
*/

-- ------------------------------------------------------------------------------------

-- Are expensive tech products popular? * TIP: Look at the function CASE WHEN to accomplish this task.
-- => no, 95% of all ordered product cost less than 300 EURO

-- TODO:
-- 1. get prices to generate X price-categories
-- 2. put prices into price-categories
-- 3. calculate % for each price-category in relation to total tech-sales

/*
WITH products_with_category AS (
    SELECT
        p.*,
        CASE
            WHEN p.price BETWEEN 0 AND 100 THEN '0 - 100 EUR'
            WHEN p.price BETWEEN 100 AND 300 THEN '100 - 300 EUR'
            WHEN p.price BETWEEN 300 AND 800 THEN '300 - 800 EUR'
            WHEN p.price BETWEEN 800 AND 1500 THEN '800 - 1500 EUR'
            WHEN p.price BETWEEN 1500 AND 2500 THEN '1500 - 2500 EUR'
            WHEN p.price BETWEEN 2500 AND 4000 THEN '2500 - 4000 EUR'
            WHEN p.price BETWEEN 4000 AND 6000 THEN '4000 - 6000 EUR'
            WHEN p.price BETWEEN 6000 AND 10000 THEN '6000 - 10000 EUR'
        END AS price_category
    FROM order_items p
)
SELECT
    price_category,
    COUNT(*) AS product_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM products_with_category), 2) AS percentage
FROM products_with_category
GROUP BY price_category
ORDER BY price_category;

/*
'0 - 100 EUR', '72337', '64.21'
'100 - 300 EUR', '33376', '29.63'
'1500 - 2500 EUR', '276', '0.25'
'2500 - 4000 EUR', '49', '0.04'
'300 - 800 EUR', '5585', '4.96'
'4000 - 6000 EUR', '6', '0.01'
'6000 - 10000 EUR', '3', '0.00'
'800 - 1500 EUR', '1018', '0.90'
*/

-- Let's make five categories: cheap (0-100), low-range (100-300), mid-range (300-800), high-range (800-1500), expensive (above 1500)
-- add a column with a number for the price-category for sorting  
/*
WITH products_with_category AS (
    SELECT
        p.*,
        CASE
            WHEN p.price BETWEEN 0 AND 100 THEN 1
            WHEN p.price BETWEEN 100 AND 300 THEN 2
            WHEN p.price BETWEEN 300 AND 800 THEN 3
            WHEN p.price BETWEEN 800 AND 1500 THEN 4
            WHEN p.price >= 1500 THEN 5
        END AS price_category_number,
        CASE
            WHEN p.price BETWEEN 0 AND 100 THEN '0 - 100 EUR'
            WHEN p.price BETWEEN 100 AND 300 THEN '100 - 300 EUR'
            WHEN p.price BETWEEN 300 AND 800 THEN '300 - 800 EUR'
            WHEN p.price BETWEEN 800 AND 1500 THEN '800 - 1500 EUR'
            WHEN p.price >= 1500 THEN '1500 and more EUR'
        END AS price_category
    FROM order_items p
)
SELECT
    price_category_number,
    price_category,
    COUNT(*) AS product_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM products_with_category), 2) AS percentage
FROM products_with_category
GROUP BY price_category_number, price_category
ORDER BY price_category_number;
*/

/*
RESULT:
'1', '0 - 100 EUR', '72337', '64.21'
'2', '100 - 300 EUR', '33376', '29.63'
'3', '300 - 800 EUR', '5585', '4.96'
'4', '800 - 1500 EUR', '1018', '0.90'
'5', '1500 and more EUR', '334', '0.30'
*/

-- ===============================================================================
-- 3.2. In relation to the sellers:
-- ===============================================================================

-- How many months of data are included in the magist database?
-- => 26 Months

-- select * from orders
-- => 9/2016 - 10/2018

/*
SELECT
  TIMESTAMPDIFF(MONTH, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp))  AS full_months
FROM
  orders;
*/

-- How many sellers are there? 
-- => 3095 distinct sellers

-- select * from order_items -- 112650 rows

/*
SELECT COUNT(DISTINCT seller_id) AS seller
FROM order_items;
*/

-- ------------------------------------------------------------------------------------
-- How many Tech sellers are there? 
-- => 499 distict seller, who sell tech-products

-- products = product_category_name => "tech-product"  !!! join with english beforehand
-- 17349 "tech-products"
/*
SELECT COUNT(DISTINCT o.seller_id) AS distinct_sellers
FROM order_items AS o
LEFT JOIN products AS p ON o.product_id = p.product_id
LEFT JOIN product_category_name_translation AS e ON p.product_category_name = e.product_category_name
WHERE e.product_category_name_english IN ("audio", "cds_dvds_musicals", "cine_photo", "consoles_games", "dvds_blu_ray", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony", "fixed_telephony");
*/

-- What percentage of overall sellers are Tech sellers?
-- =>  16,12%     manual calculation 499/3095 = 16,12 %
/*
SELECT 
    round(100.0 * (
        SELECT COUNT(DISTINCT o.seller_id) 
        FROM order_items AS o
        LEFT JOIN products AS p ON o.product_id = p.product_id
        LEFT JOIN product_category_name_translation AS e ON p.product_category_name = e.product_category_name
        WHERE e.product_category_name_english IN ("audio", "cds_dvds_musicals", "cine_photo", "consoles_games", "dvds_blu_ray", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image", "telephony", "fixed_telephony")
    ) / (
        SELECT COUNT(DISTINCT seller_id) 
        FROM order_items
    ), 2) AS tech_product_seller_percentage;
    */

-- ------------------------------------------------------------------------------------
-- What is the total amount earned by all sellers? 
-- => 13.591.644
/*
SELECT SUM(price) AS total_price
FROM order_items;
*/

-- What is the total amount earned by all Tech sellers?

-- ------------------------------------------------------------------------------------
-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

-- ===============================================================================
-- 3.3. In relation to the delivery time:
-- ===============================================================================
-- What’s the average time between the order being placed and the product being delivered?
-- How many orders are delivered on time vs orders delivered with a delay?
-- Is there any pattern for delayed orders, e.g. big products being delayed more often?
