WITH customer_orders AS (
    SELECT
        o.customer_id,
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
        f.cohort_month,
        (o.order_date - f.first_order_date) AS days_since_first
    FROM orders o
    JOIN first_orders f
        ON o.customer_id = f.customer_id
),
retention AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE 
            WHEN days_since_first <= INTERVAL '30 days'
            AND days_since_first > INTERVAL '0 days'
            THEN customer_id END
        ) AS retained_30
    FROM all_orders
    GROUP BY cohort_month
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM first_orders
    GROUP BY cohort_month
),
final AS (
    SELECT
        r.cohort_month,
        r.retained_30 * 1.0 / c.total_customers AS retention_rate
    FROM retention r
    JOIN cohort_size c
        ON r.cohort_month = c.cohort_month
)
SELECT
    cohort_month,
    retention_rate,

    LAG(retention_rate) OVER (ORDER BY cohort_month) AS prev_retention,
    (retention_rate - LAG(retention_rate) OVER (ORDER BY cohort_month))
        AS retention_change

FROM final
ORDER BY cohort_month;


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT
    month,
    revenue,

    -- running total
    SUM(revenue) OVER (
        ORDER BY month
    ) AS running_total,

    -- previous revenue
    LAG(revenue) OVER (
        ORDER BY month
    ) AS prev_revenue,

    -- growth rate
    (revenue - LAG(revenue) OVER (ORDER BY month)) * 1.0
        / LAG(revenue) OVER (ORDER BY month) AS growth_rate

FROM monthly_revenue
ORDER BY month;


SELECT
    p.category,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price) AS revenue,

    SUM(SUM(oi.quantity * oi.unit_price)) OVER (
        PARTITION BY p.category
    ) AS category_total,

    SUM(SUM(oi.quantity * oi.unit_price)) OVER () AS overall_total

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category, month;