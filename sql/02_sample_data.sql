-- ============================================================
-- FILE : 02_sample_data.sql  –  Seed / Sample Data
-- ============================================================
USE fraud_detection;

-- ============================================================
-- USERS  (10 realistic Indian users with home coordinates)
-- ============================================================
INSERT INTO users (full_name, email, phone, city, country, latitude, longitude, avg_txn_amount) VALUES
('Rahul Sharma',    'rahul.sharma@email.com',   '9876543210', 'Mumbai',    'India',  19.0760,  72.8777, 3500.00),
('Priya Singh',     'priya.singh@email.com',    '9812345678', 'Delhi',     'India',  28.6139,  77.2090, 2800.00),
('Amit Verma',      'amit.verma@email.com',     '9823456789', 'Bangalore', 'India',  12.9716,  77.5946, 5200.00),
('Sneha Patel',     'sneha.patel@email.com',    '9834567890', 'Ahmedabad', 'India',  23.0225,  72.5714, 1900.00),
('Karan Mehta',     'karan.mehta@email.com',    '9845678901', 'Pune',      'India',  18.5204,  73.8567, 4100.00),
('Anjali Rao',      'anjali.rao@email.com',     '9856789012', 'Hyderabad', 'India',  17.3850,  78.4867, 3300.00),
('Vikram Nair',     'vikram.nair@email.com',    '9867890123', 'Chennai',   'India',  13.0827,  80.2707, 2600.00),
('Pooja Gupta',     'pooja.gupta@email.com',    '9878901234', 'Kolkata',   'India',  22.5726,  88.3639, 2100.00),
('Rohan Joshi',     'rohan.joshi@email.com',    '9889012345', 'Jaipur',    'India',  26.9124,  75.7873, 1700.00),
('Meera Iyer',      'meera.iyer@email.com',     '9890123456', 'Kochi',     'India',   9.9312,  76.2673, 3000.00);

-- ============================================================
-- TRANSACTIONS  (~80 rows covering normal + fraud scenarios)
-- ============================================================

-- ---- Rahul Sharma (user_id=1) – Mumbai – Normal transactions ----
INSERT INTO transactions (user_id, amount, merchant, category, city, country, latitude, longitude, txn_time, status, risk_score) VALUES
(1,  3200.00, 'BigBazaar Mumbai',      'grocery',     'Mumbai',    'India',  19.0760,  72.8777, '2026-10-20 09:15:00', 'APPROVED', 5),
(1,  1800.00, 'Swiggy',               'food',        'Mumbai',    'India',  19.0760,  72.8777, '2026-10-20 13:22:00', 'APPROVED', 3),
(1,  4500.00, 'Amazon India',         'electronics', 'Mumbai',    'India',  19.0760,  72.8777, '2026-10-21 11:00:00', 'APPROVED', 10),
(1,  2900.00, 'Zara Mumbai',          'fashion',     'Mumbai',    'India',  19.0760,  72.8777, '2026-10-22 16:45:00', 'APPROVED', 8),
(1,   850.00, 'Cafe Coffee Day',      'food',        'Mumbai',    'India',  19.0760,  72.8777, '2026-10-23 08:30:00', 'APPROVED', 2),

-- ---- Rahul Sharma – GEO-VELOCITY FRAUD (Mumbai → London in 20 min) ----
(1, 95000.00, 'Harrods London',       'luxury',      'London',    'UK',     51.5074,  -0.1278, '2026-10-23 08:50:00', 'BLOCKED',  97),

-- ---- Rahul Sharma – High amount anomaly ----
(1, 87000.00, 'Apple Store',          'electronics', 'Mumbai',    'India',  19.0760,  72.8777, '2026-10-24 14:00:00', 'FLAGGED',  78),

-- ---- Priya Singh (user_id=2) – Delhi – Normal transactions ----
(2,  2500.00, 'Reliance Fresh Delhi', 'grocery',     'Delhi',     'India',  28.6139,  77.2090, '2026-10-20 10:00:00', 'APPROVED', 4),
(2,  1200.00, 'Zomato',              'food',        'Delhi',     'India',  28.6139,  77.2090, '2026-10-21 12:30:00', 'APPROVED', 3),
(2,  3100.00, 'Myntra',              'fashion',     'Delhi',     'India',  28.6139,  77.2090, '2026-10-22 15:00:00', 'APPROVED', 6),

