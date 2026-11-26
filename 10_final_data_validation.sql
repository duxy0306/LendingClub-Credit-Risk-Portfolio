/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 10_final_data_validation.sql
   Database: MySQL 8.0+
   Objective: Validate the final analytical dataset
   Prerequisite: 09_final_analysis_view.sql
   ===================================================== */

USE credit_risk_portfolio;
-- 1. Final Data Validation

SELECT
    COUNT(*) AS total_loans,

    COUNT(DISTINCT id) AS unique_loan_ids,

    COUNT(*) - COUNT(DISTINCT id)
        AS duplicate_rows,

    SUM(resolved_flag) AS total_resolved_loans,

    SUM(default_flag) AS defaulted_loans,

    ROUND(
        SUM(default_flag) * 100.0 /
        NULLIF(SUM(resolved_flag), 0),
        2
    ) AS historical_default_rate,

    ROUND(
        SUM(resolved_flag) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS resolution_rate,

    SUM(
        CASE
            WHEN issue_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_issue_date,

    (
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'credit_risk_portfolio'
          AND table_name = 'credit_risk_analysis'
    ) AS total_columns

FROM credit_risk_portfolio.credit_risk_analysis;

-- 2. Previously observed validation results
-- total_loans: 2260668
-- unique_loan_ids: 2260668
-- duplicate_rows: 0
-- total_resolved_loans: 1345350
-- defaulted_loans: 268599
-- historical_default_rate: 19.96
-- resolution_rate: 59.51
-- missing_issue_date: 0
-- total_columns: 27
