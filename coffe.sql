use coffe;
SELECT 'city' t, COUNT(*) FROM city
select * from coffe.city;
SELECT * FROM coffe.`customers (1)`;
select * from coffe.products;
SELECT * FROM coffe.sales;

-- Q1. Coffee consumers count (25% of the population)
SELECT city_name,
       population,
       ROUND(population * 0.25) AS estimated_coffee_consumers
FROM city
ORDER BY estimated_coffee_consumers DESC;

-- Q2. Total revenue from coffee sales in Q4 2023
SELECT SUM(total) AS total_revenue_q4_2023
FROM sales
WHERE sale_date >= '2023-10-01'
  AND sale_date <  '2024-01-01';

-- per city
SELECT ci.city_name, SUM(s.total) AS total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci     ON c.city_id = ci.city_id
WHERE s.sale_date >= '2023-10-01' AND s.sale_date < '2024-01-01'
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q3. Units sold per product
SELECT p.product_id, p.product_name, COUNT(s.sale_id) AS units_sold
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC;

-- Q4. Average sales amount per customer in each city
SELECT city.city_name,
       SUM(s.total)                        AS total_revenue,
       COUNT(DISTINCT s.customer_id)       AS total_customers,
       ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci     ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q5. Cities with population and estimated coffee consumers
SELECT city_name,
       population,
       ROUND(population * 0.25) AS estimated_coffee_consumers
FROM city
ORDER BY population DESC;

-- Q6. Top 3 selling products in each city (by sales volume)
SELECT *
FROM (
    SELECT ci.city_name,
           p.product_name,
           COUNT(s.sale_id) AS units_sold,
           DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rnk
    FROM sales s
    JOIN products p  ON s.product_id = p.product_id
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci     ON c.city_id = ci.city_id
    GROUP BY ci.city_name, p.product_name
) t
WHERE rnk <= 3
ORDER BY city_name, rnk;

-- Q7. Unique customers per city who purchased coffee

SELECT ci.city_name,
       COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci     ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY unique_customers DESC;

-- Q8. Average sale vs. rent per customer
SELECT ci.city_name,
       ci.estimated_rent,
       COUNT(DISTINCT s.customer_id) AS total_customers,
       ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer,
       ROUND(ci.estimated_rent / COUNT(DISTINCT s.customer_id), 2) AS avg_rent_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci     ON c.city_id = ci.city_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY avg_sale_per_customer DESC;

-- Q9. Monthly sales growth rate
WITH monthly AS (
    SELECT DATE_FORMAT(sale_date, '%Y-%m') AS month,
           SUM(total) AS total_sales
    FROM sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
)
SELECT month,
       total_sales,
       LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
       ROUND((total_sales - LAG(total_sales) OVER (ORDER BY month))
             / LAG(total_sales) OVER (ORDER BY month) * 100, 2) AS growth_pct
FROM monthly
ORDER BY month;

-- Per city:
WITH monthly AS (
    SELECT ci.city_name,
           DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
           SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci     ON c.city_id = ci.city_id
    GROUP BY ci.city_name, DATE_FORMAT(s.sale_date, '%Y-%m')
)
SELECT city_name, month, total_sales,
       LAG(total_sales) OVER (PARTITION BY city_name ORDER BY month) AS prev_month_sales,
       ROUND((total_sales - LAG(total_sales) OVER (PARTITION BY city_name ORDER BY month))
             / LAG(total_sales) OVER (PARTITION BY city_name ORDER BY month) * 100, 2) AS growth_pct
FROM monthly
ORDER BY city_name, month;

-- Q10. Market potential: top 3 cities by sales
SELECT ci.city_name,
       SUM(s.total)                    AS total_sale,
       ci.estimated_rent               AS total_rent,
       COUNT(DISTINCT s.customers_id)   AS total_customers,
       ROUND(ci.population * 0.25)     AS estimated_coffee_consumers
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci     ON c.city_id = ci.city_id
GROUP BY ci.city_name, ci.estimated_rent, ci.population
ORDER BY total_sale DESC
LIMIT 3;