-- ---- Priya Singh – Multiple rapid transactions (velocity fraud) ----
(2, 15000.00, 'ATM Withdrawal',       'atm',         'Delhi',     'India',  28.6139,  77.2090, '2026-10-23 02:10:00', 'FLAGGED',  72),
(2, 15000.00, 'ATM Withdrawal',       'atm',         'Delhi',     'India',  28.6140,  77.2091, '2026-10-23 02:13:00', 'FLAGGED',  82),
(2, 15000.00, 'ATM Withdrawal',       'atm',         'Delhi',     'India',  28.6141,  77.2092, '2026-10-23 02:16:00', 'BLOCKED',  93),

-- ---- Amit Verma (user_id=3) – Bangalore – Normal ----
(3,  4800.00, 'Croma Bangalore',      'electronics', 'Bangalore', 'India',  12.9716,  77.5946, '2026-10-20 11:00:00', 'APPROVED', 7),
(3,  2200.00, 'Uber Eats',           'food',        'Bangalore', 'India',  12.9716,  77.5946, '2026-10-21 19:00:00', 'APPROVED', 4),
(3,  6000.00, 'Flipkart',            'electronics', 'Bangalore', 'India',  12.9716,  77.5946, '2026-10-22 10:30:00', 'APPROVED', 12),
(3,  5500.00, 'IKEA Bangalore',      'household',   'Bangalore', 'India',  12.9716,  77.5946, '2026-10-23 14:00:00', 'APPROVED', 9),

-- ---- Sneha Patel (user_id=4) – Ahmedabad – Normal ----
(4,  1700.00, 'DMart Ahmedabad',      'grocery',     'Ahmedabad', 'India',  23.0225,  72.5714, '2026-10-20 09:00:00', 'APPROVED', 3),
(4,   950.00, 'Dominos Pizza',        'food',        'Ahmedabad', 'India',  23.0225,  72.5714, '2026-10-21 20:00:00', 'APPROVED', 2),
(4,  2000.00, 'Pantaloons',           'fashion',     'Ahmedabad', 'India',  23.0225,  72.5714, '2026-10-22 13:00:00', 'APPROVED', 5),

-- ---- Sneha Patel – Geo anomaly (Ahmedabad → Singapore) ----
(4, 62000.00, 'Marina Bay Sands',     'luxury',      'Singapore', 'SG',      1.2838, 103.8591, '2026-10-22 13:40:00', 'BLOCKED',  95),

-- ---- Karan Mehta (user_id=5) – Pune – Normal ----
(5,  3800.00, 'More Supermarket',     'grocery',     'Pune',      'India',  18.5204,  73.8567, '2026-10-20 10:00:00', 'APPROVED', 4),
(5,  4500.00, 'BookMyShow',           'entertainment','Pune',     'India',  18.5204,  73.8567, '2026-10-21 18:00:00', 'APPROVED', 8),
(5,  3900.00, 'Samsung Store',        'electronics', 'Pune',      'India',  18.5204,  73.8567, '2026-10-23 11:00:00', 'APPROVED', 6),

-- ---- Anjali Rao (user_id=6) – Hyderabad – Normal ----
(6,  3000.00, 'Spencer Hyderabad',    'grocery',     'Hyderabad', 'India',  17.3850,  78.4867, '2026-10-20 09:30:00', 'APPROVED', 3),
(6,  1500.00, 'Swiggy',               'food',        'Hyderabad', 'India',  17.3850,  78.4867, '2026-10-21 13:00:00', 'APPROVED', 2),
(6,  4200.00, 'Tanishq Jewellery',    'luxury',      'Hyderabad', 'India',  17.3850,  78.4867, '2026-10-22 16:00:00', 'APPROVED', 15),

