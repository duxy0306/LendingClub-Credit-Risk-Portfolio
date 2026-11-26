# Data Dictionary — LendingClub Credit Risk Portfolio

## 1. Dataset overview

| Property | Value |
|---|---|
| Source dataset | LendingClub accepted loans, 2007–2018 Q4 |
| Database | `credit_risk_portfolio` |
| Cleaned table | `lendingclub_clean` |
| Analytical view | `credit_risk_analysis` |
| Grain | One record per accepted loan |
| Previously validated records | 2,260,668 |
| Fields | 27 (17 retained source fields and 10 derived fields) |

The cleaning process retains records with a numeric loan ID and a positive, non-null original loan amount. The final view preserves the cleaned records. The counts in this document refer to the previously observed project results, not a new database execution.

## 2. Retained source fields

The types below follow the project's recorded MySQL table definition; they are not the original CSV's native types. Business descriptions are working definitions for this project, not a reproduction of an official LendingClub data dictionary.

| Field | MySQL type | Unit / meaning | Analytical use |
|---|---|---|---|
| `id` | VARCHAR(30) | Loan identifier | Unique loan counts and validation; treat as text |
| `loan_amnt` | DECIMAL(12,2) | Original loan amount, USD | Loan size segmentation; not current exposure or EAD |
| `term` | VARCHAR(20) | Loan term, e.g. 36 months or 60 months | Term-based risk comparison |
| `int_rate` | VARCHAR(20) | Interest rate in percentage units | Source for numeric interest rate |
| `installment` | DECIMAL(12,2) | Scheduled monthly installment, USD | Payment obligation context |
| `grade` | VARCHAR(5) | LendingClub credit grade, A–G | Risk differentiation and pricing |
| `sub_grade` | VARCHAR(5) | Finer LendingClub credit grade, e.g. A1 | Potential finer-grained segmentation |
| `annual_inc` | DECIMAL(15,2) | Reported annual income, USD | Income segmentation |
| `dti` | DECIMAL(10,2) | Debt-to-income ratio, percentage units | Debt burden segmentation |
| `loan_status` | VARCHAR(50) | Recorded loan performance status | Outcome classification and risk metrics |
| `issue_d` | VARCHAR(20) | Loan origination month and year, e.g. Dec-2015 | Cohort analysis |
| `fico_range_low` | INT | Lower bound of reported FICO range | Credit score segmentation; not an exact score |
| `recoveries` | DECIMAL(15,2) | Recorded post-charge-off recoveries, USD | Retrospective recovery context; potential target leakage |
| `total_rec_prncp` | DECIMAL(15,2) | Total principal received, USD | Retrospective repayment context; potential target leakage |
| `purpose` | VARCHAR(100) | Reported loan purpose | Purpose-based risk comparison |
| `home_ownership` | VARCHAR(30) | Reported home ownership category | Borrower segmentation |
| `verification_status` | VARCHAR(50) | Recorded verification status | Potential additional borrower segmentation |

## 3. Derived analytical fields

Derived types are logical types; exact MySQL view metadata can be checked with `DESCRIBE credit_risk_analysis;`.

| Field | Type | Definition / calculation |
|---|---|---|
| `issue_date` | Date | `STR_TO_DATE(CONCAT('01-', issue_d), '%d-%b-%Y')`; day 01 is a placeholder, not the actual origination day |
| `issue_year` | Integer | Year extracted from `issue_date` |
| `interest_rate_numeric` | DECIMAL(5,2) | `CAST(int_rate AS DECIMAL(5,2))`; 12.50 means 12.50%, not 0.125 |
| `resolved_flag` | Integer (0/1) | 1 for Fully Paid, Charged Off or Default; otherwise 0 |
| `default_flag` | Integer (0/1) | 1 for Charged Off or Default; otherwise 0. Zero does not imply successful repayment |
| `risk_category` | Text | Standardized status classification (Section 4) |
| `income_group` | Text | Annual income segment (Section 5) |
| `dti_group` | Text | DTI segment (Section 5) |
| `fico_group` | Text | FICO lower-bound segment (Section 5) |
| `amount_group` | Text | Original loan amount segment (Section 5) |

## 4. Loan status mapping

