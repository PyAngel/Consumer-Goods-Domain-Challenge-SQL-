/* Exercise #1*/

SELECT 
	DISTINCT(market)
FROM 
	gdb023.dim_customer
WHERE 
	customer = 'Atliq Exclusive' and region = 'APAC'

/* Exercise #2*/

WITH T1 AS (
    SELECT 
		COUNT(DISTINCT product_code) AS unique_count_2020
    FROM 
		gdb023.fact_sales_monthly
    WHERE 
		fiscal_year = '2020'
  ), 
  T2 AS (
    SELECT 
		COUNT(DISTINCT product_code) AS unique_count_2021
    FROM 
		gdb023.fact_sales_monthly
    WHERE 
		fiscal_year = '2021'
  ), 
  T3 AS (
    SELECT 
		ROUND(((T2.unique_count_2021 - T1.unique_count_2020) / T1.unique_count_2020) * 100,2) AS percentage_chg
    FROM 
		T1, T2
  )
SELECT * FROM T1, T2, T3

/* Exercise #3*/

SELECT 
	segment,
	COUNT(DISTINCT(product_code)) as product_count
FROM
	gdb023.dim_product
GROUP BY
	segment
ORDER BY
	product_count DESC

/* Exercise #4*/

WITH T1 AS (
SELECT 
	DISTINCT(segment)
FROM
	gdb023.dim_product
),
T2 AS (
SELECT 
	gdb023.dim_product.segment,
	COUNT(DISTINCT gdb023.fact_sales_monthly.product_code) AS unique_count_2020
FROM 
	gdb023.fact_sales_monthly LEFT JOIN gdb023.dim_product
ON 
	gdb023.fact_sales_monthly.product_code = gdb023.dim_product.product_code
WHERE 
	gdb023.fact_sales_monthly.fiscal_year = '2020'
GROUP BY 
	gdb023.dim_product.segment
), 
T3 AS (
SELECT 
	gdb023.dim_product.segment,
	COUNT(DISTINCT gdb023.fact_sales_monthly.product_code) AS unique_count_2021
FROM 
	gdb023.fact_sales_monthly LEFT JOIN gdb023.dim_product
ON 
	gdb023.fact_sales_monthly.product_code = gdb023.dim_product.product_code
WHERE 
	gdb023.fact_sales_monthly.fiscal_year = '2021'
GROUP BY 
	gdb023.dim_product.segment
  ), 
T4 AS (
  SELECT 
	T2.segment, 
	T2.unique_count_2020, 
	T3.unique_count_2021,
	((T3.unique_count_2021 - T2.unique_count_2020)) AS 'diference'
FROM
	T2 Left JOIN T3 ON T2.segment = T3.segment)
	
SELECT 
	* 
FROM 
	T4


/* Exercise #5 -----------------------------------------------------------------------------*/

WITH T1 AS (
SELECT 
	product_code,manufacturing_cost
FROM 
	gdb023.fact_manufacturing_cost
WHERE 
	manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)
), T2 AS (
SELECT 
	product_code,manufacturing_cost
FROM 
	gdb023.fact_manufacturing_cost
WHERE 
	manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)
), T3 AS (
SELECT 
	product, product_code
FROM 
	gdb023.dim_product
)
SELECT 
	T1.product_code,T3.product,T1.manufacturing_cost
FROM T1 LEFT JOIN T3 
ON T1.product_code = T3.product_code
UNION 
SELECT 
	T2.product_code,T3.product,T2.manufacturing_cost
FROM 
	T2 LEFT JOIN T3 
ON T2.product_code = T3.product_code

/* Exercise #6 -----------------------------------------------------------------------------*/

WITH T1 AS(
SELECT 
	customer_code, 
	AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM 
	gdb023.fact_pre_invoice_deductions
WHERE 
	fiscal_year = 2021
GROUP BY 
	customer_code
)
SELECT 
	T1.customer_code, 
	gdb023.dim_customer.customer,
    T1.average_discount_percentage
