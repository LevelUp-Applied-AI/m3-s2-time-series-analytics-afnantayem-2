-- growth_analysis.sql
-- Period-over-period revenue and order volume analysis using LAG/LEAD.

-- ============================================================
-- Query 1: Month-over-month revenue, order volume, and customer growth
-- ============================================================
WITH monthly_stats AS (
    SELECT
        DATE_TRUNC('month', o.order_date)              AS month,
        COUNT(DISTINCT o.order_id)                     AS order_count,
        COUNT(DISTINCT o.customer_id)                  AS unique_customers,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)  AS revenue
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month,
    revenue,
    LAG(revenue)          OVER (ORDER BY month)  AS prev_month_revenue,
    LEAD(revenue)         OVER (ORDER BY month)  AS next_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
    )  AS mom_revenue_growth_pct,
    order_count,
    LAG(order_count)      OVER (ORDER BY month)  AS prev_month_orders,
    ROUND(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month))
        / NULLIF(LAG(order_count) OVER (ORDER BY month), 0), 2
    )  AS mom_order_growth_pct,
    unique_customers,
    LAG(unique_customers) OVER (ORDER BY month)  AS prev_month_customers,
    ROUND(
        100.0 * (unique_customers - LAG(unique_customers) OVER (ORDER BY month))
        / NULLIF(LAG(unique_customers) OVER (ORDER BY month), 0), 2
    )  AS mom_customer_growth_pct
FROM monthly_stats
ORDER BY month;

-- ============================================================
-- Query 2: Quarter-over-quarter revenue and order volume growth
-- ============================================================
WITH quarterly_stats AS (
    SELECT
        DATE_TRUNC('quarter', o.order_date)              AS quarter,
        COUNT(DISTINCT o.order_id)                       AS order_count,
        COUNT(DISTINCT o.customer_id)                    AS unique_customers,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)   AS revenue
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.status != 'cancelled'
    GROUP BY DATE_TRUNC('quarter', o.order_date)
)
SELECT
    quarter,
    revenue,
    LAG(revenue)          OVER (ORDER BY quarter)  AS prev_quarter_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY quarter))
        / NULLIF(LAG(revenue) OVER (ORDER BY quarter), 0), 2
    )  AS qoq_revenue_growth_pct,
    order_count,
    LAG(order_count)      OVER (ORDER BY quarter)  AS prev_quarter_orders,
    ROUND(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY quarter))
        / NULLIF(LAG(order_count) OVER (ORDER BY quarter), 0), 2
    )  AS qoq_order_growth_pct,
    unique_customers,
    SUM(revenue) OVER (ORDER BY quarter ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM quarterly_stats
ORDER BY quarter;

-- ============================================================
-- Query 3: AOV decomposition — is growth driven by volume or order value?
-- ============================================================
WITH monthly_aov AS (
    SELECT
        DATE_TRUNC('month', o.order_date)              AS month,
        COUNT(DISTINCT o.order_id)                     AS order_count,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)  AS revenue
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month,
    revenue,
    order_count,
    ROUND(revenue / NULLIF(order_count, 0), 2)  AS avg_order_value,
    LAG(ROUND(revenue / NULLIF(order_count, 0), 2)) OVER (ORDER BY month)  AS prev_aov,
    ROUND(
        100.0 * (
            ROUND(revenue / NULLIF(order_count, 0), 2)
            - LAG(ROUND(revenue / NULLIF(order_count, 0), 2)) OVER (ORDER BY month)
        )
        / NULLIF(LAG(ROUND(revenue / NULLIF(order_count, 0), 2)) OVER (ORDER BY month), 0),
    2)  AS mom_aov_growth_pct
FROM monthly_aov
ORDER BY month;