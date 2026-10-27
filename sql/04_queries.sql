-- ============================================================
-- FILE : 04_queries.sql
--        All Core SQL Queries – Window Functions, CTEs,
--        Views, Geo-Velocity, Indexing & EXPLAIN
-- ============================================================
USE fraud_detection;

-- ============================================================
-- QUERY 1: Basic Fraud Summary – All Flagged / Blocked Txns
-- ============================================================
SELECT
    t.txn_id,
    u.full_name,
    t.amount,
    t.merchant,
    t.city,
    t.country,
    t.txn_time,
    t.status,
    t.risk_score
FROM transactions t
JOIN users u ON t.user_id = u.user_id
WHERE t.status IN ('FLAGGED', 'BLOCKED')
ORDER BY t.risk_score DESC;

-- ============================================================
-- QUERY 2: Window Function – Rolling Average Spend per User
--          LAG: previous transaction amount
--          AVG OVER: rolling average of last 5 transactions
-- ============================================================
SELECT
    txn_id,
    user_id,
    amount,
    txn_time,
    LAG(amount, 1) OVER (
        PARTITION BY user_id
        ORDER BY txn_time
    )                                   AS prev_txn_amount,
    ROUND(AVG(amount) OVER (
        PARTITION BY user_id
        ORDER BY txn_time
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ), 2)                               AS rolling_avg_5,
    ROUND(amount - AVG(amount) OVER (
        PARTITION BY user_id
        ORDER BY txn_time
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ), 2)                               AS deviation_from_avg
FROM transactions
ORDER BY user_id, txn_time;

-- ============================================================
-- QUERY 3: Window Function – RANK users by total spend
-- ============================================================
SELECT
    u.full_name,
    COUNT(t.txn_id)                        AS total_transactions,
    ROUND(SUM(t.amount), 2)               AS total_spent,
    ROUND(AVG(t.amount), 2)               AS avg_spent,
    RANK() OVER (ORDER BY SUM(t.amount) DESC) AS spend_rank
FROM transactions t
JOIN users u ON t.user_id = u.user_id
GROUP BY t.user_id, u.full_name
ORDER BY spend_rank;

-- ============================================================
-- QUERY 4: CTE – Detect Velocity Fraud
--          Users with 3+ transactions within any 30-minute window
-- ============================================================
WITH txn_velocity AS (
    SELECT
        t1.user_id,
        t1.txn_id                            AS txn_id_1,
        t2.txn_id                            AS txn_id_2,
        t1.txn_time                          AS time_1,
        t2.txn_time                          AS time_2,
        TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) AS minutes_gap,
        t1.amount                            AS amt_1,
        t2.amount                            AS amt_2
    FROM transactions t1
    JOIN transactions t2
        ON  t1.user_id  = t2.user_id
        AND t2.txn_id   > t1.txn_id
        AND TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) <= 30
)
SELECT
    v.user_id,
    u.full_name,
    COUNT(*) AS suspicious_pairs,
    MIN(v.minutes_gap) AS min_gap_minutes
FROM txn_velocity v
JOIN users u ON v.user_id = u.user_id
GROUP BY v.user_id, u.full_name
HAVING suspicious_pairs >= 2
ORDER BY suspicious_pairs DESC;

-- ============================================================
-- QUERY 5: Geo-Velocity Detection using Haversine Formula
--          Flags txn pairs where travel speed > 900 km/h
--          (max commercial aircraft speed ~900 km/h)
-- ============================================================
WITH geo_pairs AS (
    SELECT
        t1.user_id,
        t1.txn_id                          AS txn_id_1,
        t2.txn_id                          AS txn_id_2,
        t1.city                            AS city_1,
        t2.city                            AS city_2,
        t1.txn_time                        AS time_1,
        t2.txn_time                        AS time_2,
        TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) AS minutes_apart,
        -- Haversine formula (distance in km)
        ROUND(
            6371 * 2 * ASIN(SQRT(
                POW(SIN(RADIANS(t2.latitude  - t1.latitude)  / 2), 2)
              + COS(RADIANS(t1.latitude))
              * COS(RADIANS(t2.latitude))
              * POW(SIN(RADIANS(t2.longitude - t1.longitude) / 2), 2)
            ))
        , 2)                               AS distance_km
    FROM transactions t1
    JOIN transactions t2
        ON  t1.user_id = t2.user_id
        AND t2.txn_id  > t1.txn_id
        AND t1.city   <> t2.city
        AND TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) BETWEEN 1 AND 180
)
SELECT
    gp.user_id,
    u.full_name,
    gp.city_1,
    gp.city_2,
    gp.distance_km,
    gp.minutes_apart,
    ROUND(gp.distance_km / (gp.minutes_apart / 60.0), 2) AS implied_speed_kmh,
    CASE
        WHEN gp.distance_km / (gp.minutes_apart / 60.0) > 900
        THEN '🚨 IMPOSSIBLE TRAVEL'
        WHEN gp.distance_km / (gp.minutes_apart / 60.0) > 500
        THEN '⚠️ SUSPICIOUS TRAVEL'
        ELSE '✅ NORMAL'
    END                                    AS geo_verdict
FROM geo_pairs gp
JOIN users u ON gp.user_id = u.user_id
ORDER BY implied_speed_kmh DESC;

-- ============================================================
-- QUERY 6: VIEW – Suspicious Transactions (reusable)
-- ============================================================
CREATE OR REPLACE VIEW vw_suspicious_transactions AS
SELECT
    t.txn_id,
    u.full_name,
    u.city       AS home_city,
    t.city       AS txn_city,
    t.country,
    t.amount,
    t.merchant,
    t.category,
    t.txn_time,
    t.status,
    t.risk_score
FROM transactions t
JOIN users u ON t.user_id = u.user_id
WHERE t.status IN ('FLAGGED', 'BLOCKED');

-- Use the view:
SELECT * FROM vw_suspicious_transactions ORDER BY risk_score DESC;

-- ============================================================
-- QUERY 7: VIEW – User Risk Profile (per-user summary)
-- ============================================================
CREATE OR REPLACE VIEW vw_user_risk_profile AS
SELECT
    u.user_id,
    u.full_name,
    u.avg_txn_amount                        AS baseline_avg,
    COUNT(t.txn_id)                         AS total_txns,
    SUM(CASE WHEN t.status='APPROVED' THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN t.status='FLAGGED'  THEN 1 ELSE 0 END) AS flagged_count,
    SUM(CASE WHEN t.status='BLOCKED'  THEN 1 ELSE 0 END) AS blocked_count,
    ROUND(MAX(t.risk_score), 0)             AS max_risk_score,
    ROUND(AVG(t.risk_score), 1)             AS avg_risk_score,
    CASE
        WHEN MAX(t.risk_score) >= 90 THEN 'HIGH RISK'
        WHEN MAX(t.risk_score) >= 70 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END                                     AS risk_category
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id
GROUP BY u.user_id, u.full_name, u.avg_txn_amount;

-- Use the view:
SELECT * FROM vw_user_risk_profile ORDER BY max_risk_score DESC;

-- ============================================================
-- QUERY 8: Fraud Logs – Full audit report
-- ============================================================
SELECT
    fl.log_id,
    fl.txn_id,
    u.full_name,
    fl.risk_score,
    fl.fraud_reason,
    fl.detected_at,
    fl.reviewed
FROM fraud_logs fl
JOIN users u ON fl.user_id = u.user_id
ORDER BY fl.risk_score DESC;

-- ============================================================
-- QUERY 9: EXPLAIN – Before index (Sequential Scan simulation)
-- ============================================================
EXPLAIN
SELECT * FROM transactions WHERE status = 'FLAGGED';

-- ============================================================
-- QUERY 10: Create optimised composite index & re-run EXPLAIN
-- ============================================================
-- Drop old index if re-running this script
DROP INDEX IF EXISTS idx_status_risk ON transactions;

CREATE INDEX idx_status_risk
    ON transactions (status, risk_score DESC);

-- Now EXPLAIN should show "Using index" instead of full scan
EXPLAIN
SELECT * FROM transactions
WHERE status = 'FLAGGED'
ORDER BY risk_score DESC;

-- ============================================================
-- QUERY 11: Category-wise fraud analysis
-- ============================================================
SELECT
    t.category,
    COUNT(*)                         AS total_txns,
    SUM(CASE WHEN status='FLAGGED'  THEN 1 ELSE 0 END) AS flagged,
    SUM(CASE WHEN status='BLOCKED'  THEN 1 ELSE 0 END) AS blocked,
    ROUND(AVG(t.amount), 2)         AS avg_amount,
    ROUND(MAX(t.amount), 2)         AS max_amount
FROM transactions t
GROUP BY t.category
ORDER BY (flagged + blocked) DESC;

-- ============================================================
-- QUERY 12: Test trigger – Insert a suspicious transaction
--           (foreign country + odd hour + high amount)
--           Trigger should auto-compute risk & set status
-- ============================================================
INSERT INTO transactions
    (user_id, amount, merchant, category, city, country, latitude, longitude, txn_time)
VALUES
    (3, 75000.00, 'Paris Boutique', 'luxury', 'Paris', 'France', 48.8566, 2.3522,
     '2026-10-25 03:00:00');

-- Verify the trigger auto-flagged/blocked it:
SELECT txn_id, user_id, amount, merchant, country, txn_time, status, risk_score
FROM transactions
WHERE merchant = 'Paris Boutique';

SELECT 'All queries executed successfully.' AS Status;
