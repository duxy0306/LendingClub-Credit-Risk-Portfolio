/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 07_borrower_risk_analysis.sql
   Database: MySQL 8.0+
   Objective: Identify borrower and loan characteristics
              associated with historical credit risk.
   Prerequisite: 03_data_cleaning.sql

   Methodology:
   - Resolved sample: Fully Paid, Charged Off, Default.
   - Default events: Charged Off or Default (project proxy).
   - Historical default rate is not forward-looking PD.
   - Unresolved and non-standard policy loans are excluded
     from the default-rate denominator.
   - Invalid values are excluded only from relevant segments.
   - Segmentation thresholds are project-defined.
   - Unequal observation windows and selection bias remain.
   - Associations are not causal; small samples require caution.
   - FICO uses the lower bound of the reported score range.
   - Original loan amount is not EAD.
   ===================================================== */

USE credit_risk_portfolio;


-- =====================================================
-- 1. Historical Default Rate by Loan Purpose
-- =====================================================

WITH purpose_summary AS (
    SELECT
        purpose,
        COUNT(*) AS total_resolved_loans,
        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans
    FROM credit_risk_portfolio.lendingclub_clean
    WHERE loan_status IN (
        'Fully Paid',
        'Charged Off',
        'Default'
    )
    AND purpose IS NOT NULL
    AND TRIM(purpose) <> ''
    GROUP BY purpose
)

SELECT
    purpose,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate
FROM purpose_summary
ORDER BY historical_default_rate DESC;


-- =====================================================
-- 2. Historical Default Rate by Home Ownership
-- =====================================================

WITH home_summary AS (
    SELECT
        home_ownership,
        COUNT(*) AS total_resolved_loans,
        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans

    FROM credit_risk_portfolio.lendingclub_clean

    WHERE loan_status IN (
        'Fully Paid',
        'Charged Off',
        'Default'
    )
    AND home_ownership IS NOT NULL
    AND TRIM(home_ownership) <> ''

    GROUP BY home_ownership
)

SELECT
    home_ownership,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate

FROM home_summary
ORDER BY historical_default_rate DESC;


-- =====================================================
-- 3. Historical Default Rate by Annual Income
-- =====================================================

WITH income_summary AS (
    SELECT
        CASE
            WHEN annual_inc < 25000 THEN 'Very Low'
            WHEN annual_inc < 50000 THEN 'Low'
            WHEN annual_inc < 75000 THEN 'Medium'
            WHEN annual_inc < 100000 THEN 'Upper Medium'
            WHEN annual_inc < 150000 THEN 'High'
            ELSE 'Very High'
        END AS income_group,

        COUNT(*) AS total_resolved_loans,

        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans

    FROM credit_risk_portfolio.lendingclub_clean

    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND annual_inc IS NOT NULL
    AND annual_inc > 0

    GROUP BY income_group
)

SELECT
    income_group,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate

FROM income_summary

ORDER BY FIELD(
    income_group,
    'Very Low',
    'Low',
    'Medium',
    'Upper Medium',
    'High',
    'Very High'
);


-- =====================================================
-- 4. Historical Default Rate by DTI
-- =====================================================

WITH dti_summary AS (
    SELECT
        CASE
            WHEN dti < 10 THEN 'Very Low'
            WHEN dti < 20 THEN 'Low'
            WHEN dti < 30 THEN 'Medium'
            WHEN dti < 40 THEN 'High'
            ELSE 'Very High'
        END AS dti_group,

        COUNT(*) AS total_resolved_loans,

        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans

    FROM credit_risk_portfolio.lendingclub_clean

    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND dti BETWEEN 0 AND 100

    GROUP BY dti_group
)

SELECT
    dti_group,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate

FROM dti_summary

ORDER BY FIELD(
    dti_group,
    'Very Low',
    'Low',
    'Medium',
    'High',
    'Very High'
);


-- =====================================================
-- 5. Historical Default Rate by FICO Score
-- =====================================================

WITH fico_summary AS (
    SELECT
        CASE
            WHEN fico_range_low < 650 THEN 'Very Low'
            WHEN fico_range_low < 680 THEN 'Low'
            WHEN fico_range_low < 720 THEN 'Medium'
            WHEN fico_range_low < 760 THEN 'High'
            WHEN fico_range_low < 800 THEN 'Very High'
            ELSE 'Exceptional'
        END AS fico_group,

        COUNT(*) AS total_resolved_loans,

        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans

    FROM credit_risk_portfolio.lendingclub_clean

    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND fico_range_low BETWEEN 300 AND 850

    GROUP BY fico_group
)

SELECT
    fico_group,
    total_resolved_loans,
    defaulted_loans,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate

FROM fico_summary

ORDER BY FIELD(
    fico_group,
    'Very Low',
    'Low',
    'Medium',
    'High',
    'Very High',
    'Exceptional'
);


-- =====================================================
-- 6. Historical Default Rate by Loan Amount
-- =====================================================

WITH amount_summary AS (
    SELECT
        CASE
            WHEN loan_amnt < 5000 THEN 'Very Small'
            WHEN loan_amnt < 10000 THEN 'Small'
            WHEN loan_amnt < 20000 THEN 'Medium'
            WHEN loan_amnt < 30000 THEN 'Large'
            ELSE 'Very Large'
        END AS amount_group,

        COUNT(*) AS total_resolved_loans,

        SUM(
            CASE
                WHEN loan_status IN ('Charged Off', 'Default')
                THEN 1
                ELSE 0
            END
        ) AS defaulted_loans,

        ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,

        SUM(loan_amnt) AS total_loan_amount

    FROM credit_risk_portfolio.lendingclub_clean

    WHERE loan_status IN (
        'Fully Paid', 'Charged Off', 'Default'
    )
    AND loan_amnt > 0

    GROUP BY amount_group
)

SELECT
    amount_group,
    total_resolved_loans,
    defaulted_loans,
    avg_loan_amount,
    total_loan_amount,
    ROUND(
        defaulted_loans * 100.0 /
        NULLIF(total_resolved_loans, 0),
        2
    ) AS historical_default_rate

FROM amount_summary

ORDER BY FIELD(
    amount_group,
    'Very Small',
    'Small',
    'Medium',
    'Large',
    'Very Large'
);

-- =====================================================
-- 7. Previously Observed Business Findings
-- =====================================================
-- Small business loans: 29.71% historical default rate.
-- Debt consolidation: approximately 61.44% of default events.
-- Home ownership: RENT 23.22%, OWN 20.62%, MORTGAGE 17.21%.
-- Income: 24.68% (Very Low) to 14.91% (Very High).
-- DTI: 14.89% (Very Low) to 30.86% (Very High).
-- FICO: 25.29% (Low) to 6.42% (Exceptional).
-- The Very Low FICO group has only two resolved loans.
-- Loan amount: 15.48% (Very Small) to 24.23% (Very Large).
-- These are descriptive associations, not causal effects.
