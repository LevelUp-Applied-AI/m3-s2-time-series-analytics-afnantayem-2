-- cohort_analysis.sql
-- Defines customer cohorts by first-purchase month (not signup date)
-- and analyzes retention at 30, 60, and 90 days.

-- ============================================================
-- Step 1: Identify each customer's first purchase date
-- ============================================================
WITH first_purchases AS (
    SELECT
        o.customer_id,
        MIN(o.order_date)                              AS first_purchase_date,
        DATE_TRUNC('month', MIN(o.order_date))         AS cohort_month
    FROM orders o
    WHERE o.status != 'cancelled'
    GROUP BY o.customer_id
),

-- ============================================================
-- Step 2: Assign a row number within each cohort (used for counting)
-- ============================================================
cohort_members AS (
    SELECT
        customer_id,
        first_purchase_date,
        cohort_month,
        ROW_NUMBER() OVER (PARTITION BY cohort_month ORDER BY first_purchase_date, customer_id) AS rn
    FROM first_purchases
),

-- ============================================================
-- Step 3: Cohort sizes
-- ============================================================
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(customer_id) AS cohort_size
    FROM cohort_members
    GROUP BY cohort_month
),

-- ============================================================
-- Step 4: Check which customers made a repeat purchase within
--         30, 60, and 90 days of their first purchase
-- ============================================================
repeat_purchases AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        fp.first_purchase_date,
        MIN(o.order_date)                                           AS second_purchase_date,
        (MIN(o.order_date) - fp.first_purchase_date)                AS days_to_repeat
    FROM first_purchases fp
    JOIN orders o
        ON  o.customer_id = fp.customer_id
        AND o.order_date   > fp.first_purchase_date
        AND o.status      != 'cancelled'
    GROUP BY fp.customer_id, fp.cohort_month, fp.first_purchase_date
),

-- ============================================================
-- Step 5: Aggregate retention flags per cohort
-- ============================================================
cohort_retention AS (
    SELECT
        cs.cohort_month,
        cs.cohort_size,
        COUNT(rp.customer_id)                                                   AS repeat_customers_total,
        COUNT(CASE WHEN rp.days_to_repeat <= 30 THEN 1 END)                     AS retained_30d,
        COUNT(CASE WHEN rp.days_to_repeat <= 60 THEN 1 END)                     AS retained_60d,
        COUNT(CASE WHEN rp.days_to_repeat <= 90 THEN 1 END)                     AS retained_90d
    FROM cohort_sizes cs
    LEFT JOIN repeat_purchases rp USING (cohort_month)
    GROUP BY cs.cohort_month, cs.cohort_size
)

-- ============================================================
-- Final output: retention rates with window-based ranking
-- ============================================================
SELECT
    cohort_month,
    cohort_size,
    retained_30d,
    retained_60d,
    retained_90d,
    ROUND(100.0 * retained_30d / NULLIF(cohort_size, 0), 2)  AS retention_rate_30d_pct,
    ROUND(100.0 * retained_60d / NULLIF(cohort_size, 0), 2)  AS retention_rate_60d_pct,
    ROUND(100.0 * retained_90d / NULLIF(cohort_size, 0), 2)  AS retention_rate_90d_pct,
    -- Rank cohorts from strongest to weakest 90-day retention
    RANK() OVER (ORDER BY ROUND(100.0 * retained_90d / NULLIF(cohort_size, 0), 2) DESC) AS retention_rank_desc,
    -- Running cumulative customers across cohorts (ordered by month)
    SUM(cohort_size) OVER (ORDER BY cohort_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM cohort_retention
ORDER BY cohort_month;
