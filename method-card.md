---
method_name: staggered
display_name: "Efficient Estimation for Staggered Rollout Designs"
authors: "Jonathan Roth, Pedro H.C. Sant'Anna"
year: 2023
journal: "Journal of Political Economy: Microeconomics"
volume: "1(4)"
pages: "669-709"
doi: "10.1086/726581"
arxiv: "2102.01291"
package_name: staggered
package_version: 1.2.3
language: R
cran: true
github: "https://github.com/jonathandroth/staggered"
---

# Method Card: staggered

## Summary

The `staggered` R package implements the semiparametrically efficient estimator for staggered rollout designs proposed by Roth & Sant'Anna (2023). In settings where units adopt a binary, absorbing treatment at different times, this method provides the variance-minimizing estimator within a large class of linear estimators, under the assumption that treatment timing is as-good-as-randomly assigned.

The key contribution is optimizing the pre-treatment adjustment parameter β rather than fixing it at 1 (as in standard DiD). This yields standard error reductions of 1.4–3× over existing heterogeneity-robust estimators (Callaway-Sant'Anna, Sun-Abraham), which are nested as special cases within the same framework. All inference is design-based (finite-population), with Fisher Randomization Tests available.

## Key Innovation

Standard DiD estimators fix β = 1 when adjusting for pre-treatment outcome differences. Roth & Sant'Anna show that under randomized treatment timing, the optimal β* can be computed from the data via:

β* = Var(X̂)⁻¹ Cov(X̂, θ̂₀)

This plug-in estimator achieves the semiparametric efficiency bound for the class of estimators θ̂_β = θ̂₀ − X̂'β. The efficiency gain is largest when outcome autocorrelation is low (ρ ≈ 0), where DiD over-adjusts, and smallest when outcomes follow a unit root (ρ ≈ 1), where β* ≈ 1 and DiD is near-optimal.

## Estimand

The primary estimand is a weighted sum of cohort-time treatment effects:

$$\theta = \sum_{t,g,g'} a_{t,gg'} \tau_{t,gg'}$$

where $\tau_{t,gg'} = N^{-1} \sum_i [Y_{it}(g) - Y_{it}(g')]$ captures the effect of switching treatment timing from $g'$ to $g$ at period $t$. Four aggregation schemes (simple, cohort, calendar, event-study) define specific weight structures $a_{t,gg'}$.

## Identification Assumptions

| # | Assumption | Type | Formal Statement | Intuition | Testable? | Diagnostic | Violation Consequence |
|---|---|---|---|---|---|---|---|
| A1 | Random Treatment Timing | Identification | $P(D=d) = \prod N_g! / N!$ | Timing as-good-as-random | Yes | `balance_checks()`, Fisher test | Bias if $\beta^* \neq 1$; prefer CS estimator |
| A2 | No Anticipation | Identification | $Y_{it}(g) = Y_{it}(\infty)$ for $t < g$ | No pre-treatment behavior change | Indirect | Event-study pre-trends | Contaminates ATT estimates |
| A3 | Balanced Panel | Implementation | All units in all periods | No gaps in panel | Yes (auto) | Panel checks | Units dropped, smaller N |
| A4 | No Singleton Cohorts | Implementation | $N_g \geq 2$ | ≥2 units per cohort | Yes (auto) | Cohort size table | Cohorts dropped, unstable SE |

See [diagnostics.md](./diagnostics.md) for full diagnostic procedures.

## Theoretical Guarantees

- Under A1–A3, the plug-in estimator $\hat{\theta}_{\hat{\beta}^*}$ achieves the semiparametric efficiency bound.
- Two standard errors provided: refined (se) and conservative Neyman (se_neyman).
- Fisher Randomization Test provides finite-sample exact p-values under the sharp null.

## Estimators

| Estimator | Function | Key Feature | Paper Section |
|---|---|---|---|
| Efficient estimator | `staggered()` | β-optimal, achieves semiparametric efficiency bound | §3–4 |
| Callaway-Sant'Anna | `staggered_cs()` | β = 1, all not-yet-treated as controls | §5.1 |
| Sun-Abraham | `staggered_sa()` | β = 1, last-treated cohort as control | §5.2 |

**Nesting relationships:**
- `staggered_cs()` ≡ `staggered(..., beta=1, use_DiD_A0=TRUE, use_last_treated_only=FALSE)` + early-treated filter
- `staggered_sa()` ≡ `staggered(..., beta=1, use_DiD_A0=TRUE, use_last_treated_only=TRUE)` + early-treated filter

