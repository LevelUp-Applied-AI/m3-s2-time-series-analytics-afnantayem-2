WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT * FROM monthly_metrics
ORDER BY month;



WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
),
growth AS (
    SELECT
        month,
        order_count,
        revenue,

        LAG(order_count) OVER (ORDER BY month) AS prev_orders,
        LAG(revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly_metrics
)
SELECT
    month,
    order_count,
    revenue,

    (order_count - prev_orders) * 1.0 / prev_orders AS order_growth_rate,
    (revenue - prev_revenue) * 1.0 / prev_revenue AS revenue_growth_rate

FROM growth
ORDER BY month;



WITH quarterly_metrics AS (
    SELECT
        DATE_TRUNC('quarter', order_date) AS quarter,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY quarter
),
qoq_growth AS (
    SELECT
        quarter,
        revenue,
        LAG(revenue) OVER (ORDER BY quarter) AS prev_revenue
    FROM quarterly_metrics
)
SELECT
    quarter,
    revenue,
    (revenue - prev_revenue) * 1.0 / prev_revenue AS qoq_growth_rate
FROM qoq_growth
ORDER BY quarter;