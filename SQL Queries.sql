# Q1
SELECT customer, market 
FROM dim_customer 
WHERE customer = "Atliq Exclusive" AND region = "APAC";

# Q2
WITH fiscal_year_2020 AS (
SELECT COUNT(DISTINCT product_code) as 2020_unique_products
FROM fact_sales_monthly
WHERE fiscal_year = 2020),
fiscal_year_2021 AS (
SELECT COUNT(DISTINCT product_code) as 2021_unique_products
FROM fact_sales_monthly
WHERE fiscal_year = 2021)
SELECT 2020_unique_products, 2021_unique_products,
CONCAT(ROUND(((2021_unique_products-2020_unique_products)/2020_unique_products)*100,2), "%") AS pct_chg
FROM fiscal_year_2020,fiscal_year_2021;

# Q3
SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

# Q4
WITH CTE1 AS (
    SELECT 
        p.segment, 
        COUNT(DISTINCT p.product_code) AS product_count_2020
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2020
    GROUP BY p.segment
),
CTE2 AS (
    SELECT 
        p.segment, 
        COUNT(DISTINCT p.product_code) AS product_count_2021
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY p.segment
)
SELECT 
    CTE1.segment, 
    product_count_2020, 
    product_count_2021, 
    (product_count_2021 - product_count_2020) AS difference
FROM CTE1 
JOIN CTE2
ON CTE1.segment = CTE2.segment 
ORDER BY difference;

# Q5
WITH MAX_COST AS (
SELECT p.product_code,p.product,m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)),
MIN_COST AS (
SELECT p.product_code,p.product,m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
SELECT * FROM MAX_COST
UNION
SELECT * FROM MIN_COST;

# Q6
SELECT c.customer_code, c.customer, CONCAT(ROUND(AVG(p.pre_invoice_discount_pct)*100,2),"%") AS average_discount_pct
FROM fact_pre_invoice_deductions p
JOIN dim_customer c
ON p.customer_code = c.customer_code
WHERE c.market = "India" AND p.fiscal_year = 2021
GROUP BY c.customer, c.customer_code
ORDER BY average_discount_pct
LIMIT 5;

# Q7
SELECT MONTHNAME(s.date) AS month, s.fiscal_year, CONCAT(ROUND(SUM((s.sold_quantity*g.gross_price))/1000000,2)," M") AS gross_sales
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY  MONTHNAME(s.date), s.fiscal_year
ORDER BY fiscal_year;

# Q8
SELECT 
CASE
    WHEN MONTH(date) IN (9,10,11) THEN "Q1"
    WHEN MONTH(date) IN (12,1,2) THEN "Q2"
    WHEN MONTH(date) IN (3,4,5) THEN "Q3"
    WHEN MONTH(date) IN (6,7,8) THEN "Q4"
    END AS quaters,
    CONCAT(ROUND(SUM(sold_quantity)/1000000,2), " M") as total_sold_quantity
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
    GROUP BY quaters 
    ORDER BY total_sold_quantity DESC;
    
# Q9
WITH CTE AS (
    SELECT 
        c.channel, 
        ROUND(SUM(g.gross_price * s.sold_quantity) / 1000000, 2) AS gross_sales_mln,
        SUM(SUM(g.gross_price * s.sold_quantity) / 1000000) OVER () AS total_gross_sales_mln
    FROM 
        fact_sales_monthly s
    JOIN 
        dim_customer c
    ON 
        s.customer_code = c.customer_code 
    JOIN 
        fact_gross_price g
    ON 
        s.product_code = g.product_code
    WHERE 
        s.fiscal_year = 2021
    GROUP BY 
        c.channel
)
SELECT 
    channel, 
    gross_sales_mln, 
    CONCAT(ROUND((gross_sales_mln / total_gross_sales_mln) * 100, 2), "%") AS pct
FROM 
    CTE
ORDER BY 
    gross_sales_mln DESC;

# 10 
WITH CTE AS(
SELECT p.division, s.product_code, p.product, CONCAT(ROUND(SUM(s.sold_quantity)/1000000,2), " M") as total_sold_quantity,
DENSE_RANK() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS  rank_order
FROM dim_product p 
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE fiscal_year = 2021
GROUP BY p.division, s.product_code, p.product)
SELECT * FROM CTE
WHERE rank_order <=3
ORDER BY division, rank_order;

