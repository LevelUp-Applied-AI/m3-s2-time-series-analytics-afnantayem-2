WITH daily_metrics AS (
    SELECT
        DATE(order_date) AS day,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY day
)
SELECT * FROM daily_metrics
ORDER BY day;


WITH daily_metrics AS (
    SELECT
        DATE(order_date) AS day,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY day
)
SELECT
    day,
    order_count,
    revenue,

    -- 7-day moving average revenue
    AVG(revenue) OVER (
        ORDER BY day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma_7_revenue,

    -- 30-day moving average revenue
    AVG(revenue) OVER (
        ORDER BY day
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS ma_30_revenue,

    -- 7-day moving average orders
    AVG(order_count) OVER (
        ORDER BY day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma_7_orders

FROM daily_metrics
ORDER BY day;