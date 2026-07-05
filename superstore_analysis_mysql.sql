-- =============================================================================
-- SUPERSTORE SALES ANALYSIS
-- Subqueries, Correlated Subqueries, CTEs, Window Functions, JOINs,
-- Submitted by- Umna Areeb
-- =============================================================================


-- =============================================================================
-- PART 1 -- DATABASE SETUP
-- =============================================================================

CREATE DATABASE IF NOT EXISTS superstore_db;
USE superstore_db;

-- 1.1  Staging table -- mirrors the raw CSV
DROP TABLE IF EXISTS superstore_raw;
CREATE TABLE superstore_raw (
    row_id        INT             NOT NULL,
    order_id      VARCHAR(20)     NOT NULL,
    order_date    DATE            NOT NULL,
    ship_date     DATE            NOT NULL,
    ship_mode     VARCHAR(20)     NOT NULL,
    customer_id   VARCHAR(20)     NOT NULL,
    customer_name VARCHAR(100)    NOT NULL,
    segment       VARCHAR(20)     NOT NULL,
    country       VARCHAR(50)     NOT NULL,
    city          VARCHAR(50)     NOT NULL,
    state         VARCHAR(50)     NOT NULL,
    postal_code   VARCHAR(10)     NOT NULL,
    region        VARCHAR(20)     NOT NULL,
    product_id    VARCHAR(20)     NOT NULL,
    category      VARCHAR(30)     NOT NULL,
    sub_category  VARCHAR(30)     NOT NULL,
    product_name  VARCHAR(150)    NOT NULL,
    sales         DECIMAL(12, 2)  NOT NULL,
    quantity      INT             NOT NULL,
    discount      DECIMAL(4, 2)   NOT NULL,
    profit        DECIMAL(12, 2)  NOT NULL,
    PRIMARY KEY (row_id)
) ENGINE = InnoDB;

-- 1.2  customers -- one row per unique customer

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id   VARCHAR(20)   NOT NULL PRIMARY KEY,
    customer_name VARCHAR(100)  NOT NULL,
    segment       VARCHAR(20)   NOT NULL,
    country       VARCHAR(50)   NOT NULL
) ENGINE = InnoDB;

INSERT INTO customers (customer_id, customer_name, segment, country)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment,
    country
FROM superstore_raw;


-- 1.3  products -- one row per unique product

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id    VARCHAR(20)   NOT NULL PRIMARY KEY,
    category      VARCHAR(30)   NOT NULL,
    sub_category  VARCHAR(30)   NOT NULL,
    product_name  VARCHAR(150)  NOT NULL
) ENGINE = InnoDB;

INSERT INTO products (product_id, category, sub_category, product_name)
SELECT
    product_id,
    category,
    sub_category,
    MAX(product_name)
FROM superstore_raw
GROUP BY product_id, category, sub_category;


-- 1.4  orders -- one row per order line (fact table)
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    row_id       INT             NOT NULL PRIMARY KEY,
    order_id     VARCHAR(20)     NOT NULL,
    customer_id  VARCHAR(20)     NOT NULL,
    product_id   VARCHAR(20)     NOT NULL,
    order_date   DATE            NOT NULL,
    ship_date    DATE            NOT NULL,
    ship_mode    VARCHAR(20)     NOT NULL,
    city         VARCHAR(50)     NOT NULL,
    state        VARCHAR(50)     NOT NULL,
    postal_code  VARCHAR(10)     NOT NULL,
    region       VARCHAR(20)     NOT NULL,
    sales        DECIMAL(12, 2)  NOT NULL,
    quantity     INT             NOT NULL,
    discount     DECIMAL(4, 2)   NOT NULL,
    profit       DECIMAL(12, 2)  NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_product  FOREIGN KEY (product_id)  REFERENCES products (product_id)
) ENGINE = InnoDB;

