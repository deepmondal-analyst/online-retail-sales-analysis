


-- ONLINE RETAIL II — SQL DATA ANALYSIS PROJECT
-- Business Objective:
-- Analyse retail sales performance, product performance,
-- customer purchasing behaviour, and monthly revenue trends.




-- SECTION 1: DATA QUALITY ANALYSIS 

-- Q1. Identify Total and Cancelled Invoices

SELECT
    COUNT(DISTINCT invoice) AS total_invoices,
    COUNT(DISTINCT CASE
        WHEN invoice LIKE 'C%' THEN invoice
    END) AS cancelled_invoices
FROM online_retail_ii.retail_db;


-- Q2. Classify Negative-Quantity Transactions

SELECT
    CASE
        WHEN invoice LIKE 'C%' THEN 'Cancelled'
        ELSE 'Regular'
    END AS invoice_type,
    COUNT(*) AS negative_quantity_rows,
    COUNT(DISTINCT invoice) AS affected_invoices
FROM online_retail_ii.retail_db
WHERE quantity < 0
GROUP BY invoice_type;


-- Q3. Identify Missing and Unknown Descriptions
-- Among Non-Cancelled, Zero-Price Negative-Quantity Records

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE
        WHEN description IS NULL THEN 1
        ELSE 0
    END) AS null_descriptions,
    SUM(CASE
        WHEN TRIM(description) = '' THEN 1
        ELSE 0
    END) AS blank_descriptions,
    SUM(CASE
        WHEN LOWER(TRIM(description)) = 'unknown' THEN 1
        ELSE 0
    END) AS unknown_descriptions
FROM online_retail_ii.retail_db
WHERE quantity < 0
AND invoice NOT LIKE 'C%'
AND price = 0;


-- Q4. Count Stock Codes with Inconsistent Product Descriptions

SELECT
    COUNT(*) AS inconsistent_stock_codes
FROM (
    SELECT stock_code
    FROM online_retail_ii.retail_db
    WHERE stock_code NOT IN ('DOT', 'POST')
    GROUP BY stock_code
    HAVING COUNT(DISTINCT description) > 1
) AS variations;



-- SECTION 2: OVERALL SALES PERFORMANCE

-- Q5. Calculate Total Recorded Sales Revenue

SELECT
    ROUND(SUM(linevalue), 2) AS total_recorded_revenue
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%';


-- Q6. Count Non-Cancelled Invoices

SELECT
    COUNT(DISTINCT invoice) AS non_cancelled_invoices
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%';


-- Q7. Calculate Average Order Value (AOV)

SELECT
    ROUND(
        SUM(linevalue) / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%';



-- SECTION 3: PRODUCT PERFORMANCE ANALYSIS

-- Q8. Identify Top 10 Products by Revenue

SELECT
    stock_code,
    description AS product_name,
    ROUND(SUM(linevalue), 2) AS product_revenue
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%'
AND quantity > 0
AND stock_code NOT IN ('DOT', 'POST', 'M')
GROUP BY stock_code, description
ORDER BY product_revenue DESC
LIMIT 10;


-- Q9. Identify Top 10 Products by Quantity Sold

SELECT
    stock_code,
    description AS product_name,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(linevalue), 2) AS net_sales
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%'
AND quantity > 0
AND stock_code NOT IN ('DOT', 'POST', 'M')
GROUP BY stock_code, description
ORDER BY total_quantity DESC
LIMIT 10;


-- Q10. Compare Product Sales Volume Against Revenue
-- Use the results of Q8 and Q9 to compare product volume
-- and revenue. No separate query is required.


-- Q11. Calculate Product Contribution to Total Revenue

SELECT
    stock_code,
    description,
    ROUND(SUM(linevalue), 2) AS product_revenue,
    ROUND(
        SUM(linevalue) /
        (
            SELECT SUM(linevalue)
            FROM online_retail_ii.retail_db
            WHERE invoice NOT LIKE 'C%'
        ) * 100,
        2
    ) AS revenue_contribution_pct
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%'
GROUP BY stock_code, description
ORDER BY product_revenue DESC
LIMIT 10;




-- SECTION 4: CUSTOMER ANALYSIS


-- Q12. Count Unique Identifiable Customers

SELECT
    COUNT(DISTINCT customer_id) AS unique_customers
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%'
AND customer_id IS NOT NULL
AND TRIM(CAST(customer_id AS CHAR)) <> '';


-- Q13. Identify Top 10 Customers by Spending

