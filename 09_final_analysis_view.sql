/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 09_final_analysis_view.sql
   Database: MySQL 8.0+
   Objective: Create the final 27-column analytical view
   Prerequisite: 03_data_cleaning.sql
   ===================================================== */

USE credit_risk_portfolio;
-- 1. Create Final Credit Risk Analysis View

CREATE OR REPLACE VIEW
credit_risk_portfolio.credit_risk_analysis AS

SELECT
    *,

    -- Date Conversion (day 01 is a monthly placeholder)
    STR_TO_DATE(
        CONCAT('01-', issue_d),
        '%d-%b-%Y'
    ) AS issue_date,

    YEAR(
        STR_TO_DATE(
            CONCAT('01-', issue_d),
            '%d-%b-%Y'
        )
    ) AS issue_year,

    -- Interest Rate Conversion (percentage units)
    CAST(int_rate AS DECIMAL(5,2))
        AS interest_rate_numeric,

    -- Resolved Loan Flag
    CASE
        WHEN loan_status IN (
            'Fully Paid', 'Charged Off', 'Default'
        )
        THEN 1
        ELSE 0
    END AS resolved_flag,

    -- Default Flag (0 does not imply successful repayment)
    CASE
        WHEN loan_status IN ('Charged Off', 'Default')
        THEN 1
        ELSE 0
    END AS default_flag,

    -- Risk Category
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
        WHEN loan_status LIKE 'Does not meet the credit policy%'
            THEN 'Non-Standard Policy'
        ELSE 'Other'
    END AS risk_category,

    -- Annual Income Group
    CASE
        WHEN annual_inc IS NULL OR annual_inc <= 0
            THEN 'Excluded'
        WHEN annual_inc < 25000 THEN 'Very Low'
        WHEN annual_inc < 50000 THEN 'Low'
        WHEN annual_inc < 75000 THEN 'Medium'
        WHEN annual_inc < 100000 THEN 'Upper Medium'
        WHEN annual_inc < 150000 THEN 'High'
        ELSE 'Very High'
    END AS income_group,

    -- DTI Group
    CASE
        WHEN dti IS NULL OR dti < 0 OR dti > 100
            THEN 'Excluded'
        WHEN dti < 10 THEN 'Very Low'
        WHEN dti < 20 THEN 'Low'
        WHEN dti < 30 THEN 'Medium'
        WHEN dti < 40 THEN 'High'
        ELSE 'Very High'
    END AS dti_group,

    -- FICO Score Group
    CASE
        WHEN fico_range_low IS NULL
          OR fico_range_low NOT BETWEEN 300 AND 850
            THEN 'Excluded'
        WHEN fico_range_low < 650 THEN 'Very Low'
        WHEN fico_range_low < 680 THEN 'Low'
        WHEN fico_range_low < 720 THEN 'Medium'
        WHEN fico_range_low < 760 THEN 'High'
        WHEN fico_range_low < 800 THEN 'Very High'
        ELSE 'Exceptional'
    END AS fico_group,

    -- Loan Amount Group
    CASE
        WHEN loan_amnt < 5000 THEN 'Very Small'
        WHEN loan_amnt < 10000 THEN 'Small'
        WHEN loan_amnt < 20000 THEN 'Medium'
        WHEN loan_amnt < 30000 THEN 'Large'
        ELSE 'Very Large'
    END AS amount_group

FROM credit_risk_portfolio.lendingclub_clean;

-- 2. Preview analytical view
SELECT * FROM credit_risk_analysis LIMIT 10;

-- Segmentation thresholds are project-defined.
-- FICO uses the lower bound of the reported range.
-- Original loan amount is not EAD.
-- Recoveries and total_rec_prncp are post-origination variables;
-- using them for origination-time prediction would cause leakage.
