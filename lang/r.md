---
language: R
package: staggered
version: 1.2.3
cran: true
github: "jonathandroth/staggered"
---

# R API Reference: staggered

## Installation

```r
# From CRAN
install.packages("staggered")

# From GitHub (development version)
devtools::install_github("jonathandroth/staggered")
```

## Dependencies

| Package | Role |
|---------|------|
| data.table | Fast panel data reshaping and aggregation |
| purrr | Functional programming utilities |
| Rcpp | C++ interface |
| RcppEigen | Fast linear algebra via Eigen library |
| magrittr | Pipe operator |
| MASS | Matrix utilities |
| stats | Statistical functions |

**System requirement:** R (>= 3.5.0)

---

## staggered()

Calculate the efficient adjusted estimator in staggered rollout designs.

### Signature

```r
staggered(
  df,
  i = "i",
  t = "t",
  g = "g",
  y = "y",
  estimand = NULL,
  A_theta_list = NULL,
  A_0_list = NULL,
  eventTime = 0,
  beta = NULL,
  use_DiD_A0 = ifelse(is.null(A_0_list), TRUE, FALSE),
  return_full_vcv = FALSE,
  use_last_treated_only = FALSE,
  compute_fisher = FALSE,
  num_fisher_permutations = 500,
  skip_data_check = FALSE
)
```
[verified: R/compute_efficient_estimator_and_se.R#L955-L970]

### Parameters

| Parameter | Type | Default | Description | Constraints | Source |
|---|---|---|---|---|---|
| df | data.frame | — (required) | A data frame containing panel data with variables y (outcome), i (unit identifier), t (time period), g (first treatment period; Inf = never treated) | Must contain columns specified by i, t, g, y | [verified: R/compute_efficient_estimator_and_se.R#L955] |
| i | character | `"i"` | Name of column containing the individual (cross-sectional unit) identifier | Must exist in df; cannot be "g", "t", or "y" | [verified: R/compute_efficient_estimator_and_se.R#L956] |
| t | character | `"t"` | Name of the column containing the time periods | Must exist in df; cannot be "i", "g", or "y" | [verified: R/compute_efficient_estimator_and_se.R#L957] |
| g | character | `"g"` | Name of the column containing the first period when observation is treated (Inf = never treated) | Must exist in df; cannot be "i", "t", or "y" | [verified: R/compute_efficient_estimator_and_se.R#L958] |
| y | character | `"y"` | Name of the column containing the outcome variable | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L959] |
| estimand | character/NULL | `NULL` | **Effectively required.** The estimand to calculate: `"simple"`, `"cohort"`, `"calendar"`, or `"eventstudy"`. Not case-sensitive. Despite the `NULL` default signature, passing `NULL` without providing `A_theta_list` causes an error. Must specify one of the four named options for standard usage. | One of: "simple", "cohort", "calendar", "eventstudy", or NULL (only valid if `A_theta_list` is provided) | [verified: R/compute_efficient_estimator_and_se.R#L960] |
| A_theta_list | list/NULL | `NULL` | Custom estimand specification: list of matrices A_theta_g such that parameter = sum_g A_theta_g Ybar_g | Should be NULL if `estimand` is specified | [verified: R/compute_efficient_estimator_and_se.R#L961] |
| A_0_list | list/NULL | `NULL` | Matrices for constructing Xhat vector of pre-treatment differences. If NULL, uses DiD scalar (CS) or full vector of comparisons depending on `use_DiD_A0` | NULL or list of conformable matrices | [verified: R/compute_efficient_estimator_and_se.R#L962] |
| eventTime | numeric | `0` | Event-time for event-study estimand. If a vector is provided, returns estimates for all event-times in the vector. | Scalar or vector of integers; if vector, estimand must be "eventstudy" | [verified: R/compute_efficient_estimator_and_se.R#L963] |
| beta | numeric/NULL | `NULL` | Coefficient for covariate adjustment. NULL = plug-in optimal. 0 = simple difference-in-means. 1 = CS estimator (with use_DiD_A0=TRUE). **Implementation note**: While β=0 theoretically yields a simple difference-in-means, `staggered` v1.2.3 does not currently support `beta=0` due to a dimension-handling issue. Use the default `beta=NULL` for optimal estimation, or `beta=1` for DiD-style adjustment. | NULL or numeric scalar | [verified: R/compute_efficient_estimator_and_se.R#L964] |
| use_DiD_A0 | logical | `ifelse(is.null(A_0_list), TRUE, FALSE)` | If TRUE, Xhat uses the scalar DiD comparison (CS-style). If FALSE, uses the full vector of all pre-treatment comparisons. | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L965] |
| return_full_vcv | logical | `FALSE` | If TRUE and estimand = "eventstudy", returns a **list** (instead of a data.frame) containing: `resultsDF` (the standard data.frame), `vcv` (refined variance-covariance matrix across event-times), and `vcv_neyman` (conservative Neyman VCV matrix). | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L966] |
| use_last_treated_only | logical | `FALSE` | If TRUE, only compares with the last-treated cohort (Sun & Abraham style) rather than not-yet-treated units | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L967] |
| compute_fisher | logical | `FALSE` | If TRUE, computes a Fisher Randomization Test using the studentized estimator | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L968] |
| num_fisher_permutations | numeric | `500` | Number of permutations for the Fisher Randomization Test | Positive integer | [verified: R/compute_efficient_estimator_and_se.R#L969] |
| skip_data_check | logical | `FALSE` | If TRUE, skips checks for balanced panel and column existence. Used internally for recursive calls. Not recommended for end-users. | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L970] |

### Return Value

#### Standard return (return_full_vcv = FALSE)

A `data.frame` with columns:

| Column | Type | Description | Condition |
|---|---|---|---|
| estimate | numeric | Point estimate of the treatment effect parameter | Always |
| se | numeric | Refined standard error (adjusting for pre-treatment covariates) | Always |
| se_neyman | numeric | Neyman (conservative) standard error | Always |
| eventTime | integer | The event-time corresponding to each row | Only if vector eventTime provided |
| fisher_pval | numeric | Fisher p-value using refined SE | Only if compute_fisher = TRUE |
| fisher_pval_se_neyman | numeric | Fisher p-value using Neyman SE | Only if compute_fisher = TRUE |
| num_fisher_permutations | integer | Number of successful permutation draws | Only if compute_fisher = TRUE |

#### Full VCV return (return_full_vcv = TRUE, estimand = "eventstudy")

A `list` with:

| Element | Type | Description |
|---|---|---|
| resultsDF | data.frame | The data.frame described above |
| vcv | matrix | Full variance-covariance matrix (refined) across event-times |
| vcv_neyman | matrix | Full Neyman variance-covariance matrix across event-times |

### Key Relationships

| Setting | Estimator produced |
|---|---|
| `beta = NULL` (default) | Plug-in efficient estimator (Roth & Sant'Anna, 2023) |
| `beta = 0` | Simple difference-in-means |
| `beta = 1, use_DiD_A0 = TRUE, use_last_treated_only = FALSE` | Callaway & Sant'Anna (2021) estimator |
| `beta = 1, use_DiD_A0 = TRUE, use_last_treated_only = TRUE` | Sun & Abraham (2021) estimator |

### Examples

```r
library(staggered)
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# Simple weighted average
result_simple <- staggered(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "simple"
)
print(result_simple)
# Expected output:
#       estimate          se   se_neyman
# 1 -0.001126981 0.002115194 0.002119248

# Cohort weighted average
result_cohort <- staggered(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "cohort"
)
print(result_cohort)
# Expected output:
#       estimate          se   se_neyman
# 1 -0.001084689 0.002261011 0.002264876

# Calendar weighted average
result_calendar <- staggered(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "calendar"
)
print(result_calendar)
# Expected output:
#      estimate         se   se_neyman
# 1 -0.00187198 0.00255863 0.002561472

# Event-study (first 24 months)
es_results <- staggered(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "eventstudy", eventTime = 0:23
)
head(es_results)
# Expected output:
#        estimate          se   se_neyman eventTime
# 1  3.083575e-04 0.002645327 0.002650957         0
# 2  2.591678e-03 0.002614563 0.002621513         1
# 3 -4.872562e-05 0.002622640 0.002623634         2
# 4  2.043434e-03 0.002715695 0.002720467         3
# 5  2.977076e-03 0.002653917 0.002659630         4
# 6  7.979656e-04 0.002721784 0.002727140         5

# Fisher Randomization Test
result_fisher <- staggered(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "simple", compute_fisher = TRUE, num_fisher_permutations = 500
)
print(result_fisher)
# Expected output:
#       estimate          se   se_neyman fisher_pval fisher_pval_se_neyman
# 1 -0.001126981 0.002115194 0.002119248       0.642                 0.644
#   num_fisher_permutations
# 1                     500
```

---

## staggered_cs()

Calculate the Callaway & Sant'Anna (2021) estimator for staggered rollouts using not-yet-treated units (including never-treated, if available) as controls.

### Signature

```r
staggered_cs(
  df,
  i = "i",
  t = "t",
  g = "g",
  y = "y",
  estimand = NULL,
  A_theta_list = NULL,
  A_0_list = NULL,
  eventTime = 0,
  return_full_vcv = FALSE,
  compute_fisher = FALSE,
  num_fisher_permutations = 500,
  skip_data_check = FALSE
)
```
[verified: R/compute_efficient_estimator_and_se.R#L1412-L1424]

### Parameters

| Parameter | Type | Default | Description | Constraints | Source |
|---|---|---|---|---|---|
| df | data.frame | — (required) | Panel data with y, i, t, g columns. g=Inf denotes never treated. | Must contain specified columns | [verified: R/compute_efficient_estimator_and_se.R#L1412] |
| i | character | `"i"` | Individual identifier column name | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1413] |
| t | character | `"t"` | Time period column name | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1414] |
| g | character | `"g"` | First treatment period column name (Inf = never treated) | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1415] |
| y | character | `"y"` | Outcome variable column name | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1416] |
| estimand | character/NULL | `NULL` | Estimand: "simple", "cohort", "calendar", or "eventstudy". Not case-sensitive. | One of the four, or NULL if A_theta_list provided | [verified: R/compute_efficient_estimator_and_se.R#L1417] |
| A_theta_list | list/NULL | `NULL` | Custom estimand specification (list of A_theta_g matrices) | Should be NULL if estimand is specified | [verified: R/compute_efficient_estimator_and_se.R#L1418] |
| A_0_list | list/NULL | `NULL` | Custom matrices for Xhat construction | NULL or list of matrices | [verified: R/compute_efficient_estimator_and_se.R#L1419] |
| eventTime | numeric | `0` | Event-time for event-study. Scalar or vector. | Integer(s); vector requires estimand = "eventstudy" | [verified: R/compute_efficient_estimator_and_se.R#L1420] |
| return_full_vcv | logical | `FALSE` | Return full VCV matrix for event-study estimates | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L1421] |
| compute_fisher | logical | `FALSE` | Compute Fisher Randomization Test | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L1422] |
| num_fisher_permutations | numeric | `500` | Number of FRT permutations | Positive integer | [verified: R/compute_efficient_estimator_and_se.R#L1423] |
| skip_data_check | logical | `FALSE` | Skip data validation checks | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L1424] |

### Parameters NOT Exposed (Hardcoded Internally)

| Parameter | Hardcoded Value | Rationale |
|---|---|---|
| beta | 1 | DiD-style adjustment |
| use_DiD_A0 | TRUE | Scalar DiD comparison for Xhat |
| use_last_treated_only | FALSE | Uses all not-yet-treated units as controls |

### Equivalence

```r
# staggered_cs(...) is equivalent to:
staggered(..., beta = 1, use_DiD_A0 = TRUE, use_last_treated_only = FALSE)
```
[verified: R/compute_efficient_estimator_and_se.R#L1444-L1454]

### Additional Pre-processing

Units with `g <= min(t)` are dropped with a warning, since the CS estimator requires at least one pre-treatment period for the DiD comparison.
[verified: R/compute_efficient_estimator_and_se.R#L1438-L1441]

### Return Value

Same as `staggered()` — see above.

### Examples

```r
library(staggered)
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# Callaway & Sant'Anna estimator: simple weighted average
result_cs <- staggered_cs(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "simple"
)
print(result_cs)
# Expected output:
#       estimate          se   se_neyman
# 1 -0.005176818 0.003928735 0.003930919
```

---

## staggered_sa()

Calculate the Sun & Abraham (2020) estimator for staggered rollouts using only the last-treated cohort (or never-treated, if available) as controls.

### Signature

```r
staggered_sa(
  df,
  i = "i",
  t = "t",
  g = "g",
  y = "y",
  estimand = NULL,
  A_theta_list = NULL,
  A_0_list = NULL,
  eventTime = 0,
  return_full_vcv = FALSE,
  compute_fisher = FALSE,
  num_fisher_permutations = 500,
  skip_data_check = FALSE
)
```
[verified: R/compute_efficient_estimator_and_se.R#L1516-L1528]

### Parameters

| Parameter | Type | Default | Description | Constraints | Source |
|---|---|---|---|---|---|
| df | data.frame | — (required) | Panel data with y, i, t, g columns. g=Inf denotes never treated. | Must contain specified columns | [verified: R/compute_efficient_estimator_and_se.R#L1516] |
| i | character | `"i"` | Individual identifier column name | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1517] |
| t | character | `"t"` | Time period column name | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1518] |
| g | character | `"g"` | First treatment period column name (Inf = never treated) | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1519] |
| y | character | `"y"` | Outcome variable column name | Must exist in df | [verified: R/compute_efficient_estimator_and_se.R#L1520] |
| estimand | character/NULL | `NULL` | Estimand: "simple", "cohort", "calendar", or "eventstudy". Not case-sensitive. | One of the four, or NULL if A_theta_list provided | [verified: R/compute_efficient_estimator_and_se.R#L1521] |
| A_theta_list | list/NULL | `NULL` | Custom estimand specification (list of A_theta_g matrices) | Should be NULL if estimand is specified | [verified: R/compute_efficient_estimator_and_se.R#L1522] |
| A_0_list | list/NULL | `NULL` | Custom matrices for Xhat construction | NULL or list of matrices | [verified: R/compute_efficient_estimator_and_se.R#L1523] |
| eventTime | numeric | `0` | Event-time for event-study. Scalar or vector. | Integer(s); vector requires estimand = "eventstudy" | [verified: R/compute_efficient_estimator_and_se.R#L1524] |
| return_full_vcv | logical | `FALSE` | Return full VCV matrix for event-study estimates | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L1525] |
| compute_fisher | logical | `FALSE` | Compute Fisher Randomization Test | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L1526] |
| num_fisher_permutations | numeric | `500` | Number of FRT permutations | Positive integer | [verified: R/compute_efficient_estimator_and_se.R#L1527] |
| skip_data_check | logical | `FALSE` | Skip data validation checks | TRUE/FALSE | [verified: R/compute_efficient_estimator_and_se.R#L1528] |

### Parameters NOT Exposed (Hardcoded Internally)

| Parameter | Hardcoded Value | Rationale |
|---|---|---|
| beta | 1 | DiD-style adjustment |
| use_DiD_A0 | TRUE | Scalar DiD comparison for Xhat |
| use_last_treated_only | TRUE | Only uses last-treated/never-treated cohort as control |

### Equivalence

```r
# staggered_sa(...) is equivalent to:
staggered(..., beta = 1, use_DiD_A0 = TRUE, use_last_treated_only = TRUE)
```
[verified: R/compute_efficient_estimator_and_se.R#L1548-L1558]

### Additional Pre-processing

Units with `g <= min(t)` are dropped with a warning, since the SA estimator requires at least one pre-treatment period.
[verified: R/compute_efficient_estimator_and_se.R#L1542-L1545]

### Return Value

Same as `staggered()` — see above.

### Examples

```r
library(staggered)
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# Sun & Abraham estimator: simple weighted average
result_sa <- staggered_sa(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "simple"
)
print(result_sa)
# Expected output:
#     estimate         se  se_neyman
# 1 0.01153851 0.01730161 0.01730234
```

---

## balance_checks()

Calculate Wald-tests for balance in staggered rollout designs. Tests whether pre-treatment outcome differences across cohorts are consistent with the random treatment timing assumption.

### Signature

```r
balance_checks(
  df,
  i = "i",
  t = "t",
  g = "g",
  y = "y",
  estimand = NULL,
  A_0_list = NULL,
  eventTime = 0,
  use_DiD_A0 = NULL,
  use_last_treated_only = FALSE,
  compute_fisher = FALSE,
  num_fisher_permutations = 500,
  return_full_vcv = FALSE,
  skip_data_check = FALSE,
  seed = NULL
)
```
[verified: R/balance_checks.R#L72-L86]

### Parameters

| Parameter | Type | Default | Description | Constraints | Source |
|---|---|---|---|---|---|
| df | data.frame | — (required) | Panel data with y, i, t, g columns | Same as staggered() | [verified: R/balance_checks.R#L72] |
| i | character | `"i"` | Individual identifier column | Same as staggered() | [verified: R/balance_checks.R#L73] |
| t | character | `"t"` | Time period column | Same as staggered() | [verified: R/balance_checks.R#L74] |
| g | character | `"g"` | Treatment timing column | Same as staggered() | [verified: R/balance_checks.R#L75] |
| y | character | `"y"` | Outcome column | Same as staggered() | [verified: R/balance_checks.R#L76] |
| estimand | character/NULL | `NULL` | Estimand: "simple", "cohort", "calendar", "eventstudy", or "all". Supports "all" which tests all estimands. | One of the five options or NULL | [verified: R/balance_checks.R#L77] |
| A_0_list | list/NULL | `NULL` | Custom A_0 matrices for Xhat construction | NULL or list | [verified: R/balance_checks.R#L78] |
| eventTime | numeric | `0` | Event-time for event-study balance test | Scalar or vector | [verified: R/balance_checks.R#L79] |
| use_DiD_A0 | logical/NULL | `NULL` | Whether to use DiD-style scalar A_0. NULL defaults to `ifelse(is.null(A_0_list), TRUE, FALSE)` | TRUE/FALSE/NULL | [verified: R/balance_checks.R#L80] |
| use_last_treated_only | logical | `FALSE` | Compare only with last-treated cohort (SA-style) | TRUE/FALSE | [verified: R/balance_checks.R#L81] |
| compute_fisher | logical | `FALSE` | Compute Fisher Randomization Test for balance | TRUE/FALSE | [verified: R/balance_checks.R#L82] |
| num_fisher_permutations | numeric | `500` | Number of FRT permutations | Positive integer | [verified: R/balance_checks.R#L83] |
| return_full_vcv | logical | `FALSE` | Return full variance-covariance matrix of Xhat | TRUE/FALSE | [verified: R/balance_checks.R#L84] |
| skip_data_check | logical | `FALSE` | Skip data validation checks | TRUE/FALSE | [verified: R/balance_checks.R#L85] |
| seed | numeric/NULL | `NULL` | Set seed for permutations | NULL or integer | [verified: R/balance_checks.R#L86] |

### Return Value

A `list` with the following elements:

| Element | Type | Description |
|---|---|---|
| resultsDF | data.frame | Balance test results (see columns below) |
| Xvar | matrix/NULL | Full Xhat variance-covariance matrix (NULL if return_full_vcv = FALSE) |
| FRTResults | matrix/NULL | Matrix of FRT t-statistics (NULL if compute_fisher = FALSE) |

**resultsDF columns:**

| Column | Type | Description |
|---|---|---|
| Xhat | numeric | Pre-treatment difference estimate |
| se_Xhat | numeric | Standard error of Xhat |
| t_test | numeric | Absolute t-statistic (\|Xhat/se_Xhat\|) |
| pvalue_t | numeric | Two-sided p-value from normal distribution |
| Wald_test_Xhat | numeric | Joint Wald test statistic |
| pvalue_Wald | numeric | Chi-squared p-value for Wald test |
| N | integer | Total sample size |
| fisher_pval | numeric | Fisher permutation p-value (NA if not computed) |
| fisher_supt_pval | numeric | Sup-t Fisher p-value (NA if not computed) |
| num_fisher_permutations | integer | Successful permutation draws (NA if not computed) |
| estimand | character | Label for the estimand tested |

### Examples

```r
library(staggered)
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# Balance check for simple estimand
bal_simple <- balance_checks(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "simple"
)
print(bal_simple$resultsDF)

# Balance check with Fisher Randomization Test
bal_fisher <- balance_checks(
  df = df, i = "uid", t = "period", g = "first_trained", y = "complaints",
  estimand = "simple", compute_fisher = TRUE, num_fisher_permutations = 500
)
print(bal_fisher$resultsDF)
```

---

## Internal Functions (Advanced)

These functions are not exported but constitute the computational backbone of the package.

### compute_g_level_summaries()

Computes cohort-level means, covariance matrices, and sample sizes.

```r
compute_g_level_summaries(df)
```
[verified: R/compute_efficient_estimator_and_se.R#L14]

**Returns:** List with `Ybar_g_List`, `S_g_List`, `N_g_DT`, `g_list`, `t_list`

### compute_Xhat()

Computes the vector of pre-treatment differences between cohorts.

```r
compute_Xhat(Ybar_g_list, A_0_list, g_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L106]

**Returns:** Numeric vector Xhat = sum_g A_0_g %*% Ybar_g

### compute_Betastar()

Computes the plug-in optimal beta coefficient that minimizes the variance of the adjusted estimator.

```r
compute_Betastar(Xvar_list, A_theta_list, S_g_list, N_g_list, g_list, t_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L125]

**Returns:** Numeric vector beta* = Var(Xhat)^{-1} Cov(Xhat, theta_0)

### compute_Thetahat0()

Computes the unadjusted (plug-in) estimator.

```r
compute_Thetahat0(Ybar_g_list, A_theta_list, g_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L88]

**Returns:** Numeric scalar theta_hat_0 = sum_g A_theta_g %*% Ybar_g

### compute_Thetahat_beta()

Computes the beta-adjusted estimator: theta_hat(beta) = theta_hat_0 - Xhat' * beta.

```r
compute_Thetahat_beta(Ybar_g_list, A_theta_list, A_0_list, beta, g_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L163]

**Returns:** Numeric scalar

### compute_se_Thetahat_beta()

Computes the refined standard error with pre-trend adjustment.

```r
compute_se_Thetahat_beta(S_g_list, N_g_list, A_theta_list, A_0_list, beta, g_list, t_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L279]

**Returns:** Numeric scalar (standard error)

### compute_se_Thetahat_beta_conservative()

Computes the Neyman (conservative) standard error.

```r
compute_se_Thetahat_beta_conservative(S_g_list, N_g_list, A_theta_list, A_0_list, beta, g_list, t_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L206]

**Returns:** Numeric scalar (conservative standard error)

### create_A0_list()

Constructs A_0 matrices using the full vector of all possible pre-treatment comparisons.

```r
create_A0_list(g_list, t_list)
```
[verified: R/compute_efficient_estimator_and_se.R#L382]

**Returns:** List of A_0_g matrices

### create_Atheta_list_for_simple_average_ATE()

Constructs A_theta matrices for the simple-weighted ATT.
[verified: R/compute_efficient_estimator_and_se.R#L689]

### create_Atheta_list_for_cohort_average_ATE()

Constructs A_theta matrices for the cohort-weighted ATT.
[verified: R/compute_efficient_estimator_and_se.R#L668]

### create_Atheta_list_for_calendar_average_ATE()

Constructs A_theta matrices for the calendar-weighted ATT.
[verified: R/compute_efficient_estimator_and_se.R#L618]

### create_Atheta_list_for_event_study()

Constructs A_theta matrices for the event-study ATT at a given event-time.
[verified: R/compute_efficient_estimator_and_se.R#L526]

### create_A0_list_for_simple_average_ATE()

Constructs DiD-style A_0 matrices for simple aggregation.
[verified: R/create_A0_lists.R#L209]

### create_A0_list_for_cohort_average_ATE()

Constructs DiD-style A_0 matrices for cohort aggregation.
[verified: R/create_A0_lists.R#L151]

### create_A0_list_for_calendar_average_ATE()

Constructs DiD-style A_0 matrices for calendar aggregation.
[verified: R/create_A0_lists.R#L89]

### create_A0_list_for_event_study()

Constructs DiD-style A_0 matrices for event-study aggregation.
[verified: R/create_A0_lists.R#L35]

### calculate_full_vcv()

Calculates the full variance-covariance matrix across event-study event-times.
[verified: R/compute_efficient_estimator_and_se.R#L735]

### eigenMapMatMult()

Fast matrix multiplication via RcppEigen C++ backend.
[verified: src/code.cpp#L9]

### solve_least_squares_normal()

Solves (A'A)^{-1}A'B via LDLT decomposition (C++ backend).
[verified: src/code.cpp#L27]

---

## Dataset: pj_officer_level_balanced

### Description

Data from a large-scale procedural justice training program in the Chicago Police Department analyzed by Wood, Tyler, Papachristos, Roth and Sant'Anna (2020) and Roth and Sant'Anna (2023). The data contains a balanced panel of 7,785 police officers in Chicago who were randomly given a procedural justice training on different dates, and who remained in the police force throughout the study period (from January 2011 to December 2016).

### Dimensions

- **Observations:** 560,520 (7,785 officers × 72 months)
- **Variables:** 12

### Variables

| Variable | Type | Description |
|---|---|---|
| uid | integer | Identifier for the police officer |
| month | Date | Month and year of the observation |
| assigned | character | Month-year of first training assignment |
| appointed | Date | Appointment date |
| resigned | Date/NA | Date the officer resigned (NA if did not resign) |
| birth_year | integer | Officer's year of birth |
| assigned_exact | Date | Exact date of first training assignment |
| complaints | numeric | Number of complaints (settled and sustained) |
| sustained | numeric | Number of sustained complaints |
| force | numeric | Number of times force was used |
| period | integer | Time period: 1–72 |
| first_trained | integer | Time period first exposed to treatment (treatment cohort/group) |

### Usage

```r
data(pj_officer_level_balanced)
```

### Source

Wood, Tyler, Papachristos, Roth and Sant'Anna (2020) and Roth and Sant'Anna (2023).

---

## Data Validation Pipeline

The package performs the following validation steps before estimation:

### 1. processDF() [L820-L873]

1. **Column existence check:** Verifies columns named by i, t, g, y exist in df
2. **Column name conflict check:** i cannot be "g"/"t"/"y"; t cannot be "i"/"g"/"y"; g cannot be "i"/"t"/"y"
3. **Rename columns** to standard internal names "i", "t", "g", "y"
4. **Convert to data.table** and select only the four needed columns

### 2. balance_df() [L51-L85]

1. **Unique (i,t) check:** Errors if duplicate (i,t) rows exist
2. **Missing outcome removal:** Removes rows with `is.na(y)`
3. **Panel balance check:** If any unit has fewer periods than max, drops those units with a warning

### 3. Singleton Cohort Detection [L1019-L1031]

1. **Compute cohort sizes:** Count unique i per g
2. **Flag cohorts with N=1:** Remove them with a warning (variance not computable)

### 4. Estimand Validation [L982-L986, L1117-L1118]

1. If `eventTime` is a vector but `estimand != "eventstudy"`, throws error
2. If both `A_theta_list` and `estimand` are NULL/invalid, throws error
3. If `use_DiD_A0 = TRUE` but `estimand` is NULL, throws error

---

## Cross-Estimator Comparison

| Property | staggered() | staggered_cs() | staggered_sa() |
|---|---|---|---|
| **beta** | NULL (optimal) | 1 (fixed) | 1 (fixed) |
| **use_DiD_A0** | TRUE (default) | TRUE (fixed) | TRUE (fixed) |
| **use_last_treated_only** | FALSE | FALSE | TRUE |
| **Control group** | All not-yet-treated (optimal weighting) | All not-yet-treated (equal weighting) | Last-treated only |
| **Efficiency** | Optimal | Sub-optimal (1.4–1.9× SE) | Sub-optimal (3×+ SE) |
| **Early-treated filter** | No | Yes (g <= min(t) dropped) | Yes (g <= min(t) dropped) |
| **Paper** | Roth & Sant'Anna (2023) | Callaway & Sant'Anna (2021) | Sun & Abraham (2021) |

---

## References

- Roth, J. and Sant'Anna, P.H.C. (2023). "Efficient Estimation for Staggered Rollout Designs." *Journal of Political Economy: Microeconomics*, 1(4):669–709. doi:10.1086/726581
- Callaway, B. and Sant'Anna, P.H.C. (2021). "Difference-in-Differences with Multiple Time Periods." *Journal of Econometrics*, 225(2):200–230. doi:10.1016/j.jeconom.2020.12.001
- Sun, L. and Abraham, S. (2021). "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects." *Journal of Econometrics*, 225(2):175–199. doi:10.1016/j.jeconom.2020.09.006
- Wood, G., Tyler, T.R., Papachristos, A.P., Roth, J. and Sant'Anna, P.H.C. (2020). "Revised Findings for 'Procedural Justice Training Reduces Police Use of Force and Complaints Against Officers'." doi:10.31235/osf.io/xf32m
