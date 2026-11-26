/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 04_data_validation.sql
   Database: MySQL 8.0+
   Dataset: LendingClub Accepted Loans (2007-2018)
   Objective: Validate data completeness, consistency,
              and business-rule compliance

   Prerequisite: 03_data_cleaning.sql
   ===================================================== */


USE credit_risk_portfolio;


-- =====================================================
-- 1. Core Field Completeness
-- =====================================================

SELECT
    COUNT(*) AS total_loans,
    SUM(id IS NULL) AS missing_id,
    SUM(loan_amnt IS NULL) AS missing_loan_amount,
    SUM(term IS NULL) AS missing_term,
    SUM(int_rate IS NULL) AS missing_interest_rate,
    SUM(grade IS NULL) AS missing_grade,
    SUM(annual_inc IS NULL) AS missing_annual_income,
    SUM(dti IS NULL) AS missing_dti,
    SUM(loan_status IS NULL) AS missing_loan_status,
    SUM(issue_d IS NULL) AS missing_issue_date,
    SUM(fico_range_low IS NULL) AS missing_fico,
    SUM(purpose IS NULL) AS missing_purpose
FROM lendingclub_clean;


-- =====================================================
-- 2. Loan Status Validation
-- =====================================================

SELECT
    DISTINCT loan_status
FROM lendingclub_clean
ORDER BY loan_status;


-- Identify unexpected loan statuses.

SELECT
    loan_status,
    COUNT(*) AS loan_count
FROM lendingclub_clean
WHERE loan_status IS NULL
    OR (
        loan_status NOT IN (
            'Fully Paid',
            'Charged Off',
            'Default',
            'Current',
            'Late (16-30 days)',
            'Late (31-120 days)',
            'In Grace Period'
        )
        AND loan_status NOT LIKE
            'Does not meet the credit policy%'
    )
GROUP BY loan_status;


-- =====================================================
-- 3. Credit Grade Validation
-- =====================================================

SELECT
    grade,
    COUNT(*) AS loan_count
FROM lendingclub_clean
GROUP BY grade
ORDER BY grade;


-- Identify missing or invalid credit grades.

SELECT
    COUNT(*) AS invalid_credit_grade
FROM lendingclub_clean
WHERE grade IS NULL
    OR grade NOT IN ('A', 'B', 'C', 'D', 'E', 'F', 'G');


-- =====================================================
-- 4. Loan Term Validation
-- =====================================================

SELECT
    TRIM(term) AS loan_term,
    COUNT(*) AS loan_count
FROM lendingclub_clean
GROUP BY TRIM(term)
ORDER BY loan_term;


-- Expected terms: 36 months and 60 months.

SELECT
    COUNT(*) AS invalid_loan_term
FROM lendingclub_clean
WHERE term IS NULL
    OR TRIM(term) NOT IN ('36 months', '60 months');


-- =====================================================
-- 5. Annual Income Validation
-- =====================================================

SELECT
    MIN(annual_inc) AS min_annual_income,
    MAX(annual_inc) AS max_annual_income,
    ROUND(AVG(annual_inc), 2) AS avg_annual_income,
    SUM(annual_inc IS NULL) AS missing_income,
    SUM(annual_inc = 0) AS zero_income,
    SUM(annual_inc < 0) AS negative_income
FROM lendingclub_clean;


-- Missing and non-positive income values are excluded
-- from income segmentation, not the entire portfolio.


-- =====================================================
-- 6. Debt-to-Income Ratio Validation
-- =====================================================

SELECT
    MIN(dti) AS min_dti,
    MAX(dti) AS max_dti,
    ROUND(AVG(dti), 2) AS avg_dti,
    SUM(dti IS NULL) AS missing_dti,
    SUM(dti < 0) AS negative_dti,
    SUM(dti = 0) AS zero_dti,
    SUM(dti > 100) AS dti_above_100
FROM lendingclub_clean;


-- Identify records excluded from DTI segmentation.
-- The 0-100 range is a project-defined analytical rule.

SELECT
    COUNT(*) AS excluded_dti_records,
    ROUND(
        COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM lendingclub_clean), 0),
        4
    ) AS excluded_dti_percentage
FROM lendingclub_clean
WHERE dti IS NULL
    OR dti < 0
    OR dti > 100;


-- =====================================================
-- 7. FICO Score Validation
-- =====================================================

SELECT
    MIN(fico_range_low) AS min_fico,
    MAX(fico_range_low) AS max_fico,
    ROUND(AVG(fico_range_low), 2) AS avg_fico,
    SUM(fico_range_low IS NULL) AS missing_fico,
    SUM(
        CASE
            WHEN fico_range_low NOT BETWEEN 300 AND 850
            THEN 1
            ELSE 0
        END
    ) AS invalid_fico
FROM lendingclub_clean;


-- =====================================================
-- 8. Loan Amount Validation
-- =====================================================

SELECT
    MIN(loan_amnt) AS min_loan_amount,
    MAX(loan_amnt) AS max_loan_amount,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    SUM(loan_amnt) AS total_original_loan_amount
FROM lendingclub_clean;


-- Original loan amount represents originated principal,
-- not current outstanding exposure or EAD.


-- =====================================================
-- 9. Interest Rate Validation
-- =====================================================

SELECT
    COUNT(*) AS invalid_interest_rate_format
FROM lendingclub_clean
WHERE int_rate IS NULL
    OR TRIM(int_rate) NOT REGEXP '^[0-9]+([.][0-9]+)?$';


SELECT
    MIN(CAST(int_rate AS DECIMAL(5,2))) AS min_interest_rate,
    MAX(CAST(int_rate AS DECIMAL(5,2))) AS max_interest_rate,
    ROUND(
        AVG(CAST(int_rate AS DECIMAL(5,2))),
        2
    ) AS avg_interest_rate
FROM lendingclub_clean
WHERE TRIM(int_rate) REGEXP '^[0-9]+([.][0-9]+)?$';


-- =====================================================
-- 10. Origination Date Validation
-- =====================================================

WITH date_validation AS (
    SELECT
        STR_TO_DATE(
            CONCAT('01-', issue_d),
            '%d-%b-%Y'
        ) AS issue_date
    FROM lendingclub_clean
)

SELECT
    MIN(issue_date) AS earliest_issue_date,
    MAX(issue_date) AS latest_issue_date,
    SUM(issue_date IS NULL) AS invalid_issue_date,
    SUM(
        CASE
            WHEN YEAR(issue_date) NOT BETWEEN 2007 AND 2018
            THEN 1
            ELSE 0
        END
    ) AS outside_expected_years
FROM date_validation;


-- =====================================================
-- 11. Previously Verified Validation Results
-- =====================================================

-- Total valid loans:          2,260,668
-- Duplicate loan IDs:                 0
-- Missing DTI:                    1,711
-- Negative DTI:                       2
-- DTI above 100:                  2,561
-- Excluded DTI records:           4,274
-- Minimum FICO range low:           610
-- Maximum FICO range low:           845
-- Average FICO range low:        698.59
-- Invalid FICO:                       0
-- Invalid issue date:                 0
-- Origination years:          2007-2018
