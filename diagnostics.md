---
skill_name: staggered
diagnostics_type: shared+per_estimator
---

# Diagnostics Guide: staggered

## Overview

The `staggered` package provides two formal diagnostic tools for validating the randomization assumption and assessing treatment effects:

1. **Balance checks** (`balance_checks()`): Tests whether pre-treatment outcomes are balanced across treatment cohorts — the key implication of random treatment timing.
2. **Fisher Randomization Test** (`compute_fisher = TRUE`): Provides finite-sample exact p-values under the sharp null of no treatment effect.

These diagnostics are critical because the efficient estimator's variance optimization assumes random timing (Assumption A1). If timing is not random and β* ≠ 1, the estimator introduces bias. Diagnostics help researchers assess whether this assumption is credible.

## Assumption–Diagnostic Alignment

| # | Assumption | Diagnostic | Section | Key Check |
|---|---|---|---|---|
| A1 | Random Treatment Timing | Balance tests + Fisher | §1–2 below | `balance_checks()`, `compute_fisher=TRUE` |
| A2 | No Anticipation | Event-study pre-trends | §Per-Estimator | Pre-treatment event-study lags ≈ 0 |
| A3 | Balanced Panel | Data quality checks | §3 below | Panel dimensions, missing i-t pairs |
| A4 | No Singleton Cohorts | Cohort size checks | §3 below | Cohort size table; auto-removal warnings |

---

## Shared Diagnostics (All Estimators)

### 1. Pre-Treatment Balance Checks

**Function:** `balance_checks()` — tests the random treatment timing assumption by checking whether pre-treatment outcomes show systematic differences across cohorts.

