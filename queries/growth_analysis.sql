-- growth_analysis.sql
-- Period-over-period revenue and order volume analysis using LAG/LEAD.

-- ============================================================
-- Helper: monthly revenue and order volume base
-- ============================================================
WITH monthly_stats AS (
    SELECT
        DATE_TRUNC('month', o.order_date)              AS month,
        COUNT(DISTINCT o.order_id)                     AS order_count,
        COUNT(DISTINCT o.customer_id)                  AS unique_customers,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)  AS revenue,
        ROUND(AVG(oi.quantity * oi.unit_price)::NUMERIC, 2)  AS avg_item_value
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date)
),

-- ============================================================
-- 1. Month-over-month revenue and order volume growth
-- ============================================================
mom_growth AS (
    SELECT
        month,
        revenue,
        order_count,
        unique_customers,
        avg_item_value,
        LAG(revenue)        OVER (ORDER BY month) AS prev_month_revenue,
        LAG(order_count)    OVER (ORDER BY month) AS prev_month_orders,
        LAG(unique_customers) OVER (ORDER BY month) AS prev_month_customers,
        -- Next month preview via LEAD
        LEAD(revenue)       OVER (ORDER BY month) AS next_month_revenue,
        ROUND(
            100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
            / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
        )  AS mom_revenue_growth_pct,
        ROUND(
            100.0 * (order_count - LAG(order_count) OVER (ORDER BY month))
            / NULLIF(LAG(order_count) OVER (ORDER BY month), 0), 2
        )  AS mom_order_growth_pct,
        ROUND(
            100.0 * (unique_customers - LAG(unique_customers) OVER (ORDER BY month))
            / NULLIF(LAG(unique_customers) OVER (ORDER BY month), 0), 2
        )  AS mom_customer_growth_pct
    FROM monthly_stats
),

-- ============================================================
-- 2. Quarterly rollup
-- ============================================================
quarterly_stats AS (
    SELECT
        DATE_TRUNC('quarter', o.order_date)              AS quarter,
        COUNT(DISTINCT o.order_id)                       AS order_count,
        COUNT(DISTINCT o.customer_id)                    AS unique_customers,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)   AS revenue
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.status != 'cancelled'
    GROUP BY DATE_TRUNC('quarter', o.order_date)
),

qoq_growth AS (
    SELECT
        quarter,
        revenue,
        order_count,
        unique_customers,
        LAG(revenue)          OVER (ORDER BY quarter) AS prev_quarter_revenue,
        LAG(order_count)      OVER (ORDER BY quarter) AS prev_quarter_orders,
        LAG(unique_customers) OVER (ORDER BY quarter) AS prev_quarter_customers,
        ROUND(
            100.0 * (revenue - LAG(revenue) OVER (ORDER BY quarter))
            / NULLIF(LAG(revenue) OVER (ORDER BY quarter), 0), 2
        )  AS qoq_revenue_growth_pct,
        ROUND(
            100.0 * (order_count - LAG(order_count) OVER (ORDER BY quarter))
            / NULLIF(LAG(order_count) OVER (ORDER BY quarter), 0), 2
        )  AS qoq_order_growth_pct,
        -- Running cumulative revenue over all quarters
        SUM(revenue) OVER (ORDER BY quarter ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
    FROM quarterly_stats
),

-- ============================================================
-- 3. Revenue decomposition: is growth driven by volume or AOV?
--    AOV = revenue / order_count (average order value)
-- ============================================================
aov_decomposition AS (
    SELECT
        month,
        revenue,
        order_count,
        ROUND(revenue / NULLIF(order_count, 0), 2)  AS avg_order_value,
        LAG(ROUND(revenue / NULLIF(order_count, 0), 2)) OVER (ORDER BY month) AS prev_aov,
        ROUND(
            100.0 * (
                ROUND(revenue / NULLIF(order_count, 0), 2)
                - LAG(ROUND(revenue / NULLIF(order_count, 0), 2)) OVER (ORDER BY month)
            )
            / NULLIF(LAG(ROUND(revenue / NULLIF(order_count, 0), 2)) OVER (ORDER BY month), 0),
        2) AS mom_aov_growth_pct
    FROM monthly_stats
)

-- ============================================================
-- Output 1: Month-over-month summary
-- ============================================================
SELECT
    'MoM' AS period_type,
    month            AS period_start,
    revenue,
    prev_month_revenue,
    mom_revenue_growth_pct,
    order_count,
    mom_order_growth_pct,
    unique_customers,
    mom_customer_growth_pct
FROM mom_growth
ORDER BY month;

-- ============================================================
-- Output 2: Quarter-over-quarter summary
-- ============================================================
SELECT
    'QoQ' AS period_type,
    quarter            AS period_start,
    revenue,
    prev_quarter_revenue,
    qoq_revenue_growth_pct,
    order_count,
    qoq_order_growth_pct,
    unique_customers,
    cumulative_revenue
FROM qoq_growth
ORDER BY quarter;

-- ============================================================
-- Output 3: AOV decomposition (helps explain *why* revenue changed)
-- ============================================================
SELECT
    month,
    revenue,
    order_count,
    avg_order_value,
    prev_aov,
    mom_aov_growth_pct
FROM aov_decomposition
ORDER BY month;