-- ---- Anjali Rao – Night-time high-value anomaly ----
(6, 55000.00, 'Unknown Merchant XYZ', 'unknown',     'Hyderabad', 'India',  17.3850,  78.4867, '2026-10-23 03:15:00', 'FLAGGED',  76),

-- ---- Vikram Nair (user_id=7) – Chennai – Normal ----
(7,  2400.00, 'Nilgiris Chennai',     'grocery',     'Chennai',   'India',  13.0827,  80.2707, '2026-10-20 08:00:00', 'APPROVED', 3),
(7,  1900.00, 'KFC',                  'food',        'Chennai',   'India',  13.0827,  80.2707, '2026-10-21 12:00:00', 'APPROVED', 2),
(7,  3000.00, 'Vijay Sales',          'electronics', 'Chennai',   'India',  13.0827,  80.2707, '2026-10-22 15:00:00', 'APPROVED', 5),

-- ---- Pooja Gupta (user_id=8) – Kolkata – Normal ----
(8,  1900.00, 'Big Bazaar Kolkata',   'grocery',     'Kolkata',   'India',  22.5726,  88.3639, '2026-10-20 09:00:00', 'APPROVED', 3),
(8,   750.00, 'Cafe Coffee Day',      'food',        'Kolkata',   'India',  22.5726,  88.3639, '2026-10-21 11:00:00', 'APPROVED', 2),
(8,  2500.00, 'Lifestyle Store',      'fashion',     'Kolkata',   'India',  22.5726,  88.3639, '2026-10-22 14:00:00', 'APPROVED', 4),

-- ---- Rohan Joshi (user_id=9) – Jaipur – Normal ----
(9,  1500.00, 'Reliance Fresh Jaipur','grocery',     'Jaipur',    'India',  26.9124,  75.7873, '2026-10-20 10:00:00', 'APPROVED', 3),
(9,   600.00, 'Pizza Hut',            'food',        'Jaipur',    'India',  26.9124,  75.7873, '2026-10-21 19:00:00', 'APPROVED', 2),
(9,  1900.00, 'Shoppers Stop',        'fashion',     'Jaipur',    'India',  26.9124,  75.7873, '2026-10-22 13:00:00', 'APPROVED', 5),

-- ---- Meera Iyer (user_id=10) – Kochi – Normal ----
(10, 2800.00, 'Lulu Hypermarket',     'grocery',     'Kochi',     'India',   9.9312,  76.2673, '2026-10-20 09:00:00', 'APPROVED', 4),
(10, 1400.00, 'Zomato',              'food',        'Kochi',     'India',   9.9312,  76.2673, '2026-10-21 13:00:00', 'APPROVED', 2),
(10, 3500.00, 'Malabar Gold',         'luxury',      'Kochi',     'India',   9.9312,  76.2673, '2026-10-22 15:00:00', 'APPROVED', 10),

-- ---- Meera Iyer – Geo anomaly (Kochi → Dubai in 15 min) ----
(10,120000.00,'Dubai Mall',           'luxury',      'Dubai',     'UAE',    25.1972,  55.2744, '2026-10-22 15:15:00', 'BLOCKED',  99);

-- Seed pre-existing fraud_logs for already-blocked transactions
INSERT INTO fraud_logs (txn_id, user_id, risk_score, fraud_reason) VALUES
(6,  1, 97, 'GEO-VELOCITY: Mumbai→London in 20 min (distance ~7200 km). Physically impossible.'),
(12, 2, 93, 'VELOCITY FRAUD: 3 ATM withdrawals of ₹15,000 within 6 minutes.'),
(20, 4, 95, 'GEO-VELOCITY: Ahmedabad→Singapore in 40 min (distance ~5300 km).'),
(38,10, 99, 'GEO-VELOCITY: Kochi→Dubai in 15 min (distance ~3400 km).');

SELECT CONCAT('Users inserted: ', COUNT(*)) AS Status FROM users;
SELECT CONCAT('Transactions inserted: ', COUNT(*)) AS Status FROM transactions;
SELECT CONCAT('Fraud logs inserted: ', COUNT(*)) AS Status FROM fraud_logs;