INSERT INTO orders (row_id, order_id, customer_id, product_id, order_date, ship_date, ship_mode, city, state, postal_code, region, sales, quantity, discount, profit)
SELECT DISTINCT
    row_id,
    order_id,
    customer_id,
    product_id,
    order_date,
    ship_date,
    ship_mode,
    city,
    state,
    postal_code,
    region,
    sales,
    quantity,
    discount,
    profit
FROM superstore_raw;

CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_product  ON orders (product_id);
CREATE INDEX idx_orders_date     ON orders (order_date);
CREATE INDEX idx_orders_region   ON orders (region);


-- =============================================================================
-- PART 2 -- SQL QUERIES
-- =============================================================================

-- 2.1  Orders where Sales is above average   [SUBQUERY]
SELECT
    o.order_id      AS order_id,
    c.customer_name AS customer_name,
    o.product_id    AS product_id,
    o.sales         AS sales
FROM orders AS o
INNER JOIN customers AS c
    ON c.customer_id = o.customer_id
WHERE o.sales > (
    SELECT AVG(sales) FROM orders
)
ORDER BY o.sales DESC;


-- 2.2  Highest sales order for each customer   [CORRELATED SUBQUERY]
SELECT
    c.customer_name AS customer_name,
    o.order_id      AS order_id,
    o.product_id    AS product_id,
    o.sales         AS sales
FROM orders AS o
INNER JOIN customers AS c
    ON c.customer_id = o.customer_id
WHERE o.sales = (
    SELECT MAX(o2.sales)
    FROM orders AS o2
    WHERE o2.customer_id = o.customer_id
)
ORDER BY o.sales DESC;


-- 2.3  Total sales for each customer   [CTE]
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name          AS customer_name,
    ROUND(ct.total_sales, 2) AS total_sales
FROM customer_totals AS ct
INNER JOIN customers AS c
    ON c.customer_id = ct.customer_id
ORDER BY ct.total_sales DESC;


-- 2.4  Customers whose total sales are above average   [CTE + SUBQUERY]
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name          AS customer_name,
    ROUND(ct.total_sales, 2) AS total_sales
FROM customer_totals AS ct
INNER JOIN customers AS c
    ON c.customer_id = ct.customer_id
WHERE ct.total_sales > (
    SELECT AVG(total_sales) FROM customer_totals
)
ORDER BY ct.total_sales DESC;


-- 2.5  Rank customers based on total sales   [RANK / DENSE_RANK]
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name                                            AS customer_name,
    ROUND(ct.total_sales, 2)                                    AS total_sales,
    RANK()       OVER (ORDER BY ct.total_sales DESC)            AS sales_rank,
    DENSE_RANK() OVER (ORDER BY ct.total_sales DESC)            AS sales_dense_rank
FROM customer_totals AS ct
INNER JOIN customers AS c
    ON c.customer_id = ct.customer_id
ORDER BY sales_rank;


-- 2.6  Row number for each order within every customer   [ROW_NUMBER + PARTITION BY]
SELECT
    c.customer_name AS customer_name,
    o.order_id      AS order_id,
    o.order_date    AS order_date,
    o.sales         AS sales,
    ROW_NUMBER() OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date, o.row_id
    ) AS order_seq
FROM orders AS o
INNER JOIN customers AS c
    ON c.customer_id = o.customer_id
ORDER BY c.customer_name, order_seq;


-- 2.7  Top 3 customers based on total sales   [WINDOW FUNCTION]
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        c.customer_name           AS customer_name,
        ROUND(ct.total_sales, 2)  AS total_sales,
        RANK() OVER (ORDER BY ct.total_sales DESC) AS sales_rank
    FROM customer_totals AS ct
    INNER JOIN customers AS c
        ON c.customer_id = ct.customer_id
)
SELECT *
FROM ranked_customers
WHERE sales_rank <= 3
ORDER BY sales_rank;


