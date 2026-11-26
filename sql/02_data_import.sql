/* =====================================================
   Project: LendingClub Credit Risk Portfolio Analysis
   File: 02_data_import.sql
   Database: MySQL
   Objective: Import raw LendingClub loan data
   Dataset: LendingClub Accepted Loans (2007-2018)

   Source columns: 151
   Retained columns: 17

   Prerequisite: 01_database_setup.sql
   ===================================================== */


USE credit_risk_portfolio;


-- 1. Check the raw table before importing
-- The table should be empty before the initial import.
-- Do not repeat the import if data already exists.

SELECT COUNT(*) AS existing_rows
FROM lendingclub_raw;


-- 2. Import the original CSV dataset
-- Replace the file path with your local dataset location.
-- Unused columns are assigned to temporary variables.

LOAD DATA LOCAL INFILE
    'C:/path/to/accepted_2007_to_2018Q4.csv'
INTO TABLE lendingclub_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    @id,                         -- 1
    @skip_2,
    @loan_amnt,                  -- 3
    @skip_4,
    @skip_5,
    @term,                       -- 6
    @int_rate,                   -- 7
    @installment,                -- 8
    @grade,                      -- 9
    @sub_grade,                  -- 10
    @skip_11,
    @skip_12,
    @home_ownership,             -- 13
    @annual_inc,                 -- 14
    @verification_status,        -- 15
    @issue_d,                    -- 16
    @loan_status,                -- 17
    @skip_18,
    @skip_19,
    @skip_20,
    @purpose,                    -- 21
    @skip_22,
    @skip_23,
    @skip_24,
    @dti,                        -- 25
    @skip_26,
    @skip_27,
    @fico_range_low,             -- 28
    @skip_29,
    @skip_30,
    @skip_31,
    @skip_32,
    @skip_33,
    @skip_34,
    @skip_35,
    @skip_36,
    @skip_37,
    @skip_38,
    @skip_39,
    @skip_40,
    @skip_41,
    @skip_42,
    @total_rec_prncp,             -- 43
    @skip_44,
    @skip_45,
    @recoveries,                  -- 46
    @skip_47,
    @skip_48,
    @skip_49,
    @skip_50,
    @skip_51,
    @skip_52,
    @skip_53,
    @skip_54,
    @skip_55,
    @skip_56,
    @skip_57,
    @skip_58,
    @skip_59,
    @skip_60,
    @skip_61,
    @skip_62,
    @skip_63,
    @skip_64,
    @skip_65,
    @skip_66,
    @skip_67,
    @skip_68,
    @skip_69,
    @skip_70,
    @skip_71,
    @skip_72,
    @skip_73,
    @skip_74,
    @skip_75,
    @skip_76,
    @skip_77,
    @skip_78,
    @skip_79,
    @skip_80,
    @skip_81,
    @skip_82,
    @skip_83,
    @skip_84,
    @skip_85,
    @skip_86,
    @skip_87,
    @skip_88,
    @skip_89,
    @skip_90,
    @skip_91,
    @skip_92,
    @skip_93,
    @skip_94,
    @skip_95,
    @skip_96,
    @skip_97,
    @skip_98,
    @skip_99,
    @skip_100,
    @skip_101,
    @skip_102,
    @skip_103,
    @skip_104,
    @skip_105,
    @skip_106,
    @skip_107,
    @skip_108,
    @skip_109,
    @skip_110,
    @skip_111,
    @skip_112,
    @skip_113,
    @skip_114,
    @skip_115,
    @skip_116,
    @skip_117,
    @skip_118,
    @skip_119,
    @skip_120,
    @skip_121,
    @skip_122,
    @skip_123,
    @skip_124,
    @skip_125,
    @skip_126,
    @skip_127,
    @skip_128,
    @skip_129,
    @skip_130,
    @skip_131,
    @skip_132,
    @skip_133,
    @skip_134,
    @skip_135,
    @skip_136,
    @skip_137,
    @skip_138,
    @skip_139,
    @skip_140,
    @skip_141,
    @skip_142,
    @skip_143,
    @skip_144,
    @skip_145,
    @skip_146,
    @skip_147,
    @skip_148,
    @skip_149,
    @skip_150,
    @skip_151
)

-- Map retained fields to the target table.
-- Convert empty values to SQL NULL.

SET
    id = NULLIF(TRIM(@id), ''),
    loan_amnt = NULLIF(TRIM(@loan_amnt), ''),
    term = NULLIF(TRIM(@term), ''),
    int_rate = NULLIF(TRIM(@int_rate), ''),
    installment = NULLIF(TRIM(@installment), ''),
    grade = NULLIF(TRIM(@grade), ''),
    sub_grade = NULLIF(TRIM(@sub_grade), ''),
    annual_inc = NULLIF(TRIM(@annual_inc), ''),
    dti = NULLIF(TRIM(@dti), ''),
    loan_status = NULLIF(TRIM(@loan_status), ''),
    issue_d = NULLIF(TRIM(@issue_d), ''),
    fico_range_low = NULLIF(TRIM(@fico_range_low), ''),
    recoveries = NULLIF(TRIM(@recoveries), ''),
    total_rec_prncp = NULLIF(TRIM(@total_rec_prncp), ''),
    purpose = NULLIF(TRIM(@purpose), ''),
    home_ownership = NULLIF(TRIM(@home_ownership), ''),
    verification_status = NULLIF(TRIM(@verification_status), '');


-- 3. Review import warnings

SHOW WARNINGS LIMIT 20;


-- 4. Validate imported row count
-- Expected result: 2,260,701

SELECT
    COUNT(*) AS total_raw_records
FROM lendingclub_raw;


-- 5. Inspect imported records

SELECT *
FROM lendingclub_raw
LIMIT 10;


-- 6. Identify records requiring data cleaning

SELECT
    COUNT(*) AS total_records,
    SUM(loan_amnt IS NULL) AS missing_loan_amount,
    SUM(loan_amnt <= 0) AS non_positive_loan_amount,
    SUM(id IS NULL) AS missing_id,
    SUM(id NOT REGEXP '^[0-9]+$') AS non_numeric_id
FROM lendingclub_raw;


-- 7. Verify retained column count
-- Expected result: 17

SELECT
    COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'credit_risk_portfolio'
  AND table_name = 'lendingclub_raw';