SELECT
    customer_id,
    ROUND(SUM(linevalue), 2) AS total_spending
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%'
AND customer_id IS NOT NULL
AND TRIM(CAST(customer_id AS CHAR)) <> ''
GROUP BY customer_id
ORDER BY total_spending DESC
LIMIT 10;


-- Q14. Calculate Number of Repeat Customers

SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS invoice_count
    FROM online_retail_ii.retail_db
    WHERE invoice NOT LIKE 'C%'
    AND customer_id IS NOT NULL
    AND TRIM(CAST(customer_id AS CHAR)) <> ''
    GROUP BY customer_id
    HAVING invoice_count > 1
) AS repeat_customer_list;




-- SECTION 5: MONTHLY SALES TREND ANALYSIS


-- Q15. Analyse Monthly Revenue Trends

SELECT
    DATE_FORMAT(invoice_date, '%Y-%m') AS sales_month,
    ROUND(SUM(linevalue), 2) AS monthly_revenue
FROM online_retail_ii.retail_db
WHERE invoice NOT LIKE 'C%'
GROUP BY sales_month
ORDER BY sales_month;




-- SECTION 6: EXPLORATORY DATA INVESTIGATION
-- Supporting queries used during data exploration


-- E1. Investigate Products with the Most Negative-Quantity Rows
-- in Non-Cancelled Invoices

SELECT
    stock_code,
    description,
    COUNT(*) AS negative_rows,
    SUM(quantity) AS total_negative_qty
FROM online_retail_ii.retail_db
WHERE quantity < 0
AND invoice NOT LIKE 'C%'
GROUP BY stock_code, description
ORDER BY negative_rows DESC
LIMIT 10;


-- E2. Inspect Stock Code 20852

SELECT
    stock_code,
    description,
    quantity,
    price,
    linevalue,
    customer_id,
    invoice
FROM online_retail_ii.retail_db
WHERE stock_code = '20852';


-- E3. Investigate Zero-Price and Missing-Customer
-- Negative-Quantity Records

SELECT
    stock_code,
    description,
    COUNT(*) AS total_rows,
    SUM(quantity) AS total_quantity,
    SUM(linevalue) AS total_value
FROM online_retail_ii.retail_db
WHERE quantity < 0
AND (price = 0 OR customer_id IS NULL)
GROUP BY stock_code, description
ORDER BY ABS(SUM(quantity)) DESC;


-- E4. Analyse Zero-Price Transactions

SELECT
    COUNT(*) AS zero_price_rows,
    SUM(CASE
        WHEN quantity < 0 THEN 1
        ELSE 0
    END) AS negative_quantity_rows,
    SUM(CASE
        WHEN quantity < 0 THEN quantity
        ELSE 0
    END) AS total_negative_quantity,
    SUM(linevalue) AS total_line_value
FROM online_retail_ii.retail_db
WHERE price = 0;


-- E5. Compare Zero-Price and Positive-Price
-- Negative-Quantity Transactions

SELECT
    COUNT(*) AS negative_rows,
    SUM(CASE
        WHEN price = 0 THEN 1
        ELSE 0
    END) AS zero_price_rows,
    SUM(CASE
        WHEN price > 0 THEN 1
        ELSE 0
    END) AS positive_price_rows
FROM online_retail_ii.retail_db
WHERE quantity < 0
AND invoice NOT LIKE 'C%';


-- E6. Examine Descriptions of Zero-Price
-- Negative-Quantity Transactions

SELECT
    description,
    COUNT(*) AS total_rows,
    SUM(quantity) AS total_quantity
FROM online_retail_ii.retail_db
WHERE quantity < 0
AND invoice NOT LIKE 'C%'
AND price = 0
GROUP BY description
ORDER BY total_rows DESC
LIMIT 15;


-- E7. Identify Stock Codes with the Highest
-- Description Variations

SELECT
    stock_code,
    COUNT(DISTINCT description) AS description_variations
FROM online_retail_ii.retail_db
WHERE stock_code NOT IN ('DOT', 'POST')
GROUP BY stock_code
HAVING COUNT(DISTINCT description) > 1
ORDER BY description_variations DESC
LIMIT 10;


-- E8. Inspect Description Variations for Stock Code 20713

SELECT
    description,
    COUNT(*) AS occurrence_count
FROM online_retail_ii.retail_db
WHERE stock_code = '20713'
GROUP BY description
ORDER BY occurrence_count DESC;



-- END OF PROJECT

