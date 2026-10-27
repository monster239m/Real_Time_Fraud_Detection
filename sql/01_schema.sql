-- ============================================================
-- PROJECT  : Real-Time Fraud & Anomaly Detection Engine
-- SUBJECT  : Database Management System (DBMS)
-- DATABASE : MySQL 8.0
-- FILE     : 01_schema.sql  –  Database & Table Creation
-- ============================================================

-- 1. Create & select the database
DROP DATABASE IF EXISTS fraud_detection;
CREATE DATABASE fraud_detection
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE fraud_detection;

-- ============================================================
-- TABLE 1: users
-- Stores registered user profiles
-- ============================================================
CREATE TABLE users (
    user_id       INT            NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100)   NOT NULL,
    email         VARCHAR(150)   NOT NULL UNIQUE,
    phone         VARCHAR(15),
    city          VARCHAR(80)    NOT NULL,
    country       VARCHAR(80)    NOT NULL DEFAULT 'India',
    latitude      DECIMAL(9,6)   NOT NULL COMMENT 'Home city latitude',
    longitude     DECIMAL(9,6)   NOT NULL COMMENT 'Home city longitude',
    avg_txn_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Historical average spend',
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE 2: transactions
-- Every financial transaction attempted by a user
-- ============================================================
CREATE TABLE transactions (
    txn_id        BIGINT         NOT NULL AUTO_INCREMENT,
    user_id       INT            NOT NULL,
    amount        DECIMAL(12,2)  NOT NULL,
    merchant      VARCHAR(150)   NOT NULL,
    category      VARCHAR(80)    NOT NULL
                  COMMENT 'e.g. food, travel, electronics, atm',
    city          VARCHAR(80)    NOT NULL,
    country       VARCHAR(80)    NOT NULL DEFAULT 'India',
    latitude      DECIMAL(9,6)   NOT NULL,
    longitude     DECIMAL(9,6)   NOT NULL,
    txn_time      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        ENUM('APPROVED','FLAGGED','BLOCKED')
                  NOT NULL DEFAULT 'APPROVED',
    risk_score    TINYINT UNSIGNED NOT NULL DEFAULT 0
                  COMMENT '0-100; >=70 flagged, >=90 blocked',
    PRIMARY KEY (txn_id),
    INDEX idx_user_time   (user_id, txn_time),
    INDEX idx_status      (status),
    INDEX idx_flagged     (status, txn_time)  -- partial-style composite
        COMMENT 'Optimised for FLAGGED queries',
    CONSTRAINT fk_txn_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABLE 3: fraud_logs
-- Immutable audit/quarantine table – records never deleted
-- ============================================================
CREATE TABLE fraud_logs (
    log_id        BIGINT         NOT NULL AUTO_INCREMENT,
    txn_id        BIGINT         NOT NULL,
    user_id       INT            NOT NULL,
    risk_score    TINYINT UNSIGNED NOT NULL,
    fraud_reason  VARCHAR(255)   NOT NULL,
    detected_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed      BOOLEAN        NOT NULL DEFAULT FALSE,
    PRIMARY KEY (log_id),
    INDEX idx_fraud_user (user_id),
    INDEX idx_fraud_time (detected_at)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE 4: audit_trail
-- Tracks every trigger / procedure action for accountability
-- ============================================================
CREATE TABLE audit_trail (
    audit_id      BIGINT         NOT NULL AUTO_INCREMENT,
    event_type    VARCHAR(80)    NOT NULL
                  COMMENT 'e.g. TRIGGER_FIRED, PROC_CALLED',
    txn_id        BIGINT,
    user_id       INT,
    message       TEXT,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (audit_id)
) ENGINE=InnoDB;

SELECT 'Schema created successfully.' AS Status;
