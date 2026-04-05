-- combined_analysis.sql
-- Multi-window queries that combine analytical lenses no single window function can provide alone.

-- ============================================================
-- Query 1: Cohort retention rates with period-over-period change
--           ROW_NUMBER (cohort definition) + LAG (retention trend)
-- ============================================================
WITH first_purchases AS (
    SELECT
        o.customer_id,
        MIN(o.order_date)                          AS first_purchase_date,
        DATE_TRUNC('month', MIN(o.order_date))     AS cohort_month
    FROM orders o
    WHERE o.status != 'cancelled'
    GROUP BY o.customer_id
),

cohort_members AS (
    SELECT
        customer_id,
        first_purchase_date,
        cohort_month,
        ROW_NUMBER() OVER (PARTITION BY cohort_month ORDER BY first_purchase_date, customer_id) AS member_rank
    FROM first_purchases
),

cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohort_members
    GROUP BY cohort_month
),

repeat_90d AS (
    SELECT
        fp.cohort_month,
        COUNT(DISTINCT o.customer_id) AS retained_90d
    FROM first_purchases fp
    JOIN orders o
        ON  o.customer_id = fp.customer_id
        AND o.order_date   > fp.first_purchase_date
        AND o.order_date  <= fp.first_purchase_date + INTERVAL '90 days'
        AND o.status      != 'cancelled'
    GROUP BY fp.cohort_month
),

cohort_retention AS (
    SELECT
        cs.cohort_month,
        cs.cohort_size,
        COALESCE(r.retained_90d, 0) AS retained_90d,
        ROUND(100.0 * COALESCE(r.retained_90d, 0) / NULLIF(cs.cohort_size, 0), 2) AS retention_rate_90d
    FROM cohort_sizes cs
    LEFT JOIN repeat_90d r USING (cohort_month)
)

SELECT
    cohort_month,
    cohort_size,
    retained_90d,
    retention_rate_90d,
    -- Period-over-period change in retention rate (LAG)
    LAG(retention_rate_90d) OVER (ORDER BY cohort_month)  AS prev_cohort_retention_rate,
    ROUND(
        retention_rate_90d
        - LAG(retention_rate_90d) OVER (ORDER BY cohort_month)
    , 2)                                                   AS retention_rate_mom_change_ppts,
    -- Running average retention across all cohorts so far
    ROUND(
        AVG(retention_rate_90d) OVER (
            ORDER BY cohort_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2
    )                                                      AS running_avg_retention_rate,
    -- Rank cohorts by retention (best = 1)
    RANK() OVER (ORDER BY retention_rate_90d DESC)         AS retention_rank
FROM cohort_retention
ORDER BY cohort_month;


-- ============================================================
-- Query 2: Category revenue share with 30-day moving average trend
--           Partitioned SUM (share %) + ROWS BETWEEN frame (MA trend)
-- ============================================================
WITH daily_category_revenue AS (
    SELECT
        o.order_date::DATE                                      AS day,
        p.category,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)    AS category_revenue
    FROM orders o
    JOIN order_items oi USING (order_id)
    JOIN products p     ON oi.product_id = p.product_id
    WHERE o.status != 'cancelled'
    GROUP BY o.order_date::DATE, p.category
)

SELECT
    day,
    category,
    category_revenue,

    -- Daily revenue share for this category (% of all categories that day)
    ROUND(
        100.0 * category_revenue
        / NULLIF(SUM(category_revenue) OVER (PARTITION BY day), 0)
    , 2) AS daily_category_share_pct,

    -- 30-day moving average revenue for this category
    ROUND(
        AVG(category_revenue) OVER (
            PARTITION BY category
            ORDER BY day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) AS category_revenue_30d_ma,

    -- Running total revenue for this category
    SUM(category_revenue) OVER (
        PARTITION BY category
        ORDER BY day
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS category_cumulative_revenue,

    -- Rank categories by revenue on each given day
    RANK() OVER (PARTITION BY day ORDER BY category_revenue DESC) AS daily_category_rank
FROM daily_category_revenue
ORDER BY day, category;


-- ============================================================
-- Query 3: Monthly revenue by customer segment with growth rate
--           and running total (LAG + SUM window)
-- ============================================================
WITH monthly_segment_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date)                      AS month,
        c.segment,
        COUNT(DISTINCT o.order_id)                             AS order_count,
        COUNT(DISTINCT o.customer_id)                          AS active_customers,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)   AS revenue
    FROM orders o
    JOIN order_items oi  USING (order_id)
    JOIN customers c     ON o.customer_id = c.customer_id
    WHERE o.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date), c.segment
)

SELECT
    month,
    segment,
    revenue,
    order_count,
    active_customers,

    -- Month-over-month revenue growth within each segment (LAG)
    LAG(revenue) OVER (PARTITION BY segment ORDER BY month)            AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (PARTITION BY segment ORDER BY month))
        / NULLIF(LAG(revenue) OVER (PARTITION BY segment ORDER BY month), 0)
    , 2)                                                                AS mom_revenue_growth_pct,

    -- Running cumulative revenue per segment
    SUM(revenue) OVER (
        PARTITION BY segment
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                                   AS segment_cumulative_revenue,

    -- Segment revenue share of total revenue each month
    ROUND(
        100.0 * revenue
        / NULLIF(SUM(revenue) OVER (PARTITION BY month), 0)
    , 2)                                                                AS segment_monthly_share_pct,

    -- Rank segments within each month by revenue
    RANK() OVER (PARTITION BY month ORDER BY revenue DESC)             AS segment_rank_in_month
FROM monthly_segment_revenue
ORDER BY month, segment;
