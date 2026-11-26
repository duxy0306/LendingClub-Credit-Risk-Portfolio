# Credit Risk Analysis Methodology

## 1. Business Objectives

This project examines historical credit performance in LendingClub accepted loans originated from 2007 through 2018. It aims to identify risk differentiation, default concentration, pricing patterns and borrower characteristics associated with observed defaults. It is a descriptive portfolio analysis, not an underwriting or predictive model.

## 2. Data Processing and Quality Assurance

The workflow uses MySQL 8.0+ for preparation and analysis and Tableau for visualization.

1.  Import 17 selected fields from the source CSV into `lendingclub_raw`.
2.  Retain records with positive, non-null loan amounts and numeric loan IDs in `lendingclub_clean`.
3.  Check uniqueness, missing values, status categories, dates and numeric formats.
4.  Create `credit_risk_analysis`, a 27-field analytical view containing standardized dates, flags and segmentation fields.
5.  Validate the view and export it for Tableau. Correct CSV null representations as needed and reconcile dashboard totals with SQL outputs.

Previously observed validation results:

  Check                                   Result
  ---------------------------------- -----------
  Imported records                     2,260,701
  Cleaned records                      2,260,668
  Removed records                             33
  Unique cleaned loan IDs              2,260,668
  Missing standardized issue dates             0
  Analytical fields                           27

Invalid values in individual risk factors are excluded from the relevant segment analysis rather than automatically removing the entire loan record. The DTI analysis excludes missing values and values outside 0--100; this is a project-specific rule, not a universal lending standard.

## 3. Outcome Definitions and Risk Metrics

  ------------------------------------------------------------------------------------------
  Status                              Analytical treatment
  ----------------------------------- ------------------------------------------------------
  Fully Paid                          Resolved, non-default outcome

  Charged Off or Default              Resolved, observed default event

  Current, late or in grace period    Unresolved; excluded from default-rate denominator

  Does not meet credit policy         Non-standard policy; excluded from resolved sample

  Other                               Separately classified; excluded from resolved sample
  ------------------------------------------------------------------------------------------

The default flag identifies observed charged-off/default outcomes. A zero default flag does not establish successful repayment.

-   **Historical default rate** = observed default events / resolved loans.
-   **Resolution rate** = resolved loans / all cleaned loans.
-   **Portfolio share** = segment loan count / total loans in the relevant analysis universe.
-   **Default contribution** = segment default count / total defaults in the relevant analysis universe.
-   **Average interest rate** = arithmetic mean of valid recorded interest rates, expressed in percentage units; not weighted by loan balance.

Grade share and grade default contribution use grades A--G as their analysis universe. Rates should be recalculated from counts when filters change rather than averaging segment rates.

  Portfolio metric            Previously observed value
  ------------------------- ---------------------------
  Total loans                                 2,260,668
  Resolved loans                              1,345,350
  Observed defaults                             268,599
  Historical default rate                        19.96%
  Resolution rate                                59.51%

## 4. Credit Risk Segmentation

Compare counts, observed defaults and historical default rates across the following dimensions. Intervals below include their lower bound and exclude their upper bound unless otherwise stated.

  -----------------------------------------------------------------------------------------------------
  Dimension                           Segments
  ----------------------------------- -----------------------------------------------------------------
  Credit grade                        A--G

  Loan term                           36 and 60 months

  Annual income (USD)                 Positive to \<25k; 25--50k; 50--75k; 75--100k; 100--150k; 150k+

  DTI (%)                             0--10; 10--20; 20--30; 30--40; 40--100 inclusive

  FICO lower bound                    300--649; 650--679; 680--719; 720--759; 760--799; 800--850

  Original principal (USD)            \<5k; 5--10k; 10--20k; 20--30k; 30k+

  Loan purpose and home ownership     Recorded categories
  -----------------------------------------------------------------------------------------------------

Income must be positive; FICO must be within 300--850. Missing or invalid factor values are excluded from the corresponding segment comparison. The FICO field represents the lower bound of the reported score range. The lowest FICO segment has only two resolved loans and is unsuitable for meaningful comparison.

## 5. Risk-Based Pricing and Concentration

Compare grade-level historical default rates with average recorded interest rates. The interest-rate sample includes loans with valid rates, while the default-rate sample includes resolved loans only. The samples therefore differ.

Previously observed results show Grade A at 6.04% historical default rate and 7.08% average interest, compared with Grade G at 49.93% and 28.07%. Grades C and D together account for approximately 54.63% of observed defaults. These patterns are consistent with risk-based pricing and illustrate why both risk intensity and portfolio concentration matter.

Compare 36- and 60-month loans overall and within grades. Previously observed historical default rates were 16.00% and 32.45%, respectively. These associations do not establish causal effects or risk-adjusted profitability.

## 6. Origination Cohorts and Portfolio Monitoring

Parse the source origination month and year into a standardized date using day 01 as a placeholder. Group loans by origination year and calculate volume, resolved counts, default counts, resolution rate and historical default rate.

The 2018 cohort had an observed default rate of 15.76% but a resolution rate of only 11.37%. A lower observed rate does not necessarily indicate better credit quality. Cohorts differ in observation periods and resolution status; this analysis is not a fixed-horizon vintage analysis.

The Tableau reporting framework consists of:

-   Executive Risk Overview: portfolio KPIs, status distribution and annual trends.
-   Credit Grade & Risk-Based Pricing: grade-level default rates, pricing, default contribution and grade-by-term comparison.
-   Borrower Risk Factors Analysis: FICO, DTI, income and purpose comparisons.

Year filters support exploratory comparisons. The full-history default-rate reference line, where used, is a fixed benchmark rather than a dynamically filtered portfolio average.

## 7. Limitations and Responsible Interpretation

-   **Selection bias:** Accepted loans do not represent rejected applicants or the entire credit market.
-   **Outcome selection and censoring:** Restricting the denominator to resolved loans can bias comparisons; unresolved loans may later default or repay.
-   **Unequal observation horizons:** Annual cohorts and loan terms are not directly comparable on a fixed performance horizon.
-   **PD versus observed outcomes:** Historical default rate is not a calibrated forward-looking probability of default (PD).
-   **No expected-loss estimation:** Original principal is not exposure at default (EAD). The analysis does not estimate loss given default (LGD), expected loss or risk-adjusted profitability.
-   **Data leakage:** Recoveries and principal repayments are post-origination variables and must not be used as origination-time predictors.
-   **Confounding and small samples:** Segment comparisons are descriptive, not causal. Review denominators before interpreting extreme rates.
-   **Generalizability:** Historical platform-specific results may not transfer to current lending conditions.

## 8. Potential Next Steps

With suitable longitudinal performance data, construct fixed-horizon default labels, perform time-based validation, assess model discrimination and calibration, and investigate expected-loss and profitability measures. These are proposed extensions, not completed project deliverables.

## 9. Reproducibility and Data Governance

Run the SQL scripts in numerical order against an authorized local copy of the source data. Configure the import path and permissions for the local environment. Reconcile the final validation outputs with the dashboard metrics. The reorganized scripts have not been independently rerun end to end.

Keep loan-level CSV files and packaged Tableau workbooks containing extracts out of the public repository unless redistribution rights are confirmed. Dashboard screenshots can document the analytical results without distributing the underlying loan-level dataset.

See [Data Dictionary](data_dictionary.md), [SQL scripts](../sql/) and [Dashboard images](../tableau/images/) for supporting project materials.
