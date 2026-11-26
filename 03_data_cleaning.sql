/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 03_data_cleaning.sql
   Database: MySQL 8.0+
   Dataset: LendingClub Accepted Loans (2007-2018)
   Objective: Clean raw loan records and validate data quality

   Prerequisites:
   01_database_setup.sql
   02_data_import.sql
   ===================================================== */


USE credit_risk_portfolio;


-- =====================================================
-- 1. Inspect Raw Data
-- =====================================================

SELECT *
FROM lendingclub_raw
LIMIT 10;


-- =====================================================
-- 2. Identify Invalid Records
-- =====================================================

SELECT
    COUNT(*) AS total_raw_records,
    SUM(loan_amnt IS NULL) AS missing_loan_amount,
    SUM(loan_amnt <= 0) AS invalid_loan_amount,
    SUM(id IS NULL) AS missing_id,
    SUM(id NOT REGEXP '^[0-9]+$') AS non_numeric_id
FROM lendingclub_raw;


-- Inspect records that fail the cleaning criteria.

SELECT *
FROM lendingclub_raw
WHERE loan_amnt IS NULL
    OR loan_amnt <= 0
    OR id IS NULL
    OR id NOT REGEXP '^[0-9]+$';


-- Check for duplicate IDs among valid raw records.
-- Expected result: No rows returned.
-- Investigate duplicates before proceeding if any exist.

SELECT
    id,
    COUNT(*) AS duplicate_count
FROM lendingclub_raw
WHERE loan_amnt IS NOT NULL
    AND loan_amnt > 0
    AND id REGEXP '^[0-9]+$'
GROUP BY id
HAVING COUNT(*) > 1;


-- =====================================================
-- 3. Create Clean Table
-- =====================================================

CREATE TABLE IF NOT EXISTS lendingclub_clean
LIKE lendingclub_raw;


-- =====================================================
-- 4. Insert Valid Loan Records
-- =====================================================

-- Cleaning criteria:
-- 1. Loan amount must not be NULL.
-- 2. Loan amount must be greater than zero.
-- 3. Loan ID must contain only numeric characters.
--
-- Assumes valid raw loan IDs are unique.
-- Existing clean records are retained.
-- This is an insert-only process, not a full refresh.

INSERT INTO lendingclub_clean
SELECT r.*
FROM lendingclub_raw AS r
WHERE r.loan_amnt IS NOT NULL
    AND r.loan_amnt > 0
    AND r.id REGEXP '^[0-9]+$'
    AND NOT EXISTS (
        SELECT 1
        FROM lendingclub_clean AS c
        WHERE c.id = r.id
    );


-- =====================================================
-- 5. Validate Cleaned Loan Data
-- =====================================================

SELECT
    COUNT(*) AS total_loans,
    COUNT(DISTINCT id) AS unique_loan_ids,
    COUNT(*) - COUNT(DISTINCT id) AS duplicate_rows,
    SUM(loan_amnt IS NULL) AS missing_loan_amount,
    SUM(loan_amnt <= 0) AS invalid_loan_amount,
    SUM(
        CASE
            WHEN id IS NULL
                OR id NOT REGEXP '^[0-9]+$'
            THEN 1
            ELSE 0
        END
    ) AS invalid_loan_id
FROM lendingclub_clean;


-- =====================================================
-- 6. Compare Raw and Clean Record Counts
-- =====================================================

WITH raw_summary AS (
    SELECT COUNT(*) AS raw_records
    FROM lendingclub_raw
),

clean_summary AS (
    SELECT COUNT(*) AS clean_records
    FROM lendingclub_clean
)

SELECT
    r.raw_records,
    c.clean_records,
    r.raw_records - c.clean_records AS removed_records,
    ROUND(
        100.0 * c.clean_records
        / NULLIF(r.raw_records, 0),
        4
    ) AS data_retention_rate
FROM raw_summary AS r
CROSS JOIN clean_summary AS c;


-- =====================================================
-- 7. Expected Cleaning Results
-- =====================================================

-- Raw records:             2,260,701
-- Clean records:           2,260,668
-- Removed records:                33
-- Unique loan IDs:         2,260,668
-- Duplicate rows:                  0
-- Missing loan amounts:            0
-- Invalid loan amounts:            0
-- Invalid loan IDs:                0
-- Data retention rate:      99.9985%