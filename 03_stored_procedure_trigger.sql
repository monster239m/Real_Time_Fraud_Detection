-- ============================================================
-- FILE : 03_stored_procedure_trigger.sql
--        Fraud Risk Scoring Procedure + Auto-Flag Trigger
-- ============================================================
USE fraud_detection;

DELIMITER $$

-- ============================================================
-- STORED PROCEDURE: calculate_risk_score
-- Computes a 0-100 risk score based on 3 rules:
--   Rule 1 (+40 pts) – Amount > 3x user's historical average
--   Rule 2 (+35 pts) – Transaction between 12 AM and 5 AM
--   Rule 3 (+50 pts) – Country differs from user's home country
-- Returns the final score via OUT parameter
-- ============================================================
DROP PROCEDURE IF EXISTS calculate_risk_score$$

CREATE PROCEDURE calculate_risk_score(
    IN  p_user_id   INT,
    IN  p_amount    DECIMAL(12,2),
    IN  p_country   VARCHAR(80),
    IN  p_txn_time  DATETIME,
    OUT p_score     TINYINT UNSIGNED
)
BEGIN
    DECLARE v_avg_amount   DECIMAL(12,2);
    DECLARE v_home_country VARCHAR(80);
    DECLARE v_hour         TINYINT;
    DECLARE v_score        INT DEFAULT 0;

    -- Fetch user baseline data
    SELECT avg_txn_amount, country
    INTO   v_avg_amount, v_home_country
    FROM   users
    WHERE  user_id = p_user_id;

    -- Rule 1: Amount anomaly (transaction > 3× personal average)
    IF p_amount > (v_avg_amount * 3) THEN
        SET v_score = v_score + 40;
    ELSEIF p_amount > (v_avg_amount * 2) THEN
        SET v_score = v_score + 20;
    END IF;

    -- Rule 2: Odd-hours transaction (midnight to 5 AM)
    SET v_hour = HOUR(p_txn_time);
    IF v_hour >= 0 AND v_hour < 5 THEN
        SET v_score = v_score + 35;
    END IF;

    -- Rule 3: Foreign country transaction
    IF p_country <> v_home_country THEN
        SET v_score = v_score + 50;
    END IF;

    -- Cap score at 100
    IF v_score > 100 THEN
        SET v_score = 100;
    END IF;

    SET p_score = v_score;
END$$

-- ============================================================
-- TRIGGER: trg_before_txn_insert
-- Fires BEFORE every INSERT into transactions.
-- 1. Calls calculate_risk_score to compute the score.
-- 2. Sets NEW.risk_score and NEW.status automatically.
-- 3. Writes to fraud_logs and audit_trail when score >= 70.
-- ============================================================
DROP TRIGGER IF EXISTS trg_before_txn_insert$$

CREATE TRIGGER trg_before_txn_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_score     TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_reason    VARCHAR(255) DEFAULT '';

    -- Step 1: Get risk score
    CALL calculate_risk_score(
        NEW.user_id,
        NEW.amount,
        NEW.country,
        NEW.txn_time,
        v_score
    );

    -- Step 2: Assign computed score back to the row
    SET NEW.risk_score = v_score;

    -- Step 3: Determine status based on score thresholds
    IF v_score >= 90 THEN
        SET NEW.status = 'BLOCKED';
        SET v_reason   = CONCAT('HIGH RISK (score=', v_score,
                                '): Amount ₹', NEW.amount,
                                ' | Country: ', NEW.country,
                                ' | Time: ', NEW.txn_time);
    ELSEIF v_score >= 70 THEN
        SET NEW.status = 'FLAGGED';
        SET v_reason   = CONCAT('MODERATE RISK (score=', v_score,
                                '): Amount ₹', NEW.amount,
                                ' | Country: ', NEW.country,
                                ' | Time: ', NEW.txn_time);
    ELSE
        SET NEW.status = 'APPROVED';
    END IF;

    -- Step 4: Write to audit_trail for every transaction
    INSERT INTO audit_trail (event_type, user_id, message)
    VALUES (
        'TRIGGER_FIRED',
        NEW.user_id,
        CONCAT('txn evaluated | score=', v_score,
               ' | status=', NEW.status,
               ' | merchant=', NEW.merchant)
    );

    -- Step 5: If risky, write to immutable fraud_logs
    IF v_score >= 70 THEN
        INSERT INTO fraud_logs (txn_id, user_id, risk_score, fraud_reason)
        VALUES (NULL, NEW.user_id, v_score, v_reason);
        -- Note: txn_id is NULL here because the txn hasn't been committed yet.
        -- A follow-up UPDATE links them (see 04_queries.sql).
    END IF;

END$$

DELIMITER ;

SELECT 'Stored procedure and trigger created successfully.' AS Status;
