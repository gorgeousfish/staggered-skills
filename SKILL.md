---
name: staggered
description: "Efficient estimation for staggered rollout (adoption) designs using the Roth and Sant'Anna (2023) semiparametric efficient estimator. Supports three estimators (staggered, staggered_cs, staggered_sa), four aggregation schemes (simple, cohort, calendar, event-study), and Fisher randomization tests. Use when analyzing causal effects in staggered adoption designs, difference-in-differences with variation in treatment timing, or when the user mentions staggered rollout, efficient DiD, Roth and Sant'Anna, random treatment timing, or comparing CS/SA estimators."
display_name: "Efficient Estimation for Staggered Rollout Designs"
package: staggered
version: 1.2.3
language: R
authors: "Jonathan Roth, Pedro H.C. Sant'Anna"
paper: "Roth & Sant'Anna (2023), JPE:Micro 1(4):669-709"
method_type: methodology_toolkit
estimator_count: 3
estimators: [staggered, staggered_cs, staggered_sa]
---

# staggered — Efficient Estimation for Staggered Rollout Designs

Estimates causal effects in staggered adoption designs by optimally combining pre-treatment outcome information to achieve the semiparametric efficiency bound under randomized treatment timing. Provides 1.4–3× standard error reductions over existing DiD-based estimators (Callaway-Sant'Anna, Sun-Abraham), which are nested as special cases. All inference is design-based (finite-population), with Fisher Randomization Tests available.

## File Index

| File | Purpose | Link |
|------|---------|------|
| `lang/r.md` | Installation & full R API reference | [→ View](./lang/r.md) |
| `examples/r_basic.R` | End-to-end reproducible R workflow | [→ View](./examples/r_basic.R) |
| `diagnostics.md` | Diagnostics and interpretation guide | [→ View](./diagnostics.md) |
| `method-card.md` | Method overview and conceptual positioning | [→ View](./method-card.md) |
| `estimators/staggered.md` | Efficient estimator deep guide | [→ View](./estimators/staggered.md) |
| `estimators/staggered-cs.md` | Callaway-Sant'Anna wrapper guide | [→ View](./estimators/staggered-cs.md) |
| `estimators/staggered-sa.md` | Sun-Abraham wrapper guide | [→ View](./estimators/staggered-sa.md) |

---

## Quick Start (3 Steps)

```r
# Step 1: Load package and data
library(staggered)
df <- staggered::pj_officer_level_balanced

# Step 2: Estimate — simple weighted average treatment effect
result <- staggered(df = df,
                    i = "uid",
                    t = "period",
                    g = "first_trained",
                    y = "complaints",
                    estimand = "simple")
print(result)
#>       estimate          se   se_neyman
#> 1 -0.001126981 0.002115194 0.002119248

# Step 3: Event-study — dynamic effects over 24 months post-treatment
es <- staggered(df = df,
                i = "uid",
                t = "period",
                g = "first_trained",
                y = "complaints",
                estimand = "eventstudy",
                eventTime = 0:23)
head(es)
#>        estimate          se   se_neyman eventTime
#> 1  3.083575e-04 0.002645327 0.002650957         0
#> 2  2.591678e-03 0.002614563 0.002621513         1
#> 3 -4.872562e-05 0.002622640 0.002623634         2
#> 4  2.043434e-03 0.002715695 0.002720467         3
#> 5  2.977076e-03 0.002653917 0.002659630         4
#> 6  7.979656e-04 0.002721784 0.002727140         5
```

→ For detailed estimator guides, see the [estimators/](./estimators/) directory.

**Next steps:**
- For a full reproducible workflow script, see [examples/r_basic.R](./examples/r_basic.R)
- For diagnostics and balance tests, see [diagnostics.md](./diagnostics.md)
- For a condensed method overview, see [method-card.md](./method-card.md)
- Using your own data? See Phase 1: Data Preparation below for format requirements.

---

## Activation

User expressions that trigger this skill:

- "Estimate treatment effects in a staggered rollout design"
- "Use Roth and Sant'Anna efficient estimator"
- "Staggered adoption causal effects"
- "Efficient DiD with variation in treatment timing"
- "Compare estimators for staggered designs"
- "Randomized treatment timing estimation"
- "How to use the staggered R package"
- "Semiparametric efficient estimator for staggered DiD"
- "Event-study with optimal variance under random timing"
- "Fisher randomization test for staggered adoption"
- "Balance check for random treatment timing assumption"
- "Callaway Sant'Anna vs Sun Abraham efficiency comparison"

---

## Estimator Selector

### Routing Table

| Scenario | Recommended Estimator | Reason |
|---|---|---|
| Default: maximize efficiency | `staggered()` | Achieves semiparametric efficiency bound; 1.4–3× SE reduction |
| Robustness check alongside efficient estimator | `staggered_cs()` | Familiar DiD baseline; quantify efficiency gain via SE ratio |
| Compare with Callaway-Sant'Anna literature | `staggered_cs()` | Produces CS2021-compatible point estimates |
| Compare with Sun-Abraham literature | `staggered_sa()` | Produces SA2021-compatible estimates (last-treated control) |
| Stepped-wedge design with large last cohort | `staggered_sa()` | Natural comparison group; tolerable efficiency loss if N_{g_max} large |
| Unknown which to use | `staggered()` | Optimal under randomization assumption; include CS as robustness |
| Only parallel trends credible (not random timing) | `staggered_cs()` | CS point estimate valid under PT; but package SEs assume random timing |

### Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ ESTIMATOR SELECTION GUIDE                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Q1: Is treatment timing plausibly random?                   │
│     ├── YES ──────────────────────────────────────────────  │
│     │   → PRIMARY: staggered() [efficient]                  │
│     │   → ROBUSTNESS: staggered_cs() alongside             │
│     │   → DIAGNOSTIC: balance_checks() to validate         │
│     │                                                       │
│     └── NO (only parallel trends credible) ───────────────  │
│         │                                                   │
│         Q2: Do you need SA-style comparison?                │
│         ├── NO → staggered_cs()                             │
│         └── YES                                             │
│             Q3: Is last-treated cohort > 5% of N?           │
│             ├── YES → staggered_sa()                        │
│             └── NO → staggered_cs() (SA too noisy)          │
│                                                             │
│ Q4: Replicating published results?                          │
│     ├── CS (2021) → staggered_cs()                          │
│     ├── SA (2021) → staggered_sa()                          │
│     └── Roth & Sant'Anna (2023) → staggered()              │
│                                                             │
│ RECOMMENDED REPORTING:                                      │
│   1. staggered() as primary (if random timing credible)     │
│   2. staggered_cs() as robustness                           │
│   3. Report SE ratio to quantify efficiency gain            │
│   4. balance_checks() to support design assumption          │
└─────────────────────────────────────────────────────────────┘
```

### Cross-Estimator Comparison

| Property | staggered | staggered_cs | staggered_sa |
|----------|-----------|--------------|--------------|
| **Efficiency** | Optimal (baseline) | Sub-optimal (1.4–1.9× SE) | Sub-optimal (3×+ SE) |
| **β handling** | Data-driven $\hat{\beta}^*$ | Fixed at 1 (DiD) | Fixed at 1 (DiD) |
| **Control group** | All not-yet-treated (optimal weighting) | All not-yet-treated (equal) | Last-treated only |
| **Paper origin** | Roth & Sant'Anna (2023) | Callaway & Sant'Anna (2021) | Sun & Abraham (2021) |
| **Best when** | Random timing credible | ρ ≈ 1 (unit root outcomes) | Stepped-wedge + large last cohort |
| **Equivalent sample size loss** | — | 2–3.4× | 9×+ |
| **Implementation** | Full function (291 lines) | Thin wrapper (28 lines) | Thin wrapper (28 lines) |

---

## Core Concept

### The Problem

In staggered rollout designs, different units adopt a binary, absorbing treatment at different times. Researchers seek to estimate causal effects, but naive two-way fixed effects (TWFE) regressions are biased under treatment effect heterogeneity — a problem extensively documented by the modern DiD literature (Callaway & Sant'Anna 2021; Sun & Abraham 2021; de Chaisemartin & D'Haultfoeuille 2020; Goodman-Bacon 2021).

Existing heterogeneity-robust estimators (CS, SA) solve the bias problem by computing clean group-time ATEs and aggregating them. However, they all fix the pre-treatment adjustment at $\beta = 1$ (the DiD adjustment), which is generally sub-optimal. Roth & Sant'Anna (2023) show that when treatment timing is as-good-as-randomly assigned, there exists a semiparametrically efficient estimator that optimally weights pre-treatment information — achieving SE reductions of 1.4–3× in realistic applications.

The `staggered` package implements this efficient estimator and nests CS/SA as special cases within a unified framework, enabling direct efficiency comparisons. All inference is design-based (finite-population randomization).

### Estimand

The building block is the average treatment effect of switching treatment timing from $g'$ to $g$ on outcomes at time $t$:

\[\tau_{t,gg'} = N^{-1} \sum_{i=1}^N [Y_{it}(g) - Y_{it}(g')]\]

The estimand is a researcher-chosen weighted sum: $\theta = \sum_{t,g,g'} a_{t,gg'} \tau_{t,gg'}$

Four standard aggregation targets:

| Estimand | Code Value | Formula | When to Use |
|----------|-----------|---------|-------------|
| Simple | `"simple"` | \(\theta^{simple} = \frac{1}{\sum_t \sum_{g \leq t} N_g} \sum_t \sum_{g \leq t} N_g \cdot ATE(t,g)\) | Default summary; overall average weighted by cohort-size × post-periods |
| Cohort | `"cohort"` | \(\theta^{cohort} = \frac{1}{\sum_{g:g\neq \infty} N_g} \sum_{g:g\neq \infty} N_g \cdot \overline{ATE}_g\) | When cohort-specific effects matter (early vs late adopters). Only ever-treated cohorts contribute. |
| Calendar | `"calendar"` | \(\theta^{calendar} = \frac{1}{T} \sum_t \theta_t\) | Time-varying policy questions; calendar-time effects |
| Event-study | `"eventstudy"` | \(\theta^{ES}_l = \frac{1}{\sum_{g:g+l \leq T} N_g} \sum_{g:g+l \leq T} N_g \cdot ATE(g+l, g)\) | Dynamic effect visualization; lag $l$ after treatment onset |

[verified: R/compute_efficient_estimator_and_se.R#L1048-L1113]

### Key Innovation: The β Parameter

The general estimator class takes the form:

\[\hat{\theta}_\beta = \hat{\theta}_0 - \hat{X}'\beta\]

where $\hat{\theta}_0 = \sum_g A_{\theta,g} \bar{Y}_g$ is the unadjusted (plug-in) estimator and $\hat{X} = \sum_g A_{0,g} \bar{Y}_g$ captures pre-treatment outcome differences between cohorts.

**The efficiency frontier:**

- **β = 0**: Simple difference-in-means. No pre-treatment adjustment. Valid but inefficient.
  > **⚠️ WARNING (v1.2.3):** `beta = 0` is not supported in the current package version. Attempting `staggered(..., beta = 0)` will produce an uninformative error (`"non-conformable arguments"`). Use `beta = NULL` (default, optimal) or `beta = 1` (DiD-style) instead.
- **β = 1**: Canonical DiD adjustment. This is what Callaway-Sant'Anna and Sun-Abraham do. Robust under parallel trends but sub-optimal under random timing.
- **β = β\***: Variance-minimizing coefficient computed via:

\[\beta^* = \text{Var}(\hat{X})^{-1} \text{Cov}(\hat{X}, \hat{\theta}_0)\]

The plug-in estimate $\hat{\beta}^* = \hat{V}_{\hat{X}}^{-1} \hat{V}_{\hat{X},\hat{\theta}_0}$ achieves the semiparametric efficiency bound:

\[\text{Var}(\hat{\theta}_{\beta^*}) = V_{\hat{\theta}_0} - V_{\hat{\theta}_0,\hat{X}} V_{\hat{X}}^{-1} V_{\hat{X},\hat{\theta}_0}\]

**Two-period intuition** ($T=2$, $\mathcal{G} = \{2, \infty\}$):
- $\beta = 0$: simple mean difference between treated and control
- $\beta = 1$: standard difference-in-differences
- $\beta^*$: optimal weighted combination, equivalent to Lin (2013)'s efficient estimator for experiments with baseline covariates

[verified: R/compute_efficient_estimator_and_se.R#L125, src/code.cpp#L27]

### Identification Assumptions

| # | Assumption | Type | Formal Statement | Intuition | Testable? | Diagnostic | Violation Consequence |
|---|---|---|---|---|---|---|---|
| A1 | Random Treatment Timing | Identification | $P(D=d) = \frac{\prod_{g \in \mathcal{G}} N_g!}{N!}$ | Treatment cohort assignment is as-good-as-random | Yes | `balance_checks()` + Fisher test (see [diagnostics.md](./diagnostics.md) §1–2) | If timing non-random and $\beta^* \neq 1$, efficient estimator is biased; use `staggered_cs()` instead |
| A2 | No Anticipation | Identification | $Y_{it}(g) = Y_{it}(\infty)$ for all $t < g$ | Units do not change behavior before treatment | Indirect | Event-study pre-treatment lags (see [diagnostics.md](./diagnostics.md) §Per-Estimator) | Anticipation contaminates pre-periods, biasing ATT estimates |
| A3 | Balanced Panel | Implementation | All $N$ units observed in all $T$ periods | No missing unit-period combinations | Yes (auto-checked) | Panel dimension checks (see [diagnostics.md](./diagnostics.md) §3) | Unbalanced panels are trimmed; severe imbalance reduces effective sample size |
| A4 | No Singleton Cohorts | Implementation | $N_g \geq 2$ for all included cohorts | Each cohort needs ≥2 units for variance estimation | Yes (auto-filtered) | Cohort size table (see [diagnostics.md](./diagnostics.md) §3) | Singleton cohorts dropped; many singletons destabilize variance estimates |

Each assumption's full diagnostic procedure and recovery path is documented in [diagnostics.md](./diagnostics.md) (see Assumption–Diagnostic Alignment table).

---

## Implementation Workflow

### Phase 1: Data Preparation

**Required format:** Balanced panel with one row per unit-period.

| Column | Parameter | Type | Description |
|--------|-----------|------|-------------|
| Unit ID | `i` (default `"i"`) | any | Cross-sectional unit identifier |
| Time | `t` (default `"t"`) | numeric | Time period indicator |
| Treatment timing | `g` (default `"g"`) | numeric | First period of treatment; `Inf` = never-treated |
| Outcome | `y` (default `"y"`) | numeric | Outcome variable |

```r
library(staggered)

# Built-in dataset: police officers randomly assigned to procedural justice training
df <- staggered::pj_officer_level_balanced

# Check data structure
str(df[, c("uid", "period", "first_trained", "complaints")])
# uid = unit ID, period = time, first_trained = treatment timing, complaints = outcome

# Verify balanced panel
stopifnot(length(unique(table(df$uid))) == 1)  # each unit has same number of periods

# Check for never-treated units
table(is.infinite(df$first_trained))  # TRUE = never-treated

# Check cohort sizes (look for singletons)
cohort_sizes <- table(df$first_trained[!duplicated(df$uid)])
print(cohort_sizes[cohort_sizes < 3])  # flag small cohorts
```

### Phase 2: Estimand Selection

Choose your aggregation target based on your research question. The `estimand` parameter is **effectively required** — despite the `NULL` default in the function signature, passing `NULL` without a custom `A_theta_list` will produce an error.

| Research Question | Estimand | Code |
|---|---|---|
| "What is the overall average effect?" | Simple | `estimand = "simple"` |
| "Do early vs late adopters differ?" | Cohort | `estimand = "cohort"` |
| "How does the effect vary by calendar time?" | Calendar | `estimand = "calendar"` |
| "How do effects evolve over time since treatment?" | Event-study | `estimand = "eventstudy"` |

```r
# Simple average treatment effect (most commonly reported)
result_simple <- staggered(df = df,
                           i = "uid", t = "period",
                           g = "first_trained", y = "complaints",
                           estimand = "simple")

# Cohort-weighted average
result_cohort <- staggered(df = df,
                           i = "uid", t = "period",
                           g = "first_trained", y = "complaints",
                           estimand = "cohort")

# Calendar-weighted average
result_calendar <- staggered(df = df,
                             i = "uid", t = "period",
                             g = "first_trained", y = "complaints",
                             estimand = "calendar")
```

### Phase 3: Estimation

```r
# PRIMARY: Efficient estimator (recommended default)
result_eff <- staggered(df = df,
                        i = "uid", t = "period",
                        g = "first_trained", y = "complaints",
                        estimand = "simple")
# [verified: beta = NULL triggers optimal β* computation]

# ROBUSTNESS: CS estimator for comparison
result_cs <- staggered_cs(df = df,
                          i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")

# Quantify efficiency gain
cat("SE ratio (CS/Efficient):", result_cs$se / result_eff$se, "\n")
# Values > 1.4 indicate substantial efficiency gains from the efficient estimator

# EVENT-STUDY: Dynamic effects (months 0-23 post-treatment)
es_eff <- staggered(df = df,
                    i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "eventstudy",
                    eventTime = 0:23)

# Visualization
library(ggplot2)
es_eff$ymin <- es_eff$estimate - 1.96 * es_eff$se
es_eff$ymax <- es_eff$estimate + 1.96 * es_eff$se

ggplot(es_eff, aes(x = eventTime, y = estimate)) +
  geom_pointrange(aes(ymin = ymin, ymax = ymax)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(x = "Months Since Training", y = "Effect on Complaints",
       title = "Event-Study: Procedural Justice Training Effects") +
  theme_minimal()
```

### Phase 4: Diagnostics and Reporting

```r
# 1. Balance check — test the random timing assumption
bal <- balance_checks(df = df,
                      i = "uid", t = "period",
                      g = "first_trained", y = "complaints",
                      estimand = "all")
print(bal)
# Look at: Wald test p-value (joint test), individual t-tests
# If p < 0.05 → random timing assumption is questionable

# 2. Fisher Randomization Test — robust finite-sample inference
result_fisher <- staggered(df = df,
                           i = "uid", t = "period",
                           g = "first_trained", y = "complaints",
                           estimand = "simple",
                           compute_fisher = TRUE,
                           num_fisher_permutations = 500)
# [verified: num_fisher_permutations default = 500]
cat("Fisher p-value:", result_fisher$fisher_pval, "\n")

# 3. Compare all three estimators for reporting
results_all <- data.frame(
  Estimator = c("Efficient", "CS", "SA"),
  Estimate = c(result_eff$estimate, result_cs$estimate,
               staggered_sa(df = df, i = "uid", t = "period",
                            g = "first_trained", y = "complaints",
                            estimand = "simple")$estimate),
  SE = c(result_eff$se, result_cs$se,
         staggered_sa(df = df, i = "uid", t = "period",
                      g = "first_trained", y = "complaints",
                      estimand = "simple")$se)
)
results_all$SE_ratio <- results_all$SE / results_all$SE[1]
print(results_all)
```

---

## Common Pitfalls

### Pitfall 1: Unbalanced Panel (Missing i-t Combinations)

**Symptom**: Warning message "The inputted data is not a balanced panel..." and unexpected changes in sample size.

**Cause**: Some units are missing observations for certain periods. The package auto-balances by dropping incomplete units.

**Solution**: Pre-balance your panel or check which units are dropped.

**Code**:
```r
# ❌ Wrong: pass unbalanced data without checking
result <- staggered(df = unbalanced_df,
                    i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple")
# May silently drop many units

# ✅ Right: verify balance before estimation
n_units <- length(unique(df$uid))
n_periods <- length(unique(df$period))
stopifnot(nrow(df) == n_units * n_periods)  # check completeness

# Or: explicitly balance and inspect what's dropped
obs_per_unit <- table(df$uid)
incomplete_units <- names(obs_per_unit[obs_per_unit < n_periods])
cat("Units to be dropped:", length(incomplete_units), "of", n_units, "\n")
```

### Pitfall 2: Singleton Cohorts (Only 1 Unit in a Treatment Cohort)

**Symptom**: Warning "The treatment cohort g = X has a single cross-sectional unit. We drop this cohort."

**Cause**: A treatment cohort with N_g = 1 cannot contribute to within-cohort variance estimation (need ≥ 2 units).

**Solution**: Acknowledge this is expected behavior. If too many cohorts are singletons, consider coarsening treatment timing.

**Code**:
```r
# Check cohort sizes BEFORE estimation
cohort_sizes <- df[!duplicated(df[c("uid")]), ]
cohort_table <- table(cohort_sizes$first_trained)
singletons <- cohort_table[cohort_table == 1]
cat("Singleton cohorts:", length(singletons), "\n")
cat("Units lost:", sum(singletons), "\n")

# If many singletons: consider grouping nearby treatment dates
# df$first_trained_q <- as.numeric(cut(df$first_trained, breaks = "quarter"))
```

[verified: R/compute_efficient_estimator_and_se.R#L1019-L1031]

### Pitfall 3: Wrong Estimand Choice for Research Question

**Symptom**: Results are substantively different from expectations; reviewers question the aggregation scheme.

**Cause**: Each estimand weights group-time effects differently. Using `"simple"` when you want dynamic effects, or `"cohort"` when calendar-time matters, gives a misleading summary.

**Solution**: Match the estimand to your research question using the table in Phase 2.

**Code**:
```r
# ❌ Wrong: using "simple" when you want to see dynamic treatment effects
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple")
# Collapses all dynamics into one number

# ✅ Right: use "eventstudy" for dynamic effects
result_es <- staggered(df = df, i = "uid", t = "period",
                       g = "first_trained", y = "complaints",
                       estimand = "eventstudy", eventTime = 0:23)
# Shows how effect evolves over time since treatment
```

### Pitfall 4: Ignoring Efficiency Gains (Using CS/SA When staggered() Is Better)

**Symptom**: Very wide confidence intervals that fail to reject the null, when the efficient estimator would give a significant result.

**Cause**: CS fixes β=1 and SA additionally restricts the control group. Under random timing, both discard information that the efficient estimator exploits.

**Solution**: Always start with `staggered()`. Report CS alongside as robustness. Check the SE ratio.

**Code**:
```r
# ❌ Wrong: defaulting to CS without checking efficiency
result_cs <- staggered_cs(df = df, i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")
# SE = 0.00393 → CI includes zero

# ✅ Right: use efficient estimator as primary, CS as robustness
result_eff <- staggered(df = df, i = "uid", t = "period",
                        g = "first_trained", y = "complaints",
                        estimand = "simple")
# SE = 0.00212 → 1.86× more precise

cat("Efficiency gain: SE ratio =", result_cs$se / result_eff$se, "\n")
# If ratio > 1.4, the efficient estimator is clearly preferred
```

### Pitfall 5: Misinterpreting eventTime Parameter

**Symptom**: Event-study results don't cover the expected time horizon; or error about infeasible event-times.

**Cause**: `eventTime` specifies lags SINCE treatment (relative time, not calendar time). Requesting event-times that exceed available post-treatment periods for all cohorts produces NA or is silently skipped.

**Solution**: Set `eventTime` to the range of feasible post-treatment lags. Check max feasible lag = max(t) - min(g among treated).

**Code**:
```r
# ❌ Wrong: requesting too many event-time lags
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "eventstudy",
                    eventTime = 0:100)  # likely exceeds available data

# ✅ Right: compute feasible range first
t_max <- max(df$period)
g_min <- min(df$first_trained[is.finite(df$first_trained)])
max_feasible_lag <- t_max - g_min
cat("Maximum feasible event-time:", max_feasible_lag, "\n")

result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "eventstudy",
                    eventTime = 0:min(23, max_feasible_lag))
```

[verified: R/compute_efficient_estimator_and_se.R#L1082-L1094]

### Pitfall 6: Not Checking Balance Pre-Treatment

**Symptom**: Significant treatment effects that are actually driven by pre-existing differences between cohorts.

**Cause**: If treatment timing is NOT random (violating A1), the efficient estimator's variance optimization can amplify bias when β* ≠ 1.

**Solution**: Always run `balance_checks()` before interpreting results.

**Code**:
```r
# ❌ Wrong: report results without testing the design assumption
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple")
# No validation of identifying assumption

# ✅ Right: test randomization assumption first
bal <- balance_checks(df = df, i = "uid", t = "period",
                      g = "first_trained", y = "complaints")
cat("Wald test p-value:", bal$pvalue_Wald, "\n")
# If p < 0.05: random timing assumption is questionable
# Consider whether parallel-trends-based CS is more appropriate
```

[verified: R/balance_checks.R#L72-L86]

### Pitfall 7: Using compute_fisher Without Understanding Computational Cost

**Symptom**: Estimation takes very long (minutes to hours); R session appears frozen.

**Cause**: Fisher Randomization Test re-runs the entire estimation `num_fisher_permutations` times. With large panels and many permutations, this is computationally intensive.

**Solution**: Start with small `num_fisher_permutations` for exploration. Scale up for publication.

**Code**:
```r
# ❌ Wrong: jumping straight to publication-quality FRT on large data
result <- staggered(df = large_df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple",
                    compute_fisher = TRUE,
                    num_fisher_permutations = 5000)
# Could take hours on large datasets

# ✅ Right: iterative approach
# Step 1: Quick estimate without FRT
result <- staggered(df = large_df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple")

# Step 2: Quick FRT for exploration (500 perms, ~30-60 sec)
result_frt <- staggered(df = large_df, i = "uid", t = "period",
                        g = "first_trained", y = "complaints",
                        estimand = "simple",
                        compute_fisher = TRUE,
                        num_fisher_permutations = 500)
# [verified: default = 500]

# Step 3: Publication FRT only if needed (overnight job)
# result_pub <- staggered(..., compute_fisher = TRUE, num_fisher_permutations = 5000)
```

### Pitfall 8: Confusing se vs se_neyman in Results

**Symptom**: Uncertainty about which standard error to report; conflicting inference from the two.

**Cause**: The package returns TWO standard errors:
- `se`: Refined SE (Lemma 5) — less conservative, generally preferred
- `se_neyman`: Conservative Neyman SE (Lemma 2) — always valid but potentially too wide

**Solution**: Report `se` (refined) as the primary SE. Report `se_neyman` for robustness. If they differ substantially, treatment effect heterogeneity within cohorts may be present.

**Code**:
```r
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple")

# Both SEs
cat("Refined SE:", result$se, "\n")
cat("Neyman SE: ", result$se_neyman, "\n")
cat("Ratio:     ", result$se_neyman / result$se, "\n")

# For inference, use refined SE (tighter, but valid)
ci_lower <- result$estimate - 1.96 * result$se
ci_upper <- result$estimate + 1.96 * result$se
cat(sprintf("95%% CI: [%.6f, %.6f]\n", ci_lower, ci_upper))

# If ratio ≈ 1: homogeneous effects within cohorts (Neyman ≈ exact)
# If ratio >> 1: heterogeneous effects; refined SE provides sharper inference
```

### Pitfall 9: `return_full_vcv = TRUE` Changes Return Type

**Symptom**: Code expecting a `data.frame` breaks after enabling `return_full_vcv`.

**Cause**: With the default `return_full_vcv = FALSE`, functions return a `data.frame` (columns: estimate, se, se_neyman). With `return_full_vcv = TRUE`, the return becomes a **list** with elements: `resultsDF` (the data.frame), `vcv` (variance-covariance matrix), and `vcv_neyman` (Neyman VCV matrix).

**Solution**: Access results via list elements when using full VCV:

```r
# Default (data.frame)
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "eventstudy", eventTime = 0:23,
                    return_full_vcv = FALSE)
result$estimate  # works directly

# With VCV (list)
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "eventstudy", eventTime = 0:23,
                    return_full_vcv = TRUE)
result$resultsDF$estimate  # access via resultsDF
result$vcv                  # refined VCV matrix
result$vcv_neyman           # Neyman VCV matrix
```

### Pitfall 10: All-Singleton Cohorts Cause Crash

**Symptom**: Error `"argument is of length zero"` after a warning about dropping singleton cohorts.

**Cause**: The package automatically drops cohorts with only 1 unit (singletons). If ALL cohorts are singletons, no data remains after filtering, causing an uninformative crash.

**Solution**: Ensure your data has at least some cohorts with ≥2 units:

```r
# Check cohort sizes before estimation
cohort_sizes <- table(df[!duplicated(df$uid), ]$first_trained)
cat("Cohorts with ≥2 units:", sum(cohort_sizes >= 2), "\n")
cat("Singleton cohorts:", sum(cohort_sizes == 1), "\n")

# If ALL are singletons, consider coarsening treatment timing
# e.g., aggregate monthly cohorts to quarterly
```

### Pitfall 11: Extremely Small Samples Return SE = 0

**Symptom**: Function returns a valid point estimate but `se = 0` and `se_neyman = 0`.

**Cause**: With very few effective observations (e.g., only 2-3 units per cohort after filtering), the variance estimator degenerates to zero. The package issues a warning but does not halt execution.

**Solution**: Verify sample adequacy before interpreting results:

```r
result <- staggered(df = df, i = "uid", t = "period",
                    g = "first_trained", y = "complaints",
                    estimand = "simple")
if (any(result$se == 0)) {
  warning("SE = 0 detected. Sample too small for reliable variance estimation.")
  # Check effective sample size per cohort
}
```

**Minimum data requirements** (rule of thumb):
- ≥2 cohorts with ≥2 units each (absolute minimum)
- ≥5 units per cohort for stable variance estimates
- ≥3 pre-treatment and ≥3 post-treatment periods for event-study

---

## Anti-Patterns

### Anti-Pattern 1: Column Renaming Dance (Unnecessary)

```r
# ❌ WRONG: renaming columns to match defaults
names(df)[names(df) == "unit_id"] <- "i"
names(df)[names(df) == "year"] <- "t"
names(df)[names(df) == "treatment_year"] <- "g"
names(df)[names(df) == "outcome"] <- "y"
result <- staggered(df = df, estimand = "simple")

# ✅ RIGHT: use the column name parameters directly
result <- staggered(df = df,
                    i = "unit_id",
                    t = "year",
                    g = "treatment_year",
                    y = "outcome",
                    estimand = "simple")
```
**Why**: The `i`, `t`, `g`, `y` parameters exist precisely to avoid renaming. Renaming mutates your data and risks downstream bugs.

### Anti-Pattern 2: Manual β = 1 Instead of Using Wrappers

```r
# ❌ WRONG: manually replicating CS by setting beta=1
result_cs_manual <- staggered(df = df, i = "uid", t = "period",
                              g = "first_trained", y = "complaints",
                              estimand = "simple",
                              beta = 1, use_last_treated_only = FALSE)

# ✅ RIGHT: use the dedicated wrapper (includes early-treated filter)
result_cs <- staggered_cs(df = df, i = "uid", t = "period",
                          g = "first_trained", y = "complaints",
                          estimand = "simple")
```
**Why**: The `staggered_cs()` wrapper also filters units with $g \leq \min(t)$ (units treated before the first observed period). Manually setting `beta = 1` in `staggered()` does NOT apply this filter, potentially including invalid observations and producing different results.

[verified: R/compute_efficient_estimator_and_se.R#L1438-L1441]

### Anti-Pattern 3: Running Event-Study One Lag at a Time

```r
# ❌ WRONG: loop over event-times (slow, loses joint VCV)
results_list <- list()
for (l in 0:23) {
  results_list[[l + 1]] <- staggered(df = df, i = "uid", t = "period",
                                     g = "first_trained", y = "complaints",
                                     estimand = "eventstudy", eventTime = l)
}
results_df <- do.call(rbind, results_list)

# ✅ RIGHT: pass vector of event-times (single call, gets joint VCV)
result_es <- staggered(df = df, i = "uid", t = "period",
                       g = "first_trained", y = "complaints",
                       estimand = "eventstudy",
                       eventTime = 0:23,
                       return_full_vcv = TRUE)
# result_es$vcv gives the joint variance-covariance matrix for all lags
```
**Why**: Passing a vector `eventTime = 0:23` is both faster (single data processing pass) and provides the joint VCV matrix needed for sup-t confidence bands or joint hypothesis tests. The loop approach discards cross-lag covariance information.

[verified: R/compute_efficient_estimator_and_se.R#L963, L966]

### Anti-Pattern 4: Ignoring Warnings About Dropped Observations

```r
# ❌ WRONG: suppress warnings and proceed
result <- suppressWarnings(
  staggered(df = problematic_df, i = "uid", t = "period",
            g = "first_trained", y = "complaints",
            estimand = "simple")
)

# ✅ RIGHT: catch and inspect warnings
result <- withCallingHandlers(
  staggered(df = problematic_df, i = "uid", t = "period",
            g = "first_trained", y = "complaints",
            estimand = "simple"),
  warning = function(w) {
    message("WARNING: ", conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
# Then investigate: how many units/cohorts were dropped? Is the effective sample adequate?
```
**Why**: The package warns about unbalanced panels (units dropped) and singleton cohorts (cohorts removed). These warnings indicate your effective sample may be substantially smaller than your input data. Suppressing them hides critical information about data quality.

---

## Advanced Topics

### Variance Estimation: Design-Based vs Neyman

The package provides two standard errors reflecting different assumptions about treatment effect heterogeneity:

**`se` (Refined SE, Lemma 5):** Accounts for the structure of potential outcomes under the null of constant treatment effects within cohorts. Less conservative; generally preferred for inference.

**`se_neyman` (Conservative Neyman SE, Lemma 2):** Valid regardless of within-cohort treatment effect heterogeneity. Always ≥ `se`. Analogous to the Neyman conservative variance in classical experimental design.

**When to report which:**
- **Primary inference:** Use `se` (refined). This is the analog of the "standard" SE in most applications.
- **Robustness:** Report `se_neyman` alongside. If both give the same conclusion, inference is robust.
- **Conservative audiences:** Report `se_neyman` for guaranteed validity regardless of heterogeneity.

**The gap between them:**
- `se ≈ se_neyman`: Within-cohort effects are approximately constant (homogeneous)
- `se << se_neyman`: Substantial within-cohort heterogeneity; the refined SE provides sharper inference by exploiting constancy under the null

### Fisher Randomization Test

**What it tests:**
- **Sharp null:** $Y_i(g) = Y_i(g')$ for all $i, g, g'$ (no unit-level effect for anyone) → Finite-sample exact
- **Weak null:** $\theta = 0$ (average effect is zero) → Asymptotically valid

**How it works:**
1. Compute the studentized test statistic: $\mathcal{T} = \hat{\theta}_{\hat{\beta}^*} / \widehat{se}$
2. Generate $K$ random permutations of treatment assignments (preserving cohort sizes $N_g$)
3. For each permutation $\pi$, recompute $\mathcal{T}_\pi$ (full re-estimation)
4. P-value = fraction of permutations where $|\mathcal{T}_\pi| \geq |\mathcal{T}|$

```r
# Fisher Randomization Test
result_frt <- staggered(df = df,
                        i = "uid", t = "period",
                        g = "first_trained", y = "complaints",
                        estimand = "simple",
                        compute_fisher = TRUE,
                        num_fisher_permutations = 500)
#>       estimate          se   se_neyman fisher_pval fisher_pval_se_neyman
#> 1 -0.001126981 0.002115194 0.002119248       0.642                 0.644
#>   num_fisher_permutations
#> 1                     500
```

**Computational considerations:**
- 500 permutations: ~30–60 seconds (exploration)
- 5000 permutations: ~5–10 minutes (publication quality)
- Cost scales linearly with `num_fisher_permutations` × single-estimation time

[verified: R/compute_efficient_estimator_and_se.R#L1277-L1306]

### Efficiency Frontier: When Gains Are Largest

The efficiency gain from using $\hat{\beta}^*$ vs $\beta = 1$ depends on outcome autocorrelation:

- **Low autocorrelation** (ρ ≈ 0): Pre-treatment outcomes are weakly predictive of post-treatment outcomes → $\beta^* \approx 0$, and DiD (β=1) over-adjusts. Efficient estimator provides **large gains** (potentially 2–3× SE reduction).
- **Moderate autocorrelation** (ρ ≈ 0.5): Optimal β is between 0 and 1. DiD still over-adjusts. **Substantial gains** (1.5–2× SE reduction).
- **High autocorrelation** (ρ ≈ 1, unit root): $\beta^* \approx 1$, DiD is near-optimal. **Minimal gains** (≈1.1×).

**Practical guidance:**
- If outcome follows a random walk (e.g., stock prices, unit root processes): efficiency gains are small — CS is nearly as good.
- If outcome has moderate persistence (e.g., survey measures, behavioral counts): gains are substantial — efficient estimator strongly preferred.
- Always check empirically: run both `staggered()` and `staggered_cs()` and report the SE ratio.

### Custom Estimands via A_theta_list

**Base period normalization:** When `eventTime` includes negative values (pre-treatment lags), those periods serve as reference points. Specifically, `eventTime = -1` returns `estimate = 0, SE = 0` by construction (it is the normalized base period). This is standard event-study normalization — the effect at the reference period is mechanically zero.

For non-standard aggregation schemes, you can provide custom weight matrices:

```r
# Advanced: custom estimand targeting only specific cohorts
# Each element of A_theta_list is a 1×T matrix of weights for cohort g
# Sum of all weights × cohort sizes determines the target parameter

# Example: effect for cohort g=5 only, averaged over post-treatment periods
# (Consult estimators/staggered.md for full details on custom A_theta construction)
```

---

## References

- Roth, J. & Sant'Anna, P.H.C. (2023). "Efficient Estimation for Staggered Rollout Designs." *Journal of Political Economy: Microeconomics*, 1(4): 669-709.
- Callaway, B. & Sant'Anna, P.H.C. (2021). "Difference-in-Differences with Multiple Time Periods." *Journal of Econometrics*, 225(2): 200-230.
- Sun, L. & Abraham, S. (2021). "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects." *Journal of Econometrics*, 225(2): 175-199.
- Lin, W. (2013). "Agnostic Notes on Regression Adjustments to Experimental Data: Reexamining Freedman's Critique." *Annals of Applied Statistics*, 7(1): 295-318.
