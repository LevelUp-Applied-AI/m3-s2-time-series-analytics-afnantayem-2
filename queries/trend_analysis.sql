-- trend_analysis.sql
-- Moving averages for daily revenue and order volume using ROWS BETWEEN frame specs.

-- ============================================================
-- Base: daily revenue and order count
-- ============================================================
WITH daily_stats AS (
    SELECT
        o.order_date::DATE                                    AS day,
        COUNT(DISTINCT o.order_id)                            AS order_count,
        ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2)   AS daily_revenue
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.status != 'cancelled'
    GROUP BY o.order_date::DATE
),

-- ============================================================
-- Moving averages with explicit ROWS BETWEEN frame specs
-- ============================================================
moving_averages AS (
    SELECT
        day,
        daily_revenue,
        order_count,

        -- 7-day moving average of daily revenue
        -- Frame: current row and 6 preceding rows = 7-day window
        ROUND(
            AVG(daily_revenue) OVER (
                ORDER BY day
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            )::NUMERIC, 2
        ) AS revenue_7d_ma,

        -- 30-day moving average of daily revenue
        ROUND(
            AVG(daily_revenue) OVER (
                ORDER BY day
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )::NUMERIC, 2
        ) AS revenue_30d_ma,

        -- 7-day moving average of daily order count
        ROUND(
            AVG(order_count) OVER (
                ORDER BY day
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            )::NUMERIC, 2
        ) AS order_count_7d_ma,

        -- Running total revenue (cumulative)
        SUM(daily_revenue) OVER (
            ORDER BY day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,

        -- 7-day revenue range (max - min) to measure daily volatility
        MAX(daily_revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) - MIN(daily_revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS revenue_7d_range,

        -- Deviation from 7-day moving average (noise indicator)
        ROUND(
            daily_revenue - AVG(daily_revenue) OVER (
                ORDER BY day
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        ) AS deviation_from_7d_ma
    FROM daily_stats
)

-- ============================================================
-- Final output: raw numbers alongside smoothed trend lines
-- ============================================================
SELECT
    day,
    daily_revenue,
    revenue_7d_ma,
    revenue_30d_ma,
    order_count,
    order_count_7d_ma,
    cumulative_revenue,
    revenue_7d_range,
    deviation_from_7d_ma,
    -- Flag days where actual revenue deviates >20% from 7d MA (anomaly candidates)
    CASE
        WHEN ABS(deviation_from_7d_ma) > 0.20 * NULLIF(revenue_7d_ma, 0)
        THEN 'anomaly'
        ELSE 'normal'
    END AS revenue_anomaly_flag
FROM moving_averages
ORDER BY day;
