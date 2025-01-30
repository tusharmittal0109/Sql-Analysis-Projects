CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

ALTER TABLE `walmartsalesdata.csv`
RENAME TO walmart_sales;

CREATE TABLE sales_staging LIKE walmart_sales;
INSERT INTO sales_staging
SELECT * FROM walmart_sales;

WITH ranked AS
(SELECT *,
	DENSE_RANK() OVER(PARTITION BY `Invoice ID`) AS row_num
FROM walmart_sales
)
SELECT * FROM ranked
WHERE row_num > 1;

SELECT * FROM walmart_sales;
SELECT `Time` FROM walmart_sales;
SELECT 
    `Date`, 
    STR_TO_DATE(`Date`, '%Y-%m-%d') AS formatted_date
FROM 
    sales_staging;
SELECT 
    `Time`, 
    STR_T,
    STR_TO_TIME(`Date`, '%Y-%m-%d') AS formatted_date
FROM 
    sales_staging;
    
SELECT 
    `Time`, 
    STR_TO_DATE(`Time`, '%H:%i:%s') AS formatted_time
FROM 
    sales_staging;
    
UPDATE sales_staging
SET `Date` = STR_TO_DATE(`Date`, '%Y-%m-%d');

UPDATE sales_staging
SET `Time` = STR_TO_DATE(`Time`, '%H:%i:%s');

ALTER TABLE sales_staging
MODIFY COLUMN `Date` date;

ALTER TABLE sales_staging
MODIFY COLUMN `Time` time;

SELECT * FROM sales_staging;
SELECT DISTINCT `cogs` FROM sales_staging
ORDER BY 1;

SELECT count(*) FROM (SELECT DISTINCT `Invoice ID` FROM sales_staging) AS diff; -- no duplicates

-- FEATURE ENGINEERING

-- time_of day -  Morning, Afternoon, Evening
SELECT `time` FROM sales_staging
ORDER BY 1;

SELECT `time`,
	CASE
		WHEN `time` BETWEEN "10:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:00:01" AND "15:00:00" THEN "Afternoon"
        WHEN `time` BETWEEN "15:00:01" AND "21:00:00" THEN "Evening"
	END AS time_of_day
FROM sales_staging;

ALTER TABLE sales_staging
ADD COLUMN time_of_day ENUM("Morning", "Afternoon", "Evening");

COMMIT;
UPDATE sales_staging
SET Branch = "A"
WHERE `Invoice ID` = '750-67-8428';

SELECT Branch FROM sales_staging
WHERE `Invoice ID` = '750-67-8428';

rollback;

UPDATE sales_staging
	SET time_of_day =
		CASE
			WHEN `time` BETWEEN "10:00:00" AND "12:00:00" THEN "Morning"
			WHEN `time` BETWEEN "12:00:01" AND "16:00:00" THEN "Afternoon"
			WHEN `time` BETWEEN "16:00:01" AND "21:00:00" THEN "Evening"
		END;
        
UPDATE sales_staging
	SET time_of_day =
		CASE
			WHEN `time` BETWEEN "12:00:01" AND "16:00:00" THEN "Afternoon"
		END;
        
SELECT `date`,
	DAYNAME(`date`)
FROM sales_staging;

SELECT `date`,
	MONTHNAME(`date`)
FROM sales_staging;

SELECT `date`,
	MONTH(`date`)
FROM sales_staging;

SELECT DAYNAME('2003-09-01') AS day_name;

ALTER TABLE sales_staging
ADD COLUMN days VARCHAR(20) NOT NULL;

ALTER TABLE sales_staging
ADD COLUMN months VARCHAR(20) NOT NULL;

UPDATE sales_staging
SET days = DAYNAME(`date`);

UPDATE sales_staging
SET months = MONTHNAME(`date`);

SELECT * FROM sales_staging;

SELECT DISTINCT city FROM sales_staging;
SELECT DISTINCT city, Branch FROM sales_staging;

