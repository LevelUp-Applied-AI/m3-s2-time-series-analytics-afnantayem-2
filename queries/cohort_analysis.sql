WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM orders o
),
first_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date AS first_order_date,
        DATE_TRUNC('month', order_date) AS cohort_month
    FROM customer_orders
    WHERE rn = 1
)
SELECT * FROM first_orders;




WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM orders o
),
first_orders AS (
    SELECT
        customer_id,
        order_date AS first_order_date,
        DATE_TRUNC('month', order_date) AS cohort_month
    FROM customer_orders
    WHERE rn = 1
),
all_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        f.first_order_date,
        f.cohort_month,
        (o.order_date - f.first_order_date) AS days_since_first
    FROM orders o
    JOIN first_orders f
        ON o.customer_id = f.customer_id
)
SELECT * FROM all_orders;



WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM orders o
),
first_orders AS (
    SELECT
        customer_id,
        order_date AS first_order_date,
        DATE_TRUNC('month', order_date) AS cohort_month
    FROM customer_orders
    WHERE rn = 1
),
all_orders AS (
    SELECT
        o.customer_id,
        o.order_date,
        f.first_order_date,
        f.cohort_month,
        (o.order_date - f.first_order_date) AS days_since_first
    FROM orders o
    JOIN first_orders f
        ON o.customer_id = f.customer_id
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM first_orders
    GROUP BY cohort_month
),
retention AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE 
            WHEN days_since_first <= INTERVAL '30 days' 
            AND days_since_first > INTERVAL '0 days'
            THEN customer_id END) AS retained_30,
        COUNT(DISTINCT CASE 
            WHEN days_since_first <= INTERVAL '60 days'
            AND days_since_first > INTERVAL '0 days'
            THEN customer_id END) AS retained_60,
        COUNT(DISTINCT CASE 
            WHEN days_since_first <= INTERVAL '90 days'
            AND days_since_first > INTERVAL '0 days'
            THEN customer_id END) AS retained_90
    FROM all_orders
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    c.total_customers,
    r.retained_30 * 1.0 / c.total_customers AS retention_30,
    r.retained_60 * 1.0 / c.total_customers AS retention_60,
    r.retained_90 * 1.0 / c.total_customers AS retention_90
FROM cohort_size c
JOIN retention r
    ON c.cohort_month = r.cohort_month
ORDER BY c.cohort_month;