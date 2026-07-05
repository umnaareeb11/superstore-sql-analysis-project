# Superstore Sales Analysis — SQL Advanced Analytics Report

## Project Title
Superstore Sales Analysis Using Subqueries, CTEs, and Window Functions

## Objective
The goal of this project was to use subqueries, correlated subqueries, CTEs, window
functions, joins, and aggregations to analyze customer purchasing behavior in the
Superstore dataset and answer a set of business questions, like which customers rank
highest, who spends above average, which customers only ordered once, and which orders
were the biggest.

## Dataset Description
The dataset used is the Kaggle "Superstore Dataset Final"
(`vivek468/superstore-dataset-final`). Each row in the raw file represents one order
line, meaning one product within one order. The columns include Row ID, Order ID, Order
Date, Ship Date, Ship Mode, Customer ID, Customer Name, Segment, Country, City, State,
Postal Code, Region, Product ID, Category, Sub-Category, Product Name, Sales, Quantity,
Discount, and Profit.

In total there are 9,994 order-line rows, 793 unique customers, 1,862 unique products,
and 5,009 distinct orders, covering dates from January 2014 to December 2017. Total
sales across the whole dataset come out to $2,297,200.86.

Before building the database, a few things in the raw file needed to be fixed:
- The file is encoded in Windows-1252/Latin-1 rather than UTF-8, so a few customer
  names with accented characters (like "Roy Französisch") would show up garbled if
  this wasn't handled.
- Dates were stored as text in US format (M/D/YYYY) and had to be converted to a
  proper ISO date format.
- 438 postal codes in New England states had lost their leading zero somewhere along
  the way (for example Fairfield, CT showed up as 6824 instead of 06824), so these
  were padded back to 5 digits.

While setting up the tables, two data quality issues came up that affected how the
schema was designed:
- Almost all customers (780 out of 793, or 98%) shipped orders to more than one city.
  This means city, state, postal code, and region can't really be treated as fixed
  attributes of a customer — they change depending on the order. Because of this,
  these fields were kept on the orders table instead of the customers table.
- 32 product IDs are listed under two different product names in the source data (for
  example FUR-BO-10002213 shows up as both "DMI Eclipse Executive Suite Bookcases" and
  "Sauder Forest Hills Library, Woodland Oak Finish"). The category and sub-category
  stay the same for these, so only the name is inconsistent. One name was picked for
  each product ID so the products table could have a working primary key.

## Database Schema

| Table | Grain | Key Columns |
|---|---|---|
| `superstore_raw` | one row per order line (raw staging) | all 21 source columns |
| `customers` | one row per customer | `customer_id` (PK), `customer_name`, `segment`, `country` |
| `products` | one row per product | `product_id` (PK), `category`, `sub_category`, `product_name` |
| `orders` | one row per order line (fact table) | `row_id` (PK), `order_id`, `customer_id` (FK), `product_id` (FK), dates, ship-to city/state/postal_code/region, sales, quantity, discount, profit |

The `customers` and `products` tables are filled using `INSERT ... SELECT DISTINCT`
from the raw table. As mentioned above, ship-to address fields stayed on the orders
table rather than customers, since a single customer can have more than one shipping
address across their orders.

## Approach
1. Load the raw data into `superstore_raw` after fixing the encoding, date, and
   postal code issues.
2. Check for data quality problems before normalizing the tables — this is how the two
   issues above were found, instead of running into primary key errors later.
3. Split the raw data into `customers`, `orders`, and `products` tables, connecting
   them with foreign keys.
4. Use subqueries to answer questions like which order lines are above the average
   sales value, or find each customer's highest sale.
5. Use a CTE to calculate total sales per customer once, then reuse that result in
   several other queries instead of repeating the same aggregation.
6. Use window functions (RANK, DENSE_RANK, ROW_NUMBER, LAG, running SUM) to rank
   customers, number their orders, and look at trends over time without losing any
   rows.
7. Combine joins, a CTE, and a window function in one query to build a customer
   leaderboard showing name, total sales, and rank — this feeds into the mini-project
   questions.
8. Use CASE statements and date functions in the bonus section for segmentation and
   time-based analysis.

## SQL Concepts Used

**Subqueries** — A simple subquery (`SELECT AVG(sales) FROM orders`) is used to
compare each order line against the overall average sales figure.

**Correlated Subqueries** — These reference the customer_id from the outer query
(`WHERE o2.customer_id = o.customer_id`) to find each customer's highest sale, both at
the individual order-line level and at the order level.

**CTEs** — A `WITH customer_totals AS (...)` block calculates total sales per customer
once and gets reused across six different queries later on.

**Window Functions** — RANK() and DENSE_RANK() are used for the customer leaderboard,
ROW_NUMBER() with PARTITION BY for numbering each customer's orders in sequence, LAG()
for comparing month over month, and a running SUM() OVER for cumulative totals.

**Aggregations** — SUM, AVG, COUNT(DISTINCT ...), MIN and MAX show up throughout most
of the queries, from total sales to figuring out how long a customer has been ordering.

**JOINs** — Most of the business-facing queries join orders back to customers (and to
products where needed) so the results show actual names instead of just IDs.

## Business Insights

Out of 793 customers and $2,297,200.86 in total sales, the average customer spent
about $2,896.85.

Sean Miller was the top customer overall at $25,043.05, followed by Tamara Chand
($19,052.22), Raymond Buch ($15,117.34), Tom Ashbrook ($14,595.62), and Adrian Barton
($14,473.57). Even though these are the top five, they only make up about 3.8% of total
revenue, so the customer base is fairly spread out rather than depending heavily on a
few big accounts.

Technology was the highest earning category at $836,154.03, just ahead of Furniture
($741,999.80) and Office Supplies ($719,047.03). The three categories are actually
pretty close to each other, which isn't what you'd expect if you assumed one category
dominates.

Consumer was the biggest segment by sales at $1,161,401.34, about 1.6 times more than
Corporate ($706,146.37) and almost 2.7 times more than Home Office ($429,653.15). This
suggests that most of the business's revenue is coming from individual/consumer buyers
rather than corporate or home office customers.

Only 12 out of 793 customers (about 1.5%) placed just a single order. Since there are
5,009 orders total across 793 customers, that works out to roughly 6.3 orders per
customer on average, so most customers do come back and order more than once. The
handful of one-time buyers could be a small list worth targeting for a win-back
campaign.

294 out of 793 customers (37.1%) spent more than the average. This is a bit lower than
half, which makes sense since a few very high-spending customers can pull the average
up, meaning more than half of customers end up below it. It's a reminder that looking
at the median alongside the average probably gives a better sense of what a "typical"
customer looks like.

Along the way, two data issues were caught and handled before they could cause
problems: ship-to address isn't fixed per customer (most customers ship to more than
one place), and some product IDs had two different names attached to them. Both were
noted in the schema and fixed so they wouldn't cause errors or bad joins later.

## Conclusion
This project walks through a full SQL analytics workflow on a real dataset, starting
from checking the raw data for issues, normalizing it into a proper relational schema,
and then using subqueries, CTEs, and window functions to answer specific business
questions. The queries cover the required questions around top and bottom customers,
single-order customers, above-average spenders, and highest order values, and also
extend into ten bonus questions looking at monthly trends, growth rates, segment and
category performance, customer value tiers, running totals, and customer tenure. All
queries were written for MySQL 8.0 and tested against the real dataset.
