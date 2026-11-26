/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 05_portfolio_overview.sql
   Database: MySQL 8.0+
   Objective: Evaluate overall portfolio performance
              and historical credit risk

   Prerequisite: 03_data_cleaning.sql
   ===================================================== */


USE credit_risk_portfolio;


-- =====================================================
-- 1. Loan Status Distribution
-- =====================================================

SELECT
    loan_status,
    COUNT(*) AS loan_count,
    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS loan_percentage
FROM lendingclub_clean
GROUP BY loan_status
ORDER BY loan_count DESC;


-- =====================================================
-- 2. Loan Outcome Classification
-- =====================================================

WITH risk_classification AS (
    SELECT
        CASE
            WHEN loan_status = 'Fully Paid'
                THEN 'Fully Paid'
            WHEN loan_status IN ('Charged Off', 'Default')
                THEN 'Charged Off/Default'
            WHEN loan_status IN (
                'Current',
                'Late (16-30 days)',
                'Late (31-120 days)',
                'In Grace Period'
            )
                THEN 'Unresolved'
            WHEN loan_status LIKE
                'Does not meet the credit policy%'
                THEN 'Non-Standard Policy'
            ELSE 'Other'
        END AS risk_category
    FROM lendingclub_clean
)

SELECT
    risk_category,
    COUNT(*) AS loan_count,
    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS loan_percentage
FROM risk_classification
GROUP BY risk_category
ORDER BY loan_count DESC;


-- =====================================================
-- 3. Portfolio-Level Risk Metrics
-- =====================================================

-- Default events are defined as Charged Off or Default.
-- Historical default rate uses resolved loans only.
-- This metric is not a forward-looking PD estimate.

WITH portfolio_summary AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(
            CASE
                WHEN loan_status IN (
                    'Fully Paid',
                    'Charged Off',
                    'Default'
                )
                THEN 1
                ELSE 0
            END
        ) AS total_resolved_loans,

        SUM(
            CASE
                WHEN loan_status IN (
                    'Charged Off',
                    'Default'
                )
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans

    FROM lendingclub_clean
)

SELECT
    total_loans,
    total_resolved_loans,
    defaulted_loans,

    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate,

    ROUND(
        total_resolved_loans * 100.0 /
        NULLIF(total_loans, 0),
        2
    ) AS resolution_rate

FROM portfolio_summary;


-- =====================================================
-- 4. Previously Verified Portfolio Results
-- =====================================================

-- Total loans:             2,260,668
-- Resolved loans:          1,345,350
-- Defaulted loans:           268,599
-- Historical default rate:    19.96%
-- Resolution rate:            59.51%

-- Loan outcome distribution:
-- Fully Paid:              1,076,751
-- Unresolved:                912,569
-- Charged Off/Default:       268,599
-- Non-Standard Policy:         2,749
