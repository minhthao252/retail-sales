# US Retail Sales Analysis
This repository contains SQL queries used to analyze US retail sales data. The analysis focuses on understanding trends, comparing different business types, calculating percentages of total sales, tracking percentage change over time, and computing rolling time windows.

# Data
The analysis uses data from a CSV file named us_retail_sales.csv. This file is expected to contain retail sales data with columns for the sales month, NAICS code, kind of business, reason for null values (if any), and sales figures.

# Database Setup
The SQL code assumes you have a database set up and are loading the us_retail_sales.csv file into a table named retail_sales.

## Table Schema
The retail_sales table is created with the following schema:

| Column | Data Type | Description |

| sales_month | DATE | The month of the sales data. |

| naics_code | VARCHAR(255) | The NAICS (North American Industry Classification System) code for the business type. |

| kind_of_business | VARCHAR(255) | A description of the kind of business. |

| reason_for_null | VARCHAR(255) | Indicates the reason if sales data is null. |

| sales | DECIMAL | The sales figure for the given month and business type. |

## Data Loading
The data is loaded using a LOAD DATA INFILE statement. Note: The file path C:\Users\mthao\Documents\data\github\retail_orders\us_retail_sales.csv is specific to a local machine. You will need to update this path to where your CSV file is located on your system or server.

# Analysis Queries
The repository includes several SQL queries to perform different types of analysis on the retail sales data.

## Trending the Data
### Simple Trend: Views monthly or yearly total retail and food services sales.

### Comparing Components: Compares sales trends for specific business types (e.g., Book stores, Sporting goods stores, Hobby, toy, and game stores) or categories like men's and women's clothing stores.

### Ecart (Difference) and Ratio: Calculates the difference and ratio between sales of different categories (specifically men's and women's clothing stores up to December 2019).

# Percent of Total Calculations
Calculates the percentage contribution of specific business types (men's and women's clothing stores) to their combined total sales for each month. This is shown using both JOINs and window functions.

# Percent of Yearly Sales Each Month Represents
Determines what percentage of the total yearly sales for a specific business type each month represents. This is also demonstrated using both JOINs and window functions.

# Indexing to See Percent Change over Time
Calculates the percentage change in sales for a specific business type (women's clothing stores) relative to the sales in the first year of the dataset. This is shown using the FIRST_VALUE window function and a JOIN approach.

# Rolling Time Windows
Calculates rolling averages and counts over a specified time window (specifically a 12-month window for women's clothing stores sales ending in December 2019). This is shown using both JOINs with INTERVAL and window functions with ROWS BETWEEN.
