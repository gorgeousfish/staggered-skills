---
estimator: staggered_cs
package: staggered
version: 1.2.3
language: R
paper: "Callaway & Sant'Anna (2021)"
role: nested_special_case
---

# staggered_cs (Callaway-Sant'Anna Estimator)

## Overview

The `staggered_cs()` function is a convenience wrapper that computes the Callaway & Sant'Anna (2021) estimator within the efficient estimation framework of Roth & Sant'Anna (2023). It is mathematically equivalent to calling `staggered(beta=1, use_DiD_A0=TRUE, use_last_treated_only=FALSE)` with an additional filter removing early-treated units. The CS estimator uses all not-yet-treated units as controls and applies the standard DiD adjustment ($\beta = 1$), making it a familiar and interpretable baseline — but one that sacrifices efficiency relative to the optimal $\beta^*$ estimator.

## Estimand

The CS estimator targets the same family of estimands as the general efficient estimator:

$$\theta = \sum_{t,g,g'} a_{t,gg'} \tau_{t,gg'}$$

The four aggregation targets (simple, cohort, calendar, event-study) are identical to `staggered()`.

The distinctive estimation strategy computes group-time effects via DiD using not-yet-treated units as controls with period $g-1$ as reference:

$$\hat{\tau}^{CS}_{tg} = (\bar{Y}_{tg} - \bar{Y}_{t,\text{nyt}}) - (\bar{Y}_{g-1,g} - \bar{Y}_{g-1,\text{nyt}})$$

where "nyt" denotes a size-weighted average of not-yet-treated cohorts at time $t$.

**In the β-framework:** This corresponds to fixing $\beta = 1$ (full DiD adjustment) rather than optimizing $\beta$ for minimum variance.

## Identification Assumptions

| # | Assumption | Type | Formal Statement | Intuition | Testable? |
|---|---|---|---|---|---|
| A1 | Random Treatment Timing | Identification | $P(D=d) = \frac{\prod_{g \in \mathcal{G}} N_g!}{N!}$ | Treatment timing is as-good-as-randomly assigned | Partially (via `balance_checks()`) |
| A2 | No Anticipation | Identification | $Y_{it}(g) = Y_{it}(g')$ for all $g, g' > t$ | No pre-treatment behavioral change | No |
| A3 | At Least One Pre-Period | Structural | $g > \min(t)$ for all included units | DiD requires at least one pre-treatment period per cohort | Automatic (filter applied) |
| A4 | Regularity | Technical | Cohort proportions stable, variances converge | Standard CLT conditions | Implicitly |

**Note on A1:** The original Callaway & Sant'Anna (2021) paper requires only parallel trends (weaker than random timing). However, within this package's design-based framework, random timing is the maintained assumption for all three estimators. The CS point estimate remains valid under parallel trends alone, but the design-based standard errors assume random timing.

## When to Use This Estimator

**Use when:**
- You want a **robustness check** alongside the efficient estimator (compare SEs to quantify efficiency gain)
- Only **parallel trends** (not random timing) is credible for your setting — the CS estimator is the natural choice
- You are **replicating or benchmarking** against Callaway & Sant'Anna (2021) results
- Outcome autocorrelation is near 1 ($\rho \approx 1$, unit root process) — in this case $\beta^* \approx 1$ and efficiency loss is minimal
- You want a **familiar, interpretable** estimator for audiences trained on standard DiD

**Do NOT use when:**
- Random timing is credible and you want maximum precision → use `staggered()` instead
- You specifically need last-treated-only comparison group → use `staggered_sa()`
- All units are treated in or before the first observed period (no valid units remain after filter)

**Prefer over `staggered()` when:**
- The random timing assumption is questionable but parallel trends holds
- The audience is more familiar with CS-style estimates
- You want conservative inference that does not depend on correct $\beta^*$ specification

## Parameters

| Parameter | Type | Default | Description | When to Change | Source |
|---|---|---|---|---|---|
| `df` | data.frame | (required) | Balanced panel with columns for i, t, g, y | — | [verified: R/compute_efficient_estimator_and_se.R#L1412] |
| `i` | character | `"i"` | Column name for unit identifier | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1413] |
| `t` | character | `"t"` | Column name for time period | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1414] |
| `g` | character | `"g"` | Column name for treatment timing (`Inf` = never treated) | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1415] |
| `y` | character | `"y"` | Column name for outcome variable | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1416] |
| `estimand` | character | NULL | Aggregation target: `"simple"`, `"cohort"`, `"calendar"`, or `"eventstudy"` | Always specify (required unless using `A_theta_list`) | [verified: R/compute_efficient_estimator_and_se.R#L1417] |
| `A_theta_list` | list | NULL | Custom estimand weight matrices | Advanced use only | [verified: R/compute_efficient_estimator_and_se.R#L1418] |
| `A_0_list` | list | NULL | Custom pre-treatment adjustment matrices | Advanced use only | [verified: R/compute_efficient_estimator_and_se.R#L1419] |
| `eventTime` | numeric | `0` | Event-time lag(s) for event-study; scalar or vector | Set to vector (e.g., `0:23`) for event-study plot | [verified: R/compute_efficient_estimator_and_se.R#L1420] |
| `return_full_vcv` | logical | FALSE | Return full variance-covariance matrix | Set TRUE for joint event-study tests | [verified: R/compute_efficient_estimator_and_se.R#L1421] |
| `compute_fisher` | logical | FALSE | Compute Fisher Randomization Test | Set TRUE for permutation-based inference | [verified: R/compute_efficient_estimator_and_se.R#L1422] |
| `num_fisher_permutations` | numeric | 500 | Number of FRT permutations | 500 for exploration; 5000 for publication | [verified: R/compute_efficient_estimator_and_se.R#L1423] |
| `skip_data_check` | logical | FALSE | Skip input validation | Never set TRUE as end-user | [verified: R/compute_efficient_estimator_and_se.R#L1424] |

**Parameters NOT exposed (hardcoded internally):**

| Hidden Parameter | Hardcoded Value | Meaning |
|---|---|---|
| `beta` | `1` | Fixed DiD adjustment (no optimization) |
| `use_DiD_A0` | `TRUE` | Scalar CS-style pre-treatment difference |
| `use_last_treated_only` | `FALSE` | All not-yet-treated units serve as controls |

## Quick Example

```r
library(staggered)

# Load built-in dataset
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# Rename columns to match defaults
names(df)[match(c("period", "complaints", "first_trained", "uid"),
                names(df))] <- c("t", "y", "g", "i")

# CS estimator: simple weighted average
result_cs <- staggered_cs(df = df, estimand = "simple")
print(result_cs)

# Compare with efficient estimator to quantify efficiency gain
result_eff <- staggered(df = df, estimand = "simple")
cat("SE ratio (CS/Efficient):", result_cs$se / result_eff$se, "\n")

# Event-study with CS estimator
result_es <- staggered_cs(df = df, estimand = "eventstudy", eventTime = 0:23)
head(result_es)
```

## Return Value

Identical structure to `staggered()`:

| Column | Description |
|---|---|
| `estimate` | Point estimate (CS estimator, $\beta = 1$) |
| `se` | Refined standard error |
| `se_neyman` | Conservative (Neyman) standard error |
| `eventTime` | Event-time index (if vector `eventTime` provided) |
| `fisher_pval` | Fisher p-value (if `compute_fisher = TRUE`) |
| `fisher_pval_se_neyman` | Fisher p-value with Neyman SE (if `compute_fisher = TRUE`) |
| `num_fisher_permutations` | FRT permutation count (if `compute_fisher = TRUE`) |

## Relationship to Other Estimators

`staggered_cs()` is a **thin wrapper** (28 lines) that delegates to `staggered()` with fixed parameters:

```r
# These two calls produce identical results:
staggered_cs(df, estimand = "simple")

staggered(df, estimand = "simple", beta = 1,
          use_DiD_A0 = TRUE, use_last_treated_only = FALSE)
# ...EXCEPT staggered_cs() additionally drops units with g <= min(t)
```

**Relationship to `staggered()`:** CS is a special case obtained by fixing $\beta = 1$ instead of optimizing. The point estimates differ from `staggered()` whenever $\hat{\beta}^* \neq 1$ (which is typical).

**Relationship to `staggered_sa()`:** Both fix $\beta = 1$, but CS uses all not-yet-treated units as controls while SA restricts to the last-treated cohort only. CS is weakly more efficient than SA (uses more control information).

**Equivalence to original CS (2021):** Point estimates are numerically equivalent. Standard errors differ slightly because this package uses design-based (Neyman) inference rather than the sampling-based bootstrap of the original CS package.

## Efficiency Properties

The CS estimator is **sub-optimal** under random treatment timing because it fixes $\beta = 1$ rather than choosing the variance-minimizing $\beta^*$:

$$\text{Var}(\hat{\theta}_1) \geq \text{Var}(\hat{\theta}_{\beta^*})$$

**Efficiency loss in simulations (Roth & Sant'Anna 2023):**
- Standard deviations approximately 1.4–1.9× larger than the efficient estimator
- Equivalent sample size loss: 2–3.4× (you would need 2–3.4× more data to achieve the same precision with CS)
- Loss increases with lower outcome autocorrelation (farther from unit root)

**When loss is minimal:** If outcomes follow a unit root process ($\rho \approx 1$), then $\beta^* \approx 1$ and CS is near-optimal. In this case, pre-treatment differences carry little information about post-treatment outcomes.

**When loss is severe:** With moderate autocorrelation ($\rho \approx 0.5$), the efficiency gap widens substantially. The optimal $\beta^*$ can differ significantly from 1, and the pre-treatment adjustment provides large variance reduction.

## Common Pitfalls

1. **Assuming CS standard errors match the `did` package:** The `staggered` package uses design-based (Neyman) inference, not the bootstrap or cluster-robust SEs from Callaway & Sant'Anna's `did` package. Point estimates match, but SEs will differ.

2. **Ignoring the early-treated filter:** Units with $g \leq \min(t)$ are automatically dropped with a warning. If many units are removed, your effective sample may be substantially smaller than expected. Check the warning message.

3. **Using CS when random timing is credible:** If the randomization assumption holds, `staggered()` dominates — report CS only as a robustness check, not the primary result.

4. **Not reporting the SE ratio:** When presenting CS alongside the efficient estimator, always report `se_cs / se_efficient` to quantify what is gained from the stronger assumption. Ratios > 1.5 make a strong case for the efficient estimator.

5. **Confusing "parallel trends validity" with "efficiency optimality":** The CS estimate is valid under either parallel trends or random timing. But its efficiency is only optimal when $\beta^* = 1$ (unit root outcomes) — which is an empirical question, not an assumption.

## References

- Callaway, B. & Sant'Anna, P.H.C. (2021). "Difference-in-Differences with Multiple Time Periods." *Journal of Econometrics* 225(2):200-230.
- Roth, J. & Sant'Anna, P.H.C. (2023). "Efficient Estimation for Staggered Rollout Designs." *Journal of Political Economy: Microeconomics* 1(4):669-709.
