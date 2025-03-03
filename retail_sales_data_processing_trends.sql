#CREATE TABLE THEN IMPORT DATA
DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales
(
    sales_month      DATE,
    naics_code       VARCHAR(255),
    kind_of_business VARCHAR(255),
    reason_for_null  VARCHAR(255),
    sales            DECIMAL
);
###TRENDING THE DATA
##Simple Trend
SELECT sales_month, retail_sales.sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total';
#transform at yearly level to reduce noise
SELECT YEAR(retail_sales.sales_month) AS sales_year,
       SUM(retail_sales.sales) AS sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
GROUP BY sales_year;
##Comparing components
SELECT YEAR(retail_sales.sales_month) as sales_year,
       retail_sales.kind_of_business,
       SUM(retail_sales.sales) as sales
FROM retail_sales
WHERE kind_of_business IN ('Book stores', 'Sporting goods stores', 'Hobby, toy, and game stores')
GROUP BY sales_year, kind_of_business;
#Compare women and mens sales
SELECT YEAR(retail_sales.sales_month) as sales_year,
       sum(case when retail_sales.kind_of_business = 'Women''s clothing stores' then sales end) as womens_sales,
       sum(case when retail_sales.kind_of_business = 'Men''s clothing stores' then sales end) as mens_sales
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
     ,'Women''s clothing stores')
    and sales_month <= '2019-12-01'
    GROUP BY sales_year;
#ecart of women and men sales

SELECT YEAR(retail_sales.sales_month) as sales_year,
       sum(case when retail_sales.kind_of_business = 'Women''s clothing stores' then sales end) - sum(case when retail_sales.kind_of_business = 'Men''s clothing stores' then sales end) as ecart_gender_sell
FROM retail_sales
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
  AND sales_month <= '2019-12-01'
GROUP BY sales_year;
#calculate the ratio of women and men clothing sales
SELECT sales_year,
       womens_sales / mens_sales AS womens_times_of_mens
FROM (
    SELECT YEAR(sales_month) AS sales_year,
           SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
           SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
    FROM retail_sales
    WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
      AND sales_month <= '2019-12-01'
    GROUP BY sales_year
) AS a;
##Percent of Total Calculations using join
SELECT
    a.sales_month,
    a.kind_of_business,
    a.sales,
    (a.sales * 100 / total_sales.total_sales) AS pct_total_sales
FROM
    retail_sales a
JOIN (
    SELECT
        sales_month,
        SUM(sales) AS total_sales
    FROM
        retail_sales
    WHERE
        kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
    GROUP BY
        sales_month
) AS total_sales ON a.sales_month = total_sales.sales_month
WHERE
    a.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores');
#using window function (more practice
SELECT
    sales_month,
    kind_of_business,
    sales,
    SUM(sales) OVER (PARTITION BY sales_month) AS total_sales,
    sales * 100 / SUM(sales) OVER (PARTITION BY sales_month) AS pct_total #have to use window function in this case to specify the partition by sales_month
FROM
    retail_sales
WHERE
    kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores');

##the percent of yearly sales each month represents
#using join (The query is designed to find, for each month and type of business, the percentage of yearly sales that each month’s sales represent by compare itself)
SELECT
    sales_month,
    kind_of_business,
    sales * 100 / yearly_sales AS pct_yearly
FROM (
    SELECT
        a.sales_month,
        a.kind_of_business,
        a.sales,
        SUM(b.sales) AS yearly_sales
    FROM
        retail_sales a
    JOIN
        retail_sales b
    ON
        YEAR(a.sales_month) = YEAR(b.sales_month)
        AND a.kind_of_business = b.kind_of_business
    WHERE
        a.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
    GROUP BY
        a.sales_month, a.kind_of_business, a.sales
) AS aa;
#using window function
SELECT
    sales_month,
    kind_of_business,
    sales,
    SUM(sales) OVER (PARTITION BY YEAR(sales_month), kind_of_business) AS yearly_sales,
    sales * 100 / SUM(sales) OVER (PARTITION BY YEAR(sales_month), kind_of_business) AS pct_yearly
FROM
    retail_sales
WHERE
    kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores');
##Indexing to See Percent Change over Time
#using first_value window function (using to find the first value associated with the first row in the PARTITION Clause acoording to the sort in ORDER BY)
SELECT sales_year, sales,
       first_value(sales) OVER (ORDER BY sales_year) as index_table #partiton by allows to segment your dataset into distinct groups while order by returns the  value from the first year in the sorted list of years.
FROM
    (SELECT YEAR(retail_sales.sales_month) as sales_year,
            SUM(retail_sales.sales) as sales
    FROM retail_sales
    WHERE kind_of_business = 'Women''s clothing stores'
    GROUP BY sales_year) a;
#the percentage change in sales from the first year in the dataset
SELECT sales_year, sales,
       (sales / FIRST_VALUE(sales) OVER (ORDER BY sales_year) - 1) * 100 AS pct_from_index
FROM
(
    SELECT YEAR(sales_month) AS sales_year,
           SUM(sales) AS sales
    FROM retail_sales
    WHERE kind_of_business = 'Women''s clothing stores'
    GROUP BY sales_year
) AS a;
#using JOIN
SELECT sales_year, sales, #4
       (sales / index_sales - 1) * 100 AS pct_from_index
FROM
(
    SELECT YEAR(aa.sales_month) AS sales_year, #3
           bb.index_sales,
           SUM(aa.sales) AS sales
    FROM retail_sales aa
    CROSS JOIN
    (
        SELECT SUM(a.sales) AS index_sales #1
        FROM retail_sales a
        JOIN
        (
            SELECT MIN(YEAR(sales_month)) AS first_year #2
            FROM retail_sales
            WHERE kind_of_business = 'Women''s clothing stores'
        ) b ON YEAR(a.sales_month) = b.first_year
        WHERE a.kind_of_business = 'Women''s clothing stores'
    ) bb
    WHERE aa.kind_of_business = 'Women''s clothing stores'
    GROUP BY sales_year, bb.index_sales
) aaa;

###Rolling Time Windows -  moving calculations, that take into account multiple periods.
##Calculating Rolling Time Windows
#using join function and interval function
SELECT a.sales_month as start_date,
       a.sales,
       b.sales_month as end_of_periode,
       b.sales as rolling_sales
FROM retail_sales a
JOIN retail_sales b on a.kind_of_business = b.kind_of_business
    AND b.sales_month BETWEEN a.sales_month - INTERVAL 11 MONTH #defines the rolling 12-month window, ending at a.sales_month and looking back 11 months.
    AND a.sales_month
WHERE a.sales_month = '2019-12-01'
   AND b.kind_of_business = 'Women''s clothing stores'
   AND a.kind_of_business = 'Women''s clothing stores';
#apply average aggregate and count function to calculate avarage sales each periode (in a row)
SELECT
    sales_month,
    AVG(retail_sales.sales) OVER (ORDER BY retail_sales.sales_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS avg_sales,
    COUNT(retail_sales.sales) OVER (ORDER BY retail_sales.sales_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS records_count
FROM
    retail_sales
WHERE
    kind_of_business = 'Women''s clothing stores';