[verified: R/balance_checks.R#L72-L86]

#### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `df` | — | Panel data frame [verified: required] |
| `i` | `"i"` | Unit identifier column [verified: R/balance_checks.R#L73] |
| `t` | `"t"` | Time period column [verified: R/balance_checks.R#L74] |
| `g` | `"g"` | Treatment timing column [verified: R/balance_checks.R#L75] |
| `y` | `"y"` | Outcome column [verified: R/balance_checks.R#L76] |
| `estimand` | `NULL` | Estimand: `"simple"`, `"cohort"`, `"calendar"`, `"eventstudy"`, or `"all"` [verified: R/balance_checks.R#L77] |
| `eventTime` | `0` | Event-time lag(s) for event-study balance [verified: R/balance_checks.R#L79] |
| `use_DiD_A0` | `NULL` (→ TRUE if `A_0_list` is NULL) | Use scalar DiD-style adjustment [verified: R/balance_checks.R#L80] |
| `use_last_treated_only` | `FALSE` | SA-style comparison (last-treated control only) [verified: R/balance_checks.R#L81] |
| `compute_fisher` | `FALSE` | Compute Fisher permutation p-values [verified: R/balance_checks.R#L82] |
| `num_fisher_permutations` | `500` | Number of permutations for Fisher test [verified: R/balance_checks.R#L83] |
| `return_full_vcv` | `FALSE` | Return full VCV matrix of X̂ [verified: R/balance_checks.R#L84] |
| `skip_data_check` | `FALSE` | Skip panel balance check (internal use only) [verified: R/balance_checks.R#L85] |
| `seed` | `NULL` | Random seed for reproducibility [verified: R/balance_checks.R#L86] |

#### Return Value

A list containing:
- `resultsDF`: data.frame with columns `Xhat`, `se_Xhat`, `t_test`, `pvalue_t`, `Wald_test_Xhat`, `pvalue_Wald`, `N`, `fisher_pval`, `fisher_supt_pval`, `num_fisher_permutations`, `estimand`
- `Xvar`: Full VCV matrix (if `return_full_vcv = TRUE`)
- `FRTResults`: Matrix of permutation t-statistics (if `compute_fisher = TRUE`)

#### Wald Test

**What it tests:** Joint null hypothesis that all pre-treatment outcome differences between cohorts are zero: H₀: E[X̂] = 0. Under random timing, X̂ should be centered at zero because cohort means should not differ systematically before treatment.

**How to run:**

```r
library(staggered)
df <- staggered::pj_officer_level_balanced

# Balance check for all estimands simultaneously
bal <- balance_checks(df = df,
                      i = "uid",
                      t = "period",
                      g = "first_trained",
                      y = "complaints",
                      estimand = "all")

# Key outputs
bal$resultsDF[, c("Xhat", "se_Xhat", "t_test", "pvalue_t",
                  "Wald_test_Xhat", "pvalue_Wald", "estimand")]
```

**Interpretation:**

| Result | Meaning | Action |
|--------|---------|--------|
| `pvalue_Wald` > 0.05 | No evidence against balance; randomization assumption supported | Proceed with `staggered()` |
| `pvalue_Wald` < 0.05 | Pre-treatment differences detected; random timing assumption questionable | Consider `staggered_cs()` under parallel trends; investigate timing mechanism |
| Individual `pvalue_t` < 0.05 | Specific estimand-dimension shows imbalance | Examine which cohort comparisons drive the imbalance |

**Important caveat:** Passing the balance test is *necessary but not sufficient* for random timing. The test has limited power — it may not detect moderate violations, especially with few cohorts or small cohort sizes.

#### Fisher Randomization Test for Balance

**What it tests:** Same null as the Wald test, but using a permutation-based reference distribution. More robust in finite samples and does not rely on asymptotic chi-squared approximation.

```r
# Balance check with Fisher permutation test
bal_fisher <- balance_checks(df = df,
                             i = "uid",
                             t = "period",
                             g = "first_trained",
                             y = "complaints",
                             estimand = "simple",
                             compute_fisher = TRUE,
                             num_fisher_permutations = 500,
                             seed = 42)

# Fisher p-values
cat("Fisher element-wise p-value:", bal_fisher$resultsDF$fisher_pval, "\n")
cat("Fisher sup-t p-value:", bal_fisher$resultsDF$fisher_supt_pval, "\n")
```

**Interpretation:**
- `fisher_pval`: Element-wise permutation p-value (per X̂ component)
- `fisher_supt_pval`: Sup-t p-value (controls family-wise error across all X̂ elements)
- If `fisher_supt_pval` < 0.05: Evidence of imbalance that is robust to multiple testing

#### Matching Balance Checks to Estimators

```r
# For staggered() and staggered_cs(): use_last_treated_only = FALSE
bal_cs_style <- balance_checks(df = df,
                               i = "uid", t = "period",
                               g = "first_trained", y = "complaints",
                               estimand = "simple",
                               use_last_treated_only = FALSE)

# For staggered_sa(): use_last_treated_only = TRUE
bal_sa_style <- balance_checks(df = df,
                               i = "uid", t = "period",
                               g = "first_trained", y = "complaints",
                               estimand = "simple",
                               use_last_treated_only = TRUE)
```

---

### 2. Fisher Randomization Test (Treatment Effect)

**Available for all three estimators** via the `compute_fisher = TRUE` parameter in `staggered()`, `staggered_cs()`, and `staggered_sa()`.

**What it tests:**
- **Sharp null:** Y_i(g) = Y_i(g') for all i, g, g' → treatment has zero effect on every unit (finite-sample exact)
- **Weak null:** θ = 0 → average treatment effect is zero (asymptotically valid)

**How it works:**
1. Compute studentized test statistic: T = θ̂_{β*} / ŝe
2. Generate K random permutations of treatment assignments (preserving cohort sizes N_g)
3. For each permutation π, recompute T_π (full re-estimation including β* re-optimization)
4. P-value = fraction of permutations where |T_π| ≥ |T|

[verified: R/compute_efficient_estimator_and_se.R#L1277-L1306]

```r
# Fisher Randomization Test for treatment effect
result_fisher <- staggered(df = df,
                           i = "uid",
                           t = "period",
                           g = "first_trained",
                           y = "complaints",
                           estimand = "simple",
                           compute_fisher = TRUE,
                           num_fisher_permutations = 500)
# [verified: num_fisher_permutations default = 500]

cat("Point estimate:", result_fisher$estimate, "\n")
cat("Standard error:", result_fisher$se, "\n")
cat("Fisher p-value:", result_fisher$fisher_pval, "\n")
cat("Fisher p-value (Neyman SE):", result_fisher$fisher_pval_se_neyman, "\n")
```

**Interpretation:**

| Fisher p-value | Interpretation |
|---|---|
| p < 0.05 | Strong evidence of treatment effect under randomization; reject sharp null |
| p > 0.05 | Cannot reject no-effect null; effect may be zero or test lacks power |
| `fisher_pval` ≈ `fisher_pval_se_neyman` | Refined and Neyman SEs agree; inference is robust |
| `fisher_pval` differs from `fisher_pval_se_neyman` | Within-cohort effect heterogeneity present; report both |

**Computational guidance:**
- 500 permutations: ~30–60 seconds (exploratory analysis)
- 5000 permutations: ~5–10 minutes (publication quality)
- Cost is linear in `num_fisher_permutations` × single-estimation time

---

### 3. Data Quality Checks

These are automatically performed by the package but should be verified manually before estimation:

#### Panel Balance Verification

```r
# Check that panel is balanced
n_units <- length(unique(df$uid))
n_periods <- length(unique(df$period))
expected_rows <- n_units * n_periods
actual_rows <- nrow(df)

cat("Expected rows (balanced):", expected_rows, "\n")
cat("Actual rows:", actual_rows, "\n")

if (actual_rows != expected_rows) {
  # Identify which units have missing periods
  obs_per_unit <- table(df$uid)
  incomplete <- names(obs_per_unit[obs_per_unit < n_periods])
  cat("Incomplete units:", length(incomplete), "of", n_units, "\n")
  cat("These will be DROPPED by the package with a warning.\n")
}
```

#### Singleton Cohort Detection

```r
# Check for singleton cohorts (will be auto-removed)
cohort_sizes <- table(df$first_trained[!duplicated(df$uid)])
singletons <- cohort_sizes[cohort_sizes == 1]

if (length(singletons) > 0) {
  cat("Singleton cohorts (will be dropped):", length(singletons), "\n")
  cat("Cohort values:", names(singletons), "\n")
  cat("Consider coarsening treatment timing if many singletons exist.\n")
}
```

[verified: R/compute_efficient_estimator_and_se.R#L1019-L1031]

#### Missing Value Handling

```r
# Check for NAs in key variables
na_counts <- colSums(is.na(df[, c("uid", "period", "first_trained", "complaints")]))
if (any(na_counts > 0)) {
  cat("WARNING: Missing values detected:\n")
  print(na_counts[na_counts > 0])
  cat("These observations will be removed during panel balancing.\n")
}
```

---

## Per-Estimator Diagnostics

### For staggered() (Efficient Estimator)

#### Efficiency Gain Assessment

**Purpose:** Quantify how much precision the efficient estimator gains over the fixed-β alternatives.

```r
# Run all three estimators
result_eff <- staggered(df = df,
                        i = "uid", t = "period",
                        g = "first_trained", y = "complaints",
                        estimand = "simple")

result_cs <- staggered_cs(df = df,
                          i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")

result_sa <- staggered_sa(df = df,
                          i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")

# Efficiency ratios
cat("SE ratio (CS / Efficient):", result_cs$se / result_eff$se, "\n")
cat("SE ratio (SA / Efficient):", result_sa$se / result_eff$se, "\n")
cat("Equivalent sample size multiplier (CS):", (result_cs$se / result_eff$se)^2, "\n")
cat("Equivalent sample size multiplier (SA):", (result_sa$se / result_eff$se)^2, "\n")
```

**Interpretation:**
- SE ratio > 1.4: Substantial efficiency gain; strongly prefer `staggered()`
- SE ratio ≈ 1.0–1.2: Minimal gain; outcome likely has high autocorrelation (ρ ≈ 1)
- SE ratio > 3.0: Dramatic gain (common for SA when last cohort is small)

#### Refined vs Neyman SE Comparison

```r
# Check treatment effect heterogeneity signal
cat("Refined SE:", result_eff$se, "\n")
cat("Neyman SE:", result_eff$se_neyman, "\n")
cat("Ratio (Neyman/Refined):", result_eff$se_neyman / result_eff$se, "\n")

# Ratio ≈ 1: homogeneous within-cohort effects
# Ratio >> 1: heterogeneous effects; refined SE is sharper
```

#### β* Diagnostic (via Manual Comparison)

Assess whether β* is far from 1 — large deviations indicate strong efficiency gains but also greater sensitivity to the randomization assumption:

```r
# Compare β* (optimal) vs β=1 (DiD-style)
result_beta_null <- staggered(df = df, i = "uid", t = "period",
                              g = "first_trained", y = "complaints",
                              estimand = "simple", beta = NULL)  # optimal β*
result_beta_1 <- staggered(df = df, i = "uid", t = "period",
                            g = "first_trained", y = "complaints",
                            estimand = "simple", beta = 1)  # DiD-style

cat("SE (β*):  ", result_beta_null$se, "\n")
cat("SE (β=1): ", result_beta_1$se, "\n")
cat("Efficiency gain:", result_beta_1$se / result_beta_null$se, "x\n")

# NOTE: beta=0 (difference-in-means) is theoretically valid but not supported
# in staggered v1.2.3 due to a dimension-handling issue. Compare β* vs β=1 only.
```

---

### For staggered_cs()

#### Comparison with did Package

The `staggered_cs()` produces the same point estimates as Callaway & Sant'Anna (2021)'s `did` package, but with design-based (Neyman) standard errors rather than sampling-based ones. To verify alignment:

```r
# staggered_cs result
result_cs <- staggered_cs(df = df,
                          i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")

# Known differences from did::att_gt():
# 1. staggered_cs uses design-based SEs (randomization inference)
# 2. did uses sampling-based SEs (with optional clustering)
# 3. Point estimates should align if same comparison group and data
# 4. staggered_cs filters units with g <= min(t) (early-treated filter)
cat("CS point estimate:", result_cs$estimate, "\n")
cat("CS design-based SE:", result_cs$se, "\n")
```

#### Efficiency Loss Quantification

```r
# How much precision are you sacrificing by using CS instead of efficient?
eff_loss <- (result_cs$se / result_eff$se)^2
cat("Using CS costs the equivalent of", round(eff_loss, 1),
    "× the sample size vs efficient estimator.\n")

# Decision: if eff_loss < 1.5, CS is acceptable as primary
# if eff_loss > 2.0, strongly prefer staggered() when randomization holds
```

---

### For staggered_sa()

#### Efficiency Loss Assessment

The SA estimator restricts the control group to only the last-treated cohort. This can produce severe efficiency losses when the last cohort is small:

```r
# Assess SA efficiency cost
result_sa <- staggered_sa(df = df,
                          i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")

# SE ratio shows efficiency cost
ratio_sa <- result_sa$se / result_eff$se
cat("SE ratio (SA/Efficient):", round(ratio_sa, 2), "\n")
cat("Equivalent sample size multiplier:", round(ratio_sa^2, 1), "\n")

# Check last-cohort size (explains the efficiency loss)
cohort_sizes <- table(df$first_trained[!duplicated(df$uid)])
last_cohort_size <- cohort_sizes[names(cohort_sizes) == max(as.numeric(names(cohort_sizes)[is.finite(as.numeric(names(cohort_sizes)))]))]
total_n <- sum(cohort_sizes)
cat("Last-treated cohort: ", last_cohort_size, "units (",
    round(100 * last_cohort_size / total_n, 1), "% of N)\n")

# Rule of thumb: if last cohort < 5% of N, SA is extremely inefficient
```

#### SA vs CS Equivalence Check

When a never-treated group exists (g = Inf), SA and CS should give very similar results since the "last-treated" control effectively includes the never-treated. Verify:

```r
# If never-treated exists, SA ≈ CS (but not identical due to control restriction)
has_never_treated <- any(is.infinite(df$first_trained))
if (has_never_treated) {
  cat("Never-treated group exists.\n")
  cat("SA estimate:", result_sa$estimate, "\n")
  cat("CS estimate:", result_cs$estimate, "\n")
  cat("Difference:", abs(result_sa$estimate - result_cs$estimate), "\n")
}
```

---

## Diagnostic Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ DIAGNOSTIC WORKFLOW                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ STEP 1: Data Quality                                        │
│ ├── Check panel balance (n_units × n_periods == nrow?)      │
│ ├── Check for singleton cohorts                             │
│ ├── Check for missing values in i, t, g, y                  │
│ └── If issues → fix data BEFORE estimation                  │
│                                                             │
│ STEP 2: Design Assumption Validation                        │
│ ├── Run balance_checks(estimand = "all")                    │
│ ├── Examine Wald test p-value                               │
│ │   ├── p > 0.10 → Proceed to Step 3                       │
│ │   ├── 0.05 < p < 0.10 → Borderline; run Fisher test      │
│ │   └── p < 0.05 → Randomization assumption questionable   │
│ │       → Consider staggered_cs() under parallel trends     │
│ │       → Investigate timing mechanism                      │
│ └── Optional: Fisher balance test for robustness            │
│                                                             │
│ STEP 3: Primary Estimation                                  │
│ ├── Run staggered() (efficient estimator)                   │
│ ├── Run staggered_cs() (robustness)                         │
│ └── Compute SE ratio: result_cs$se / result_eff$se          │
│                                                             │
│ STEP 4: Inference Validation                                │
│ ├── Compare se vs se_neyman (heterogeneity check)           │
│ ├── Optional: Fisher Randomization Test (compute_fisher)    │
│ └── For event-study: check pre-treatment lags ≈ 0           │
│                                                             │
│ STEP 5: Sensitivity                                         │
│ ├── Compare β* estimate vs β=1 estimate                     │
│ │   ├── Similar → robust to assumption                      │
│ │   └── Different → results depend on randomization         │
│ └── If concerned: report both staggered() and CS estimates  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Interpretation Guide

| Diagnostic Result | Interpretation | Action |
|---|---|---|
| Balance Wald test p > 0.10 | No evidence against random timing | Use `staggered()` as primary estimator |
| Balance Wald test p < 0.05 | Treatment timing may not be random | Consider `staggered_cs()` under parallel trends assumption |
| Fisher treatment test p < 0.05 | Strong evidence of treatment effect under randomization | Report alongside asymptotic CI |
| Fisher treatment test p > 0.10 | Cannot reject sharp null | Effect may be zero; check power |
| SE ratio (CS/Efficient) > 1.5 | Substantial efficiency gain from β-optimization | Report `staggered()` as primary |
| SE ratio (CS/Efficient) ≈ 1.0 | Minimal gain; outcomes have unit-root behavior | Either estimator is acceptable |
| SE ratio (SA/Efficient) > 3.0 | SA is severely inefficient (small last cohort) | Avoid `staggered_sa()` as primary |
| `se_neyman` >> `se` | Substantial within-cohort effect heterogeneity | Report both; refined SE preferred for inference |
| `se_neyman` ≈ `se` | Homogeneous effects within cohorts | Either SE is valid; they converge |
| Point estimates diverge across estimators | Potential violation of assumptions or heterogeneity | Investigate which cohorts drive differences |

---

## Red Flags

The following signals indicate potential problems with the analysis:

| Red Flag | Likely Cause | Diagnostic Action |
|---|---|---|
| Balance test strongly rejects (p < 0.01) | Treatment timing is endogenous | Re-examine research design; switch to parallel-trends methods |
| Large fraction of cohorts are singletons | Overly granular treatment timing | Coarsen timing variable (e.g., quarter instead of month) |
| SE ratio (CS/Efficient) < 1.0 | Implementation error or data issue | Verify data preparation; check for duplicates |
| Point estimate changes sign between estimators | Strong heterogeneity or assumption violation | Run event-study; check pre-trends; examine per-cohort effects |
| `se_neyman` much smaller than `se` | Should never happen (Neyman is conservative) | Possible bug; check package version; report to maintainer |
| Event-study shows clear pre-trends | No-anticipation assumption violated OR timing is non-random | Report pre-trend evidence; consider whether anticipation is plausible |
| Fisher p-value disagrees sharply with asymptotic CI | Finite-sample issues or small effective sample | Trust Fisher test (exact); increase permutations for precision |
| Many warnings about dropped units/cohorts | Data quality issues | Investigate data construction; ensure panel is truly balanced |
| Estimate is NA or Inf for some event-times | Requested event-times exceed available data | Compute max feasible lag: `max(t) - min(g among treated)` |
