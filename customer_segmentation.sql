-- RECENCY
SELECT DISTINCT(CUSTOMERNAME), COUNT(*) AS total_orders, SUM(QUANTITYORDERED) total_quantity, SUM(SALES) total_sales, MAX(ORDERDATE) last_orderdate, DATEDIFF('2020-05-31', MAX(ORDERDATE)) recency
FROM mytable
GROUP BY CUSTOMERNAME
ORDER BY last_orderdate asc;

-- RFM Percentile 
SELECT *,
       ntile(3) over (order by last_orderdate desc) rfm_recency,
       ntile(3) over (order by total_orders) rfm_frequency,
       ntile(3) over (order by total_sales) rfm_monetary
FROM (
    SELECT DISTINCT
           CUSTOMERNAME,
           COUNT(*) as total_orders,
           SUM(SALES) as total_sales,
           DATEDIFF('2020-05-31', MAX(ORDERDATE)) as last_orderdate
    FROM mytable
    GROUP BY CUSTOMERNAME
) AS rfm
ORDER BY last_orderdate;

-- RFM SCORE
WITH rfm AS (
    SELECT DISTINCT
        CUSTOMERNAME,
        COUNT(*) as total_orders,
        SUM(SALES) as total_sales,
        DATEDIFF('2020-05-31', MAX(ORDERDATE)) as last_orderdate
    FROM mytable
    GROUP BY CUSTOMERNAME
    ORDER BY last_orderdate
),
rfm_calc as (
    SELECT
        *,
        ntile(3) over (order by last_orderdate desc) rfm_recency,
        ntile(3) over (order by total_orders) rfm_frequency,
        ntile(3) over (order by total_sales) rfm_monetary
    FROM rfm
)

SELECT
    *,
    rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
    CONCAT(rfm_recency, rfm_frequency, rfm_monetary) as rfm
FROM rfm_calc
UNION ALL
SELECT
    *,
    rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
    CONCAT(rfm_recency, rfm_frequency, rfm_monetary) as rfm
FROM rfm_calc
ORDER BY rfm_score desc;

-- SEGMENTATION 
SELECT
    *,
    CASE
        WHEN rfm IN (311, 312, 311) THEN 'new customers'
        WHEN rfm IN (111, 121, 131, 122, 133, 113, 112, 132) THEN 'lost customers'
        WHEN rfm IN (212, 313, 123, 221, 211, 232) THEN 'regular customers'
        WHEN rfm IN (223, 222, 213, 322, 231, 321, 331) THEN 'loyal customers'
        WHEN rfm IN (333, 332, 323, 233) THEN 'champion customers'
    END as rfm_segment
FROM (
    WITH rfm AS (
        SELECT DISTINCT
            CUSTOMERNAME,
            COUNT(*) as total_orders,
            SUM(SALES) as total_sales,
            DATEDIFF('2020-05-31', MAX(ORDERDATE)) as last_orderdate
        FROM mytable
        GROUP BY CUSTOMERNAME
        ORDER BY last_orderdate
    ),
    rfm_calc as (
        SELECT
            *,
            ntile(3) over (order by last_orderdate desc) rfm_recency,
            ntile(3) over (order by total_orders) rfm_frequency,
            ntile(3) over (order by total_sales) rfm_monetary
        FROM rfm
    )

    SELECT
        *,
        rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
        CONCAT(rfm_recency, rfm_frequency, rfm_monetary) as rfm
    FROM rfm_calc

    UNION ALL

    SELECT
        *,
        rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
        CONCAT(rfm_recency, rfm_frequency, rfm_monetary) as rfm
    FROM rfm_calc
) AS combined_result
ORDER BY rfm_score DESC;