SELECT count(DISTINCT `Product line`) FROM sales_staging;

SELECT max(`Payment`) FROM sales_staging;
SELECT max(`Product line`) FROM sales_staging;

SELECT Months, SUM(Total) FROM sales_staging
GROUP BY Months;

SELECT Months FROM sales_staging
WHERE cogs = (SELECT max(cogs) FROM sales_staging);

SELECT `Product line` FROM sales_staging
WHERE cogs = (SELECT max(cogs) FROM sales_staging);

SELECT `Product line` FROM
(SELECT `Product line`, SUM(Total) FROM sales_staging
GROUP BY `Product line`
ORDER BY SUM(Total) DESC
LIMIT 1) AS highest_product_line;

SELECT `City` FROM
(SELECT `City`, SUM(Total) FROM sales_staging
GROUP BY `City`
ORDER BY SUM(Total) DESC
LIMIT 1) AS highest_city;

SELECT `Product line` FROM
(SELECT `Product line`, SUM(0.05*COGS) AS VAT FROM sales_staging
GROUP BY `Product line`
ORDER BY VAT DESC
LIMIT 1) AS highest_product_line;

SELECT `Product line`,
	CASE 
		WHEN AVG(Quantity) > (SELECT AVG(Quantity) FROM sales_staging) THEN "Good"
        ELSE "BAD"
	END AS remarks
FROM sales_staging
GROUP BY `Product line`;

SELECT Branch FROM sales_staging
GROUP BY Branch
HAVING SUM(Quantity) > (SELECT AVG(Quantity) FROM sales_staging);

SELECT * from sales_staging;

SELECT
	gender,
    product_line,
    COUNT(gender) AS total_cnt,
    DENSE_RANK() OVER(PARTITION BY gender, product_line ORDER BY total_cnt DESC) as ranking
FROM sales
WHERE ranking = 1;

WITH ranked_sales AS (
    SELECT
        gender,
        product_line,
        COUNT(*) AS total_cnt,
        DENSE_RANK() OVER (PARTITION BY gender ORDER BY COUNT(*) DESC) AS ranking
    FROM sales
    GROUP BY gender, product_line
)
SELECT
    gender,
    product_line,
    total_cnt,
    ranking
FROM ranked_sales
WHERE ranking = 1;


SELECT
    product_line,
	ROUND(AVG(rating), 2) as avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;

SELECT DISTINCT days FROM sales_staging;

SELECT days, time_of_day, sum(total) AS total_sale
FROM sales_staging
GROUP BY days, time_of_day
HAVING days = "Saturday" or days = "Sunday"
ORDER BY days, total_sale DESC;

SELECT city,
AVG(`Tax 5%`) AS tax_pct FROM sales_staging
GROUP BY city
ORDER BY tax_pct DESC
LIMIT 1;

SELECT `Customer type`,
	SUM (0.05 * COGS) AS VAT
FROM sales_staging
GROUP BY `Customer type`
ORDER BY VAT DESC;

SELECT DISTINCT `Customer type` FROM sales_staging;
SELECT DISTINCT payment FROM sales_staging;

SELECT `Customer type`, COUNT(*) AS count_type
FROM sales_staging
GROUP BY `Customer type`
ORDER BY count_type DESC;

SELECT Branch, Gender, COUNT(gender) FROM sales_staging
GROUP BY Branch, Gender
ORDER BY BRANCH;

SELECT 
	time_of_day,
    AVG(rating) AS ratings
FROM sales_staging
GROUP BY time_of_day
ORDER BY ratings DESC;

SELECT 
	time_of_day,
    Branch,
    AVG(rating) AS ratings
FROM sales_staging
GROUP BY time_of_day, Branch
ORDER BY ratings DESC;

SELECT 
	days,
    AVG(rating) AS ratings
FROM sales_staging
GROUP BY days
ORDER BY ratings DESC;