/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 06_credit_grade_and_pricing.sql
   Database: MySQL 8.0+
   Objective: Evaluate credit grade differentiation,
              default concentration, loan term risk,
              and risk-based pricing

   Prerequisite: 03_data_cleaning.sql

   Methodology:
   - Default events: Charged Off or Default.
   - Historical default rate uses resolved loans only.
   - Average interest rate uses all loans with valid rates.
   - Historical default rate is not forward-looking PD.
   - Pricing patterns do not establish profitability.
   - Observed relationships are descriptive, not causal.
   ===================================================== */


USE credit_risk_portfolio;


-- =====================================================
-- 1. Loan Distribution by Credit Grade
-- =====================================================

SELECT
    grade,
    COUNT(*) AS total_loans,
    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS loan_percentage
FROM lendingclub_clean
WHERE grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
GROUP BY grade
ORDER BY grade;


-- =====================================================
-- 2. Historical Default Rate by Credit Grade
-- =====================================================

WITH grade_summary AS (
    SELECT
        grade,
        COUNT(*) AS total_resolved_loans,
        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans
    FROM lendingclub_clean
    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
    GROUP BY grade
)

SELECT
    grade,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate
FROM grade_summary
ORDER BY grade;


-- =====================================================
-- 3. Default Contribution by Credit Grade
-- =====================================================

WITH grade_defaults AS (
    SELECT
        grade,
        COUNT(*) AS defaulted_loans
    FROM lendingclub_clean
    WHERE loan_status IN ('Charged Off', 'Default')
      AND grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
    GROUP BY grade
)

SELECT
    grade,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(SUM(defaulted_loans) OVER (), 0),
        2
    ) AS default_contribution_pct
FROM grade_defaults
ORDER BY grade;


-- =====================================================
-- 4. Historical Default Rate by Loan Term
-- =====================================================

WITH term_summary AS (
    SELECT
        TRIM(term) AS loan_term,
        COUNT(*) AS total_resolved_loans,
        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans
    FROM lendingclub_clean
    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    GROUP BY TRIM(term)
)

SELECT
    loan_term,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate
FROM term_summary
ORDER BY loan_term;


-- =====================================================
-- 5. Historical Default Rate by Grade and Loan Term
-- =====================================================

WITH grade_term_summary AS (
    SELECT
        grade,
        TRIM(term) AS loan_term,
        COUNT(*) AS total_resolved_loans,
        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans
    FROM lendingclub_clean
    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
    GROUP BY grade, TRIM(term)
)

SELECT
    grade,
    loan_term,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate
FROM grade_term_summary
ORDER BY grade, loan_term;


-- =====================================================
-- 6. Average Interest Rate by Credit Grade
-- =====================================================

SELECT
    grade,
    COUNT(*) AS total_loans,
    COUNT(
        CASE
            WHEN TRIM(int_rate)
                REGEXP '^[0-9]+([.][0-9]+)?$'
            THEN 1
        END
    ) AS valid_interest_rate_loans,
    ROUND(
        AVG(
            CASE
                WHEN TRIM(int_rate)
                    REGEXP '^[0-9]+([.][0-9]+)?$'
                THEN CAST(int_rate AS DECIMAL(5,2))
            END
        ),
        2
    ) AS avg_interest_rate
FROM lendingclub_clean
WHERE grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
GROUP BY grade
ORDER BY grade;


-- =====================================================
-- 7. Risk-Based Pricing Analysis
-- =====================================================

-- Compare average interest rates with historical
-- default rates across credit grades.
--
-- Interest rate denominator: loans with valid rates.
-- Default rate denominator: resolved loans.

WITH interest_summary AS (
    SELECT
        grade,
        COUNT(*) AS total_loans,
        AVG(
            CASE
                WHEN TRIM(int_rate)
                    REGEXP '^[0-9]+([.][0-9]+)?$'
                THEN CAST(int_rate AS DECIMAL(5,2))
            END
        ) AS avg_interest_rate
    FROM lendingclub_clean
    WHERE grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
    GROUP BY grade
),

default_summary AS (
    SELECT
        grade,
        COUNT(*) AS total_resolved_loans,
        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans
    FROM lendingclub_clean
    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND grade IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
    GROUP BY grade
)

SELECT
    i.grade,
    i.total_loans,
    ROUND(i.avg_interest_rate, 2) AS avg_interest_rate,
    d.total_resolved_loans,
    d.defaulted_loans,
    ROUND(
        d.defaulted_loans * 100.0 /
        NULLIF(d.total_resolved_loans, 0),
        2
    ) AS historical_default_rate
FROM interest_summary AS i
JOIN default_summary AS d
    ON i.grade = d.grade
ORDER BY i.grade;


-- =====================================================
-- 8. Previously Observed Business Findings
-- =====================================================

-- Grade A historical default rate: 6.04%
-- Grade G historical default rate: 49.93%
--
-- Grade A average interest rate: 7.08%
-- Grade G average interest rate: 28.07%
--
-- Grades C and D account for approximately 54.63%
-- of observed default events.
--
-- 36-month loan historical default rate: 16.00%
-- 60-month loan historical default rate: 32.45%
--
-- Longer-term loans exhibit higher historical default
-- rates across all seven credit grades.
--
-- Results are consistent with risk-based pricing,
-- but do not establish risk-adjusted profitability.