-- =============================================================================
-- PART 3 -- FINAL QUERY  (JOIN + CTE + WINDOW FUNCTION)
-- =============================================================================
WITH customer_sales AS (
    SELECT
        c.customer_id                AS customer_id,
        c.customer_name              AS customer_name,
        SUM(o.sales)                 AS total_sales
    FROM customers AS c
    INNER JOIN orders AS o
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name             AS `Customer Name`,
    ROUND(total_sales, 2)     AS `Total Sales`,
    RANK() OVER (ORDER BY total_sales DESC) AS `Customer Rank`
FROM customer_sales
ORDER BY `Customer Rank`;


-- =============================================================================
-- PART 4 -- MINI PROJECT: CUSTOMER SALES INSIGHTS
-- =============================================================================

-- 4.1  Top 5 customers
WITH customer_sales AS (
    SELECT c.customer_id, c.customer_name, SUM(o.sales) AS total_sales
    FROM customers AS c
    INNER JOIN orders AS o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name             AS customer_name,
    ROUND(total_sales, 2)     AS total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM customer_sales
ORDER BY total_sales DESC
LIMIT 5;

-- 4.2  Bottom 5 customers
WITH customer_sales AS (
    SELECT c.customer_id, c.customer_name, SUM(o.sales) AS total_sales
    FROM customers AS c
    INNER JOIN orders AS o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name             AS customer_name,
    ROUND(total_sales, 2)     AS total_sales,
    RANK() OVER (ORDER BY total_sales ASC) AS rank_from_bottom
FROM customer_sales
ORDER BY total_sales ASC
LIMIT 5;

-- 4.3  Customers who made only ONE order
SELECT
    c.customer_name                    AS customer_name,
    COUNT(DISTINCT o.order_id)         AS order_count
FROM customers AS c
INNER JOIN orders AS o
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) = 1
ORDER BY c.customer_name;

-- 4.4  Customers with above-average sales
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name           AS customer_name,
    ROUND(ct.total_sales, 2)  AS total_sales
FROM customer_totals AS ct
INNER JOIN customers AS c
    ON c.customer_id = ct.customer_id
WHERE ct.total_sales > (SELECT AVG(total_sales) FROM customer_totals)
ORDER BY ct.total_sales DESC;

-- 4.5  Highest ORDER value for each customer (order-level, not line-level)
WITH order_totals AS (
    SELECT customer_id, order_id, SUM(sales) AS order_value
    FROM orders
    GROUP BY customer_id, order_id
)
SELECT
    c.customer_name                AS customer_name,
    ot.order_id                    AS order_id,
    ROUND(ot.order_value, 2)       AS highest_order_value
FROM order_totals AS ot
INNER JOIN customers AS c
    ON c.customer_id = ot.customer_id
WHERE ot.order_value = (
    SELECT MAX(ot2.order_value)
    FROM order_totals AS ot2
    WHERE ot2.customer_id = ot.customer_id
)
ORDER BY highest_order_value DESC;


-- =============================================================================
-- PART 9 -- BONUS ANALYSIS: 10 ADVANCED BUSINESS QUESTIONS
-- =============================================================================

-- 9.1  Monthly sales trend   [DATE FUNCTIONS + AGGREGATION]
SELECT
    DATE_FORMAT(order_date, '%Y-%m')  AS sales_month,
    ROUND(SUM(sales), 2)              AS monthly_sales,
    COUNT(DISTINCT order_id)          AS order_count
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;

-- 9.2  Month-over-month sales growth %   [LAG]
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
        SUM(sales)                       AS total_sales
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    sales_month,
    ROUND(total_sales, 2)                                  AS total_sales,
    ROUND(LAG(total_sales) OVER (ORDER BY sales_month), 2) AS prev_month_sales,
    ROUND(
        100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY sales_month))
        / LAG(total_sales) OVER (ORDER BY sales_month), 2
    ) AS mom_growth_pct
FROM monthly_sales
ORDER BY sales_month;

-- 9.3  Segment-wise total sales and rank
SELECT
    c.segment                                   AS segment,
    ROUND(SUM(o.sales), 2)                      AS segment_sales,
    RANK() OVER (ORDER BY SUM(o.sales) DESC)    AS segment_rank