FROM 
	T1 LEFT JOIN gdb023.dim_customer 
	ON T1.customer_code = gdb023.dim_customer.customer_code
WHERE 
	gdb023.dim_customer.sub_zone = 'India'
ORDER BY 
	T1.average_discount_percentage DESC
LIMIT 5

/* Exercise #7 -----------------------------------------------------------------------------*/

SELECT
	DATE_FORMAT(fsm.date, '%m') AS 'Month',
	DATE_FORMAT(fsm.date, '%Y') AS 'Year',
	SUM(fsm.sold_quantity * fg.gross_price) AS 'Total_Gross_sales_Amount'
FROM
	gdb023.fact_sales_monthly fsm
INNER JOIN gdb023.fact_gross_price fg
ON fsm.product_code = fg.product_code AND fsm.fiscal_year = fg.fiscal_year
INNER JOIN (
SELECT 
	customer_code
FROM
	gdb023.dim_customer
WHERE 
	customer = 'Atliq Exclusive'
) cc ON fsm.customer_code = cc.customer_code
GROUP BY 
	Month, Year
ORDER BY
	Total_Gross_sales_Amount desc

/* Exercise #8 -----------------------------------------------------------------------------*/

SELECT
	CASE
		WHEN date >= '2019-09-01' AND date <= '2019-11-01' THEN 'Q1'
		WHEN date >= '2019-12-01' AND date <= '2020-02-01' THEN 'Q2'
		WHEN date >= '2020-03-01' AND date <= '2020-05-01' THEN 'Q3'
		WHEN date >= '2020-06-01' AND date <= '2020-08-01' THEN 'Q4'
	END AS 'Quarter', 
	SUM(sold_quantity) AS total_sold_quantity
FROM
	gdb023.fact_sales_monthly
WHERE 
	fiscal_year = 2020
GROUP BY 
	Quarter
ORDER BY Quarter ASC

/* Exercise #9 -----------------------------------------------------------------------------*/

WITH T1 AS (
	SELECT 
		distinct(dm.channel), 
		SUM(fsm.sold_quantity * fg.gross_price) AS 'Gross_sales_min'
	FROM 
		gdb023.fact_sales_monthly fsm INNER JOIN gdb023.fact_gross_price fg 
	ON fsm.product_code = fg.product_code AND fsm.fiscal_year = fg.fiscal_year 
	INNER JOIN gdb023.dim_customer dm 
	ON fsm.customer_code = dm.customer_code 
	WHERE 
		fsm.fiscal_year = 2021 
	GROUP BY 
		dm.channel
		
)	
,T2 AS (
	SELECT 
		SUM(T1.Gross_sales_min) AS total_sum
	FROM T1
) 
SELECT 
	T1.channel, 
	T1.Gross_sales_min, 
	(T1.Gross_sales_min/T2.total_sum)*100 as percentage
FROM 
	T1,T2
ORDER BY 
	T1.Gross_sales_min desc

/* Exercise #10 -----------------------------------------------------------------------------*/

SELECT 
  sr.division, 
  sr.product_code, 
  dim_product.product, 
  sr.total_sold_quantity, 
  sr.sales_rank AS rank_order
FROM (
  SELECT 
    fp.division, 
    fp.product_code, 
    fp.product,
    SUM(fs.sold_quantity) AS total_sold_quantity, 
    RANK() OVER (PARTITION BY fp.division ORDER BY SUM(fs.sold_quantity) DESC) AS sales_rank
  FROM 
    gdb023.dim_product fp
    INNER JOIN gdb023.fact_sales_monthly fs ON fp.product_code = fs.product_code
  GROUP BY 
    fp.division, 
    fp.product_code,
    fp.product
) AS sr
JOIN gdb023.dim_product ON sr.product_code = dim_product.product_code
WHERE 
	sr.sales_rank <= 3
ORDER BY 
	sr.division, rank_order
