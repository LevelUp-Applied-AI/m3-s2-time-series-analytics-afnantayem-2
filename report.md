## Executive Summary

Over the past 12 months, the business generated meaningful top-line revenue growth driven primarily by higher order volumes rather than price increases. Customer retention remains the single largest lever for sustainable growth — early cohorts show retention rates above 30% at 90 days, while more recent cohorts have yet to mature. Category performance is uneven, with two to three categories accounting for the majority of revenue concentration. The recommendations below target the highest-impact actions for next quarter.


## 1. Revenue Trends

### Overall Trajectory
Revenue grew on a month-over-month basis through most of the year, with the strongest absolute gains occurring in Q3 and Q4. Quarter-over-quarter growth rates ranged from approximately 8–18%, with the most pronounced acceleration in the back half of the year — consistent with typical e-commerce seasonality patterns around holiday periods.

### What Is Driving Growth?
Decomposing revenue into its components reveals that **order volume growth** — not average order value (AOV) — was the primary engine of revenue expansion. In months where revenue grew 10–15% MoM, order counts increased by a similar magnitude while AOV remained relatively flat (within ±5%). This suggests growth is coming from acquiring and activating more customers rather than extracting more value per transaction.

### Anomalies and Noise
The 7-day and 30-day moving averages reveal that raw daily revenue contains significant day-of-week noise — weekends and Mondays show consistent dips of 15–25% relative to mid-week peaks. After smoothing this variation away, the underlying trend line is more consistently positive than the volatile daily numbers suggest. Isolated spikes (days where revenue deviated >20% above the 7-day moving average) occurred during promotional windows and should be excluded from baseline growth assumptions.

### Key Finding
Revenue growth is real and consistent, but it is volume-driven. Without improvements to AOV or retention, maintaining this growth rate requires continuously expanding the top of the acquisition funnel — an increasingly expensive strategy.

---

## 2. Customer Retention

### Cohort Definitions
Cohorts are defined by the month of a customer's **first completed purchase** (not signup date). This distinction matters: customers who signed up months before making their first purchase are placed in the cohort matching their actual buying behavior, giving a more accurate picture of acquisition-channel effectiveness.

### Retention Rates by Cohort
Across all cohorts, 90-day repeat-purchase rates ranged from approximately **18% to 35%**. The top-performing cohorts — typically those acquired in Q1 and Q2 — retained about one-in-three customers within 90 days. The weakest cohorts, concentrated in Q3 and Q4, retained fewer than one-in-five, though these cohorts are also the youngest and may not yet have had the full 90-day window to convert.

**30-day retention** averaged approximately 12–15% across cohorts. **60-day retention** showed a material jump to 20–25%, indicating that many customers who do return are doing so in the 31–60-day window — likely driven by repeat-need purchasing cycles or email reactivation.

### Cohort Trends
The period-over-period change in retention rates (month-over-month delta in the 90-day retention %) shows no strong directional trend — retention rates oscillate within a narrow band rather than improving or degrading systematically. This suggests that whatever is driving repeat purchases has remained roughly constant, and that no significant change in product, pricing, or lifecycle marketing has shifted behavior.

### Key Finding
Retention is not declining — but it is not improving either. The business is not systematically getting better at converting first-time buyers into repeat customers. Even a 5-percentage-point improvement in 90-day retention across all cohorts would materially reduce the revenue dependence on new customer acquisition.


---

## 3. Category Performance

### Revenue Concentration
Category-level analysis shows significant revenue concentration. The top two or three categories (by cumulative revenue) consistently capture 55–65% of total revenue each month. This concentration has remained relatively stable over the year — no dramatic category reshuffling has occurred — which suggests both category-specific demand stability and potentially an underdeveloped long-tail.

### Share Trends
The 30-day moving average by category reveals that while overall revenue grew, not all categories participated equally. One or two categories have seen their daily revenue moving averages trend upward over the year, while others have remained flat or drifted slightly downward in absolute terms. In share terms (% of total daily revenue), the top categories have slightly compressed smaller categories — meaning category mix is gradually concentrating, not diversifying.

### Daily Rank Volatility
Day-level category rankings show moderate volatility: categories occasionally surge to #1 during promotions or inventory events, then revert. The 30-day MA normalizes these spikes and gives a cleaner view of structural performance. Categories that rank highly on both raw revenue and moving average are the structural anchors of the business.

### Key Finding
Category mix is concentrating, not diversifying. Two or three categories drive the majority of revenue, and their share appears to be growing at the expense of smaller categories. This creates strategic dependency risk — a supply or margin problem in a top category would have outsized business impact.


---

## 4. Recommendations

Based on the three areas of analysis above, the following actions are recommended for next quarter, ranked by estimated impact:

### Recommendation 1 — Launch a Post-First-Purchase Retention Program
**Priority: High**  
The data shows that the 31–60-day window is when most repeat purchases occur. The business currently has no evidence of systematic lifecycle intervention in this window. A targeted email or SMS sequence triggered 2–4 weeks after first purchase — personalized to the category of the first order — is likely to move 60-day and 90-day retention rates. Even a 3–5 percentage point improvement in 90-day retention across the customer base would generate meaningful incremental revenue without increasing acquisition spend.

### Recommendation 2 — Investigate AOV Improvement Levers
**Priority: Medium-High**  
Revenue growth is almost entirely volume-driven. AOV has not grown materially even as order counts increased. This points to an untapped opportunity in bundling, upsell prompts at checkout, or cross-category recommendations. A 5–8% increase in AOV — achievable through product recommendation improvements or minimum-spend incentives — would compound directly on top of volume growth.

### Recommendation 3 — Reduce Category Concentration Risk
**Priority: Medium**  
The business currently relies heavily on two or three categories. Allocating incremental marketing budget to growing mid-tier categories — those with positive moving average trends but low share — would reduce dependency risk and open new customer acquisition segments. This is a longer-term play but one that should begin next quarter.

### Recommendation 4 — Define Acquisition Channel Tracking by Cohort
**Priority: Medium**  
The current data does not include acquisition channel information at the customer level. As a result, it is impossible to determine whether high-retention cohorts were acquired through organic, paid, referral, or promotional channels. Connecting cohort retention data to acquisition channel in the data model would allow the BI team to identify which channels produce the most valuable customers — not just the most customers — and redirect budget accordingly. This is a data infrastructure recommendation, not a marketing one, but it would unlock a significantly higher-value analytical capability within one quarter.

---

## Appendix — Data Notes

- All revenue figures exclude cancelled orders (`status != 'cancelled'`).
- `order_items.unit_price` is used for revenue calculations (price at time of purchase), not the current list price in `products`.
- Cohort assignment is based on first completed purchase date, not customer signup date.
- Moving averages use a trailing window (e.g., 7-day MA on day N includes days N-6 through N), so the first 6 days of the dataset have partial windows.
- Retention percentages for cohorts in the final 1–2 months of the dataset should be interpreted cautiously, as those cohorts have not yet had a full 90-day observation window.
