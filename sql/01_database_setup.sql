/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 01_database_setup.sql
   Database: MySQL
   Objective: Initialize the database and raw data table
   Dataset: LendingClub Accepted Loans (2007-2018)
   ===================================================== */


-- 1. Create the project database

CREATE DATABASE IF NOT EXISTS credit_risk_portfolio;

USE credit_risk_portfolio;


-- 2. Create the raw loan data table
-- Retain 17 relevant fields from the original 151 columns
-- to support credit risk and portfolio analysis.

CREATE TABLE IF NOT EXISTS lendingclub_raw (
    id VARCHAR(30) DEFAULT NULL,
    loan_amnt DECIMAL(12,2) DEFAULT NULL,
    term VARCHAR(20) DEFAULT NULL,
    int_rate VARCHAR(20) DEFAULT NULL,
    installment DECIMAL(12,2) DEFAULT NULL,
    grade VARCHAR(5) DEFAULT NULL,
    sub_grade VARCHAR(5) DEFAULT NULL,
    annual_inc DECIMAL(15,2) DEFAULT NULL,
    dti DECIMAL(10,2) DEFAULT NULL,
    loan_status VARCHAR(50) DEFAULT NULL,
    issue_d VARCHAR(20) DEFAULT NULL,
    fico_range_low INT DEFAULT NULL,
    recoveries DECIMAL(15,2) DEFAULT NULL,
    total_rec_prncp DECIMAL(15,2) DEFAULT NULL,
    purpose VARCHAR(100) DEFAULT NULL,
    home_ownership VARCHAR(30) DEFAULT NULL,
    verification_status VARCHAR(50) DEFAULT NULL
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;


-- 3. Verify database creation

SELECT DATABASE();


-- 4. Verify table structure

DESCRIBE lendingclub_raw;


-- 5. Verify the number of retained columns
-- Expected result: 17

SELECT
    COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'credit_risk_portfolio'
  AND table_name = 'lendingclub_raw';
