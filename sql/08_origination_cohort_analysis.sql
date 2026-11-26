/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 08_origination_cohort_analysis.sql
   Database: MySQL 8.0+
   Objective: Analyze annual origination cohorts
   Prerequisite: 03_data_cleaning.sql
   ===================================================== */

USE credit_risk_portfolio;
-- 1. Inspect Loan Issue Date

SELECT
    issue_d,
    COUNT(*) AS loan_count
FROM credit_risk_portfolio.lendingclub_clean
GROUP BY issue_d
ORDER BY loan_count DESC
LIMIT 10;

-- 2. Convert Issue Date and Extract Year

SELECT
    issue_d,

    STR_TO_DATE(
        CONCAT('01-', issue_d),
        '%d-%b-%Y'
    ) AS issue_date,

    YEAR(
        STR_TO_DATE(
            CONCAT('01-', issue_d),
            '%d-%b-%Y'
        )
    ) AS issue_year

FROM credit_risk_portfolio.lendingclub_clean

LIMIT 10;

-- 3. Origination-year cohort analysis (not fixed-months-on-book vintage analysis)

WITH cohort_summary AS (
    SELECT
        YEAR(
            STR_TO_DATE(
                CONCAT('01-', issue_d),
                '%d-%b-%Y'
            )
        ) AS issue_year,

        COUNT(*) AS total_loans,

        SUM(
            CASE
                WHEN loan_status IN (
                    'Fully Paid', 'Charged Off', 'Default'
                )
                THEN 1
                ELSE 0
            END
        ) AS total_resolved_loans,

        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans

    FROM credit_risk_portfolio.lendingclub_clean

    GROUP BY issue_year
)

SELECT
    issue_year,
    total_loans,
    total_resolved_loans,
    defaulted_loans,

    ROUND(
        total_resolved_loans * 100.0 /
        NULLIF(total_loans, 0),
        2
    ) AS resolution_rate,

    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate

FROM cohort_summary

ORDER BY issue_year;

-- 4. Previously observed findings
-- Originations: 603 (2007) to 495,242 (2018).
-- Historical default rate: 23.29% (2016), 23.13% (2017).
-- 2018 default rate: 15.76%; resolution rate: 11.37%.
-- Unequal observation windows and unresolved loans limit comparisons.
-- Default rate is observed defaults / resolved loans, not forward PD.
-- Resolution rate includes all loans in its denominator.
-- Day 01 is a placeholder for monthly origination dates.
