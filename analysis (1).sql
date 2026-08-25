-- ============================================================
-- The Last-Touch Trap — Paid Social Attribution Analysis
-- ============================================================
-- Question: is Paid Social really underperforming, or is
-- last-touch attribution just hiding its role in the funnel?
-- ============================================================

-- ----------------------------------------------------------
-- Step 1: Setup — database and tables
-- ----------------------------------------------------------
CREATE DATABASE LAST_TOUCH_TRAP;
USE LAST_TOUCH_TRAP;

CREATE TABLE CONVERSIONS (
    customer_id  VARCHAR(20),
    converted_at DATETIME,
    plan         VARCHAR(20),
    amount_usd   INT
);

CREATE TABLE TOUCHES (
    customer_id VARCHAR(20),
    touch_ts    DATETIME,
    channel     VARCHAR(30),
    campaign    VARCHAR(50),
    device      VARCHAR(20)
);

-- Load conversions.csv into CONVERSIONS and touches.csv into TOUCHES
-- (via LOAD DATA INFILE or the MySQL Workbench import wizard)


-- ----------------------------------------------------------
-- Step 2: Sanity checks on raw conversions
-- ----------------------------------------------------------

-- Total conversion rows on record (includes resubscribes)
SELECT COUNT(*) FROM CONVERSIONS;                       -- 6422

-- Unique converting customers
SELECT COUNT(DISTINCT customer_id) FROM CONVERSIONS;    -- 5939

-- Number of resubscribe rows (duplicate customers)
SELECT COUNT(*) - COUNT(DISTINCT customer_id)
FROM CONVERSIONS;                                       -- 483


-- ----------------------------------------------------------
-- Step 3: Dedupe conversions — keep each customer's FIRST
-- conversion only (per the brief: resubscribes are dupes)
-- ----------------------------------------------------------
CREATE TEMPORARY TABLE deduped_conversions AS
SELECT customer_id, MIN(converted_at) AS first_converted_at
FROM CONVERSIONS
GROUP BY customer_id;

SELECT COUNT(*) FROM deduped_conversions;                -- 5939 (Q2 answer)


-- ----------------------------------------------------------
-- Step 4: Attach qualifying touches — 30-day attribution
-- window, touch must be at or before the conversion
-- ----------------------------------------------------------
CREATE TEMPORARY TABLE qualifying_touches AS
SELECT t.customer_id, t.touch_ts, t.channel, dc.first_converted_at
FROM TOUCHES t
JOIN deduped_conversions dc ON t.customer_id = dc.customer_id
WHERE t.touch_ts <= dc.first_converted_at
  AND t.touch_ts >= dc.first_converted_at - INTERVAL 30 DAY;

SELECT COUNT(*) FROM qualifying_touches;                 -- 20533


-- ----------------------------------------------------------
-- Step 5: Last-touch attribution
-- (the LATEST qualifying touch per customer gets full credit)
-- ----------------------------------------------------------
SELECT channel, COUNT(*) AS conversions
FROM (
    SELECT customer_id, channel,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY touch_ts DESC) AS rn
    FROM qualifying_touches
) ranked
WHERE rn = 1
GROUP BY channel
ORDER BY conversions DESC;

-- Result:
-- brand_search     2055
-- retargeting      1423
-- direct            719
-- email             677
-- organic_search    464
-- referral          264
-- paid_social       173   <-- Q1: Brand Search wins; Paid Social = 2.9%
-- youtube            106
-- display             58

-- Paid Social last-touch share (Q3)
SELECT ROUND(173 / 5939 * 100, 1) AS paid_social_last_touch_pct;   -- 2.9%


-- ----------------------------------------------------------
-- Step 6: First-touch attribution
-- (the EARLIEST qualifying touch per customer gets full credit)
-- ----------------------------------------------------------
SELECT channel, COUNT(*) AS conversions
FROM (
    SELECT customer_id, channel,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY touch_ts ASC) AS rn
    FROM qualifying_touches
) ranked
WHERE rn = 1
GROUP BY channel
ORDER BY conversions DESC;

-- Paid Social first-touch count = 1621

-- Paid Social first-touch share (Q4)
SELECT ROUND(1621 / 5939 * 100, 1) AS paid_social_first_touch_pct;  -- 27.3%


-- ============================================================
-- Summary
-- ============================================================
-- Metric                         | Paid Social
-- --------------------------------|------------
-- Last-touch share (Q3)          | 2.9%
-- First-touch share (Q4)         | 27.3%
--
-- ~9x gap between the two models. Paid Social rarely closes
-- the sale, but originates roughly 1 in 4 converting customer
-- journeys — a discovery/top-of-funnel channel that last-touch
-- systematically undercredits.
-- ============================================================
