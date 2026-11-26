/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 11_tableau_data_export.sql
   Database: MySQL 8.0+
   Objective: Export the analytical dataset for Tableau
   Prerequisite: 10_final_data_validation.sql
   ===================================================== */

USE credit_risk_portfolio;
-- 1. Export the validated analytical view
-- In MySQL Workbench, disable the result row limit before execution.
-- Export the complete result grid as CSV with column headers.
-- Verify that the exported dataset contains 2,260,668 rows and 27 columns.
-- Check CSV parsing and NULL handling before importing into Tableau.
-- Interest rate values are in percentage units (e.g., 11.99).
-- Do not publish loan-level data or extracts without checking
-- redistribution permissions and privacy requirements.


SELECT *
FROM credit_risk_analysis;
