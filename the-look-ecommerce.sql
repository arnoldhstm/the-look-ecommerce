# Case #1
# To track the result of new campaign expenses in the marketing department, Sheila also wants to know the growth trend of **unique** new users in the past 3 months.
SELECT
  DATE_TRUNC(created_at, MONTH) month
  , COUNT(DISTINCT id) total_users
FROM `sql-project-376612.thelook_ecommerce.users`
GROUP BY 1
ORDER BY 1 DESC
LIMIT 3;

# Case #2
# Considering **completed orders** and focusing on the **month of shipment,** which month in the year 2021 had the **lowest total order performance for the Jeans category?**
WITH T1 AS (
  SELECT
    id
    , order_id
    , product_id
    , status
    , shipped_at
  FROM `sql-project-376612.thelook_ecommerce.order_items`
)
, T2 AS (
  SELECT
    id
    , category
  FROM `sql-project-376612.thelook_ecommerce.products`
    WHERE category = 'Jeans'
)
SELECT
  DATE_TRUNC(T1.shipped_at, MONTH) as months
  , COUNT(T1.id) as total_orders
FROM T1
JOIN T2
  ON T1.product_id = T2.id
WHERE 
  T1.status = 'Complete'
  AND EXTRACT(YEAR FROM T1.shipped_at) IN (2021)
  AND T2.category = 'Jeans'
GROUP BY 1
ORDER BY 2 ASC;

# Case #3
# Considering the **completed orders** that were **shipped** in the year **2022**, which distribution center to **which country destination** had the **highest total number of items sold?**
WITH dbcenters AS (
  SELECT
    id
    , name
  FROM `sql-project-376612.thelook_ecommerce.distribution_centers`
  )
, inventory AS (
  SELECT 
    id
    , product_distribution_center_id
  FROM `sql-project-376612.thelook_ecommerce.inventory_items`
  )
, users AS (
  SELECT 
  id
  , country
  FROM `sql-project-376612.thelook_ecommerce.users`
  )
, orders_items AS (
  SELECT
    order1.order_id
    , order1.user_id
    , order1.status
    , order1.shipped_at
    , order1.inventory_item_id
    , order2.num_of_item
  FROM `sql-project-376612.thelook_ecommerce.order_items` order1
  JOIN `sql-project-376612.thelook_ecommerce.orders` order2
    ON order1.order_id = order2.order_id
  )
SELECT
  users.country
  , dbcenters.name
  , CONCAT(dbcenters.name, ' to ', users.country) as route
  , COUNT(orders_items.order_id) AS total_orders
FROM orders_items
  JOIN users
    ON orders_items.user_id = users.id
  JOIN inventory
    ON orders_items.inventory_item_id = inventory.id
  JOIN dbcenters
    ON inventory.product_distribution_center_id = dbcenters.id
WHERE
  status = 'Complete'
  AND EXTRACT(YEAR FROM orders_items.shipped_at) IN (2022)
GROUP BY 1,2,3
ORDER BY 4 DESC;

# Case #4
# Can you identify the top 1 combination of age group, gender, and country that contributed the **highest number of buyers in 2021?** How much percentage contribute to all buyers?
WITH users AS (
  SELECT 
    id
    , gender
    , country
    , CASE
      WHEN age<18 THEN '-17'
      WHEN age<25 THEN '18 to 24'
      WHEN age<35 THEN '25 to 34'
      WHEN age<55 THEN '35 to 54'
    ELSE '55+'
  END AS age_group
  FROM `sql-project-376612.thelook_ecommerce.users`
  )
, orders_items AS (
  SELECT
    order_id
    , user_id
    , status
    , delivered_at
  FROM `sql-project-376612.thelook_ecommerce.order_items`
  ORDER BY 1,2,3,4
  )
, t3 AS (
  SELECT
    users.country AS country
    , users.age_group AS age_group
    , users.gender AS gender
    , COUNT(DISTINCT orders_items.order_id) AS total_orders
  FROM orders_items
    JOIN users
      ON orders_items.user_id = users.id
  WHERE
    status = 'Complete'
    AND EXTRACT(YEAR FROM orders_items.delivered_at) IN (2021)
  GROUP BY 1,2,3
  )
SELECT
  t3.country
  , t3.age_group
  , t3.gender
  , t3.total_orders / SUM(t3.total_orders) OVER() * 100
FROM t3
ORDER BY 4 DESC;

# Case #5
# Create **monthly retention cohorts** (the groups, or cohorts, can be defined based upon the date that a user completely purchased a product) and then **how many of them (%) coming back for the following month in months in 2022.**

WITH u AS (
  SELECT
    id
    , EXTRACT(MONTH FROM created_at) user_month
  FROM `sql-project-376612.thelook_ecommerce.users`
  WHERE EXTRACT(YEAR FROM created_at) = 2022
    AND status = 'Complete'
)
, o AS (
  SELECT
    order_id
    , user_id
    , EXTRACT(MONTH FROM created_at) order_month
  FROM `sql-project-376612.thelook_ecommerce.orders`
  WHERE EXTRACT(YEAR FROM created_at) = 2022
    AND status = 'Complete'
)
, user AS (
    SELECT 
    u.user_month
    , SUM(COUNT(DISTINCT u.id)) OVER(PARTITION BY u.user_month) total_users
  FROM u
  GROUP BY 1
)
SELECT
  user.total_users
  , u.user_month
  , o.order_month
  , COUNT(DISTINCT o.order_id) total_orders
FROM o
  JOIN u
    ON o.user_id = u.id
  JOIN user
    ON user.user_month = u.user_month
GROUP BY 1,2,3;