FROM customers AS c
INNER JOIN orders AS o
    ON o.customer_id = c.customer_id
GROUP BY c.segment;

-- 9.4  Each category's % contribution to total sales
SELECT
    p.category                                                          AS category,
    ROUND(SUM(o.sales), 2)                                              AS category_sales,
    ROUND(100.0 * SUM(o.sales) / (SELECT SUM(sales) FROM orders), 2)    AS pct_of_total_sales
FROM products AS p
INNER JOIN orders AS o
    ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY category_sales DESC;

-- 9.5  Classify each order line into High / Medium / Low value   [CASE]
SELECT
    order_id,
    sales,
    CASE
        WHEN sales >= 1000 THEN 'High Value'
        WHEN sales >= 300  THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment
FROM orders
ORDER BY sales DESC;

-- 9.6  Running (cumulative) sales total per customer over time
SELECT
    c.customer_name AS customer_name,
    o.order_date    AS order_date,
    o.sales         AS sales,
    ROUND(
        SUM(o.sales) OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date, o.row_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2
    ) AS running_total_sales
FROM orders AS o
INNER JOIN customers AS c
    ON c.customer_id = o.customer_id
ORDER BY c.customer_name, o.order_date;

-- 9.7  First-half vs second-half sales per customer (flags declining customers)
WITH bounds AS (
    SELECT MIN(order_date) AS min_d, MAX(order_date) AS max_d FROM orders
),
half_sales AS (
    SELECT
        o.customer_id,
        SUM(CASE WHEN o.order_date <  DATE_ADD(b.min_d, INTERVAL DATEDIFF(b.max_d, b.min_d)/2 DAY)
                 THEN o.sales ELSE 0 END) AS first_half_sales,
        SUM(CASE WHEN o.order_date >= DATE_ADD(b.min_d, INTERVAL DATEDIFF(b.max_d, b.min_d)/2 DAY)
                 THEN o.sales ELSE 0 END) AS second_half_sales
    FROM orders AS o
    CROSS JOIN bounds AS b
    GROUP BY o.customer_id
)
SELECT
    c.customer_name                          AS customer_name,
    ROUND(hs.first_half_sales, 2)            AS first_half_sales,
    ROUND(hs.second_half_sales, 2)           AS second_half_sales,
    CASE
        WHEN hs.second_half_sales < hs.first_half_sales THEN 'Declining'
        WHEN hs.second_half_sales > hs.first_half_sales THEN 'Growing'
        ELSE 'Flat'
    END AS trend
FROM half_sales AS hs
INNER JOIN customers AS c ON c.customer_id = hs.customer_id
ORDER BY (hs.second_half_sales - hs.first_half_sales) ASC;

-- 9.8  Best-selling product per category
WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(o.sales) AS product_sales
    FROM products AS p
    INNER JOIN orders AS o ON o.product_id = p.product_id
    GROUP BY p.category, p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_name,
        ROUND(product_sales, 2) AS product_sales,
        RANK() OVER (PARTITION BY category ORDER BY product_sales DESC) AS rank_in_category
    FROM product_sales
)
SELECT * FROM ranked_products WHERE rank_in_category = 1;

-- 9.9  Average discount by region, ranked
SELECT
    o.region                                            AS region,
    ROUND(AVG(o.discount), 3)                           AS avg_discount,
    RANK() OVER (ORDER BY AVG(o.discount) DESC)         AS discount_rank
FROM orders AS o
GROUP BY o.region;

-- 9.10  Customer tenure -- days between first and last order
SELECT
    c.customer_name                              AS customer_name,
    MIN(o.order_date)                            AS first_order_date,
    MAX(o.order_date)                            AS last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS tenure_days,
    COUNT(DISTINCT o.order_id)                   AS total_orders
FROM customers AS c
INNER JOIN orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY tenure_days DESC;