| Original status | Risk category | Resolved flag | Default flag |
|---|---|---:|---:|
| Fully Paid | Fully Paid | 1 | 0 |
| Charged Off; Default | Charged Off/Default | 1 | 1 |
| Current; Late (16-30 days); Late (31-120 days); In Grace Period | Unresolved | 0 | 0 |
| Starts with `Does not meet the credit policy` | Non-Standard Policy | 0 | 0 |
| All other statuses, including NULL | Other | 0 | 0 |

Non-standard policy records are excluded from the resolved sample even if their original status text includes Fully Paid or Charged Off.

## 5. Risk segmentation rules

Intervals use inclusive lower bounds and exclusive upper bounds unless explicitly noted. These thresholds are project-defined analytical buckets, not official underwriting rules.

### Annual income (USD)

| Group | Range |
|---|---|
| Excluded | NULL or <= 0 |
| Very Low | > 0 and < 25,000 |
| Low | 25,000–<50,000 |
| Medium | 50,000–<75,000 |
| Upper Medium | 75,000–<100,000 |
| High | 100,000–<150,000 |
| Very High | >= 150,000 |

### Debt-to-income ratio (%)

| Group | Range |
|---|---|
| Excluded | NULL, < 0 or > 100 |
| Very Low | 0–<10 |
| Low | 10–<20 |
| Medium | 20–<30 |
| High | 30–<40 |
| Very High | 40–100 inclusive |

### FICO score (lower bound)

| Group | Range |
|---|---|
| Excluded | NULL or outside 300–850 |
| Very Low | 300–649 |
| Low | 650–679 |
| Medium | 680–719 |
| High | 720–759 |
| Very High | 760–799 |
| Exceptional | 800–850 |

The Very Low group contained only two resolved loans in the previous analysis and was omitted from the FICO dashboard comparison.

### Original loan amount (USD)

| Group | Range |
|---|---|
| Very Small | > 0 and < 5,000 |
| Small | 5,000–<10,000 |
| Medium | 10,000–<20,000 |
| Large | 20,000–<30,000 |
| Very Large | >= 30,000 |

Invalid income, DTI and FICO values are excluded from their respective segment comparisons, not globally removed from the portfolio.

## 6. Key risk metrics

| Metric | Calculation | Previously observed full-portfolio result |
|---|---|---:|
| Total loans | `COUNT(DISTINCT id)` | 2,260,668 |
| Resolved loans | `SUM(resolved_flag)` | 1,345,350 |
| Defaulted loans | `SUM(default_flag)` | 268,599 |
| Historical default rate | `SUM(default_flag) / NULLIF(SUM(resolved_flag), 0)` | 19.96% |
| Resolution rate | `SUM(resolved_flag) / NULLIF(COUNT(*), 0)` | 59.51% |
| Loan share | Segment loan count / total loan count in comparison population | Varies by segment |
| Default contribution | Segment default count / total default count in comparison population | Varies by segment |
| Average interest rate | Mean numeric interest rate among loans with valid rates | Varies by grade |

Rates in this table are ratios unless otherwise specified. Multiply ratios by 100 for SQL percentage-unit output, or format the ratios as percentages in Tableau. For Tableau's average interest rate, divide `AVG([Interest Rate Numeric])` by 100 before percentage formatting. Grade share and grade default contribution use the A–G comparison population. Average interest rate is not restricted to resolved loans.

## 7. Data quality and interpretation notes

- Previous validation: 2,260,668 unique IDs, zero duplicate rows, zero missing converted issue dates and 27 fields.
- Historical default rate is the observed charged-off/default share among resolved standard-status loans. It is not a forward-looking probability of default (PD).
- Annual origination cohorts have unequal observation periods and resolution rates. Comparisons are not fixed-horizon vintage analyses.
- The dataset contains accepted loans; findings do not represent all applicants or rejected applications.
- Segment comparisons are descriptive, not causal. Small samples require caution.
- Original loan amount is not exposure at default (EAD); observed default counts do not measure economic loss or profitability.
- Loan outcomes, recoveries and principal received are post-origination information and must not be used as origination-time predictors.
- The full loan-level dataset and packaged Tableau workbook are not intended for public redistribution without checking the applicable data license.

## 8. Related project files

- [`03_data_cleaning.sql`](../sql/03_data_cleaning.sql)
- [`09_final_analysis_view.sql`](../sql/09_final_analysis_view.sql)
- [`10_final_data_validation.sql`](../sql/10_final_data_validation.sql)
- [`11_tableau_data_export.sql`](../sql/11_tableau_data_export.sql)