[verified: R/compute_efficient_estimator_and_se.R#L1444-L1454, L1548-L1558]

## Comparative Positioning

| Feature | staggered | did (CS2021) | sunab (SA2021) | fixest::sunab |
|---|---|---|---|---|
| Efficiency optimal | ✓ | ✗ | ✗ | ✗ |
| Assumes randomization | ✓ | ✗ (parallel trends) | ✗ (parallel trends) | ✗ (parallel trends) |
| Design-based inference | ✓ | ✗ (sampling-based) | ✗ (sampling-based) | ✗ (sampling-based) |
| Multiple aggregations | ✓ (4 schemes) | ✓ | Limited | Limited |
| Fisher randomization test | ✓ | ✗ | ✗ | ✗ |
| Event-study | ✓ | ✓ | ✓ | ✓ |
| Covariates | ✗ | ✓ | ✗ | ✗ |
| Unbalanced panels | ✗ (auto-balances) | ✓ | ✓ | ✓ |

## Aggregation Schemes

| Estimand | Code Value | When to Use |
|---|---|---|
| Simple | `"simple"` | Default summary; overall average weighted by cohort-size × post-periods |
| Cohort | `"cohort"` | When early vs late adopter effects may differ |
| Calendar | `"calendar"` | Time-varying policy questions |
| Event-study | `"eventstudy"` | Dynamic effect visualization; treatment effects by lag since onset |

[verified: R/compute_efficient_estimator_and_se.R#L1048-L1113]

## Prerequisites

- **Random or quasi-random treatment timing** — the core identifying assumption (strictly stronger than parallel trends)
- **Balanced panel** — all N units observed in all T periods (unbalanced panels are auto-trimmed with warning)
- **At least 2 units per treatment cohort** — singleton cohorts are auto-removed with warning
- **A "never-treated" or "last-treated" control group** — framework works with either; `g = Inf` denotes never-treated
- **Absorbing treatment** — once treated, always treated (no reversal)
- **No anticipation** — treatment has no effect on outcomes before implementation

## Data Requirements

**Format:** `data.frame` (or `data.table`) with one row per unit-period.

| Column | Parameter | Type | Description |
|--------|-----------|------|-------------|
| Unit ID | `i` (default `"i"`) | any | Cross-sectional unit identifier |
| Time period | `t` (default `"t"`) | numeric | Time period indicator |
| Treatment timing | `g` (default `"g"`) | numeric | First period of treatment; `Inf` = never-treated |
| Outcome | `y` (default `"y"`) | numeric | Outcome variable |

**Special values:**
- `g = Inf`: Never-treated units (serve as permanent controls)
- In stepped-wedge designs without never-treated units, the last-treated cohort serves as the comparison group

[verified: R/compute_efficient_estimator_and_se.R#L955-L970]

## Output Structure

All estimators return a `data.frame` with:

| Column | Description |
|--------|-------------|
| `estimate` | Point estimate |
| `se` | Refined standard error (preferred for inference) |
| `se_neyman` | Conservative Neyman standard error (always valid) |
| `eventTime` | (if vector eventTime specified) |
| `fisher_pval` | (if `compute_fisher = TRUE`) |
| `fisher_pval_se_neyman` | (if `compute_fisher = TRUE`) |

With `return_full_vcv = TRUE`: returns a list with `resultsDF`, `vcv`, and `vcv_neyman`.

## Scope and Limitations

**Appropriate when:**
- Treatment timing is plausibly randomized (lottery-based rollouts, randomized phase-ins)
- Quasi-experimental settings with strong case for exogenous timing variation
- Precision matters (e.g., detecting small effects, powering a study)
- Comparing efficiency of alternative DiD-style estimators

**Not appropriate when:**
- Treatment timing is clearly endogenous (selection into timing based on outcomes)
- Only parallel trends is credible (use CS/SA estimators or the `did` package instead)
- Panel is heavily unbalanced with no reasonable way to construct a balanced subset
- Treatment effects reverse (non-absorbing treatment)
- Covariates are needed for identification (package does not support covariate adjustment)

**Key risk:** If treatment timing is NOT random and β* ≠ 1, the efficient estimator introduces bias = (β* − 1) · E[X̂]. Always validate with `balance_checks()`.

## Citation

Roth, J. & Sant'Anna, P.H.C. (2023). "Efficient Estimation for Staggered Rollout Designs." *Journal of Political Economy: Microeconomics*, 1(4): 669-709. DOI: [10.1086/726581](https://doi.org/10.1086/726581). arXiv: [2102.01291](https://arxiv.org/abs/2102.01291).
