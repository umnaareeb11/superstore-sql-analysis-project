# SQL Sales Analysis Assignment

## Project Overview

This project focuses on performing advanced sales data analysis using structured SQL
queries. The dataset is the Superstore Sales dataset from Kaggle
(`vivek468/superstore-dataset-final`). Queries cover everything from basic subqueries to
CTEs, window functions, joins, aggregations, and real business case questions. All
queries are written for MySQL 8.0 and were tested and executed in MySQL Workbench.

## Created By

Name: Areeba
Email: umnaareeb11@gmail.com
Tool: MySQL Workbench 8.0
Dataset: Superstore Sales Dataset (Kaggle, real dataset — 9,994 rows, 793 customers,
1,862 products, 5,009 orders)

## Work Summary

In this assignment, I worked with a sales dataset containing orders, customers,
products, regions, and profit data. I first cleaned and split the raw data into
separate `customers`, `products`, and `orders` tables, then wrote SQL queries using
subqueries, correlated subqueries, CTEs, and window functions to answer business
questions — things like which customers rank highest by sales, who spends above
average, which customers only ordered once, and which order was each customer's
biggest.

## Assignment Structure

- **Part 1 — Database Setup:** Imported the raw Superstore CSV into a staging table,
  then split it into `customers`, `products`, and `orders` tables with proper primary
  and foreign keys.
- **Part 2 — Core Queries:** Wrote 7 queries covering a scalar subquery, a correlated
  subquery, a CTE, a CTE combined with a subquery, RANK()/DENSE_RANK(), ROW_NUMBER()
  with PARTITION BY, and a top-3 customers query using a window function.
- **Part 3 — Final Combined Query:** Brought JOIN, CTE, and window functions together
  in one query to build a full customer sales leaderboard (name, total sales, rank).
- **Part 4 — Mini Project:** Solved 5 business questions — top 5 customers, bottom 5
  customers, customers who placed only one order, customers above average sales, and
  each customer's highest single order value.
- **Part 9 — Bonus Analysis:** 10 additional queries covering monthly sales trends,
  month-over-month growth using LAG(), segment and category performance, CASE-based
  value segmentation, running totals, customers with declining sales, best-selling
  product per category, average discount by region, and customer tenure.

## Analysis Results

- Sean Miller is the highest-value customer overall, followed by Tamara Chand and
  Raymond Buch.
- The top 5 customers account for only about 3.8% of total revenue — the customer
  base is fairly spread out rather than concentrated in a few big accounts.
- Technology is the top-earning category, but Furniture and Office Supplies are close
  behind — no single category dominates the mix.
- Consumer is the biggest segment by sales, followed by Corporate and then Home
  Office.
- Only 12 out of 793 customers placed just one order — most customers come back and
  order more than once (about 6.3 orders per customer on average).
- About 37% of customers spend above the average — since a handful of high spenders
  pull the average up, more than half of customers actually fall below it.

## Files in This Repo

- `superstore_analysis_mysql.sql` — the full SQL script (Part 1 through Part 9)
- `Superstore_Full_Assignment.ipynb` — notebook version with explanations, outputs,
  and insights for each query
- `REPORT.md` — written report covering the objective, schema, approach, and findings
- `superstore_raw.csv` — cleaned copy of the dataset used to build the database

## How to Run It

1. Import the Superstore CSV into a table called `superstore_raw` in MySQL 8.0 (see
   the LOAD DATA command near the top of the SQL script).
2. Run `superstore_analysis_mysql.sql` from top to bottom — it creates the database,
   builds the `customers`, `products`, and `orders` tables, and then runs all the
   analysis queries.
3. Check row counts after import: `superstore_raw` and `orders` should both be 9,994,
   `customers` should be 793, and `products` should be 1,862.

