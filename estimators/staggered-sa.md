---
estimator: staggered_sa
package: staggered
version: 1.2.3
language: R
paper: "Sun & Abraham (2021)"
role: nested_special_case
---

# staggered_sa (Sun-Abraham Estimator)

## Overview

The `staggered_sa()` function is a convenience wrapper that computes the Sun & Abraham (2021) estimator within the efficient estimation framework of Roth & Sant'Anna (2023). It is mathematically equivalent to calling `staggered(beta=1, use_DiD_A0=TRUE, use_last_treated_only=TRUE)` with an additional early-treated filter. The SA estimator restricts the control group to ONLY the last-treated cohort, which can lead to severe efficiency loss when that cohort is small. It is primarily useful for replication and benchmarking against the SA literature, or in stepped-wedge designs where last-treated comparison is the natural choice.

> **WARNING:** In typical applications, `staggered_sa()` produces standard errors 3× or more larger than `staggered()`. Use with caution and consider whether the efficiency loss is justified.

## Estimand

The SA estimator targets the same family of estimands as the general efficient estimator:

$$\theta = \sum_{t,g,g'} a_{t,gg'} \tau_{t,gg'}$$

The four aggregation targets (simple, cohort, calendar, event-study) are identical to `staggered()`.

The distinctive feature is the choice of comparison group — ONLY the last-treated cohort $g_{\max}$ serves as control:

$$\hat{\tau}^{SA}_{tg} = (\bar{Y}_{tg} - \bar{Y}_{t,g_{\max}}) - (\bar{Y}_{g-1,g} - \bar{Y}_{g-1,g_{\max}})$$

When a never-treated group exists ($\infty \in \mathcal{G}$), $g_{\max} = \infty$ and SA coincides with CS using never-treated as controls (CS Variant 1).

## Identification Assumptions

| # | Assumption | Type | Formal Statement | Intuition | Testable? |
|---|---|---|---|---|---|
| A1 | Random Treatment Timing | Identification | $P(D=d) = \frac{\prod_{g \in \mathcal{G}} N_g!}{N!}$ | Treatment timing is as-good-as-randomly assigned | Partially (via `balance_checks(use_last_treated_only=TRUE)`) |
| A2 | No Anticipation | Identification | $Y_{it}(g) = Y_{it}(g')$ for all $g, g' > t$ | No pre-treatment behavioral change | No |
| A3 | At Least One Pre-Period | Structural | $g > \min(t)$ for all included units | DiD requires a pre-treatment reference period | Automatic (filter applied) |
| A4 | Last-Treated Cohort Exists | Structural | $\exists g_{\max} < \infty$ with $N_{g_{\max}} \geq 2$ | At least two units in the last-treated cohort for variance estimation | Implicitly (singleton removal) |
| A5 | Regularity | Technical | Cohort proportions stable, variances converge | Standard CLT conditions | Implicitly |

**Note on A1:** The original Sun & Abraham (2021) paper requires only parallel trends. Within this package's design-based framework, random timing is maintained. The SA point estimate remains valid under parallel trends alone, but design-based SEs assume random timing.

## When to Use This Estimator

**Use when:**
- You are **replicating or benchmarking** against Sun & Abraham (2021) results
- You have a **stepped-wedge design** where the last-treated cohort comparison is the natural methodological choice
- The **last-treated cohort is large** (> 5% of total N) — efficiency loss is tolerable
- You want to demonstrate robustness by showing results are qualitatively similar across CS, SA, and efficient estimators

**Do NOT use when:**
- The last-treated cohort is small (< 5% of N) — standard errors will explode (3×+ larger than efficient estimator)
- You want maximum precision → use `staggered()` instead
- A never-treated group exists and you want all not-yet-treated as controls → use `staggered_cs()` instead
- You are the primary analysis (SA should almost never be the lead result unless specifically motivated)

**Prefer over alternatives when:**
- The SA methodological framework is specifically required by your research question
- You are in a stepped-wedge trial where the last-treated cohort is genuinely the most appropriate comparison
- The last-treated cohort constitutes a substantial fraction of the sample

## Parameters

| Parameter | Type | Default | Description | When to Change | Source |
|---|---|---|---|---|---|
| `df` | data.frame | (required) | Balanced panel with columns for i, t, g, y | — | [verified: R/compute_efficient_estimator_and_se.R#L1516] |
| `i` | character | `"i"` | Column name for unit identifier | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1517] |
| `t` | character | `"t"` | Column name for time period | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1518] |
| `g` | character | `"g"` | Column name for treatment timing (`Inf` = never treated) | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1519] |
| `y` | character | `"y"` | Column name for outcome variable | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L1520] |
| `estimand` | character | NULL | Aggregation target: `"simple"`, `"cohort"`, `"calendar"`, or `"eventstudy"` | Always specify (required unless using `A_theta_list`) | [verified: R/compute_efficient_estimator_and_se.R#L1521] |
| `A_theta_list` | list | NULL | Custom estimand weight matrices | Advanced use only | [verified: R/compute_efficient_estimator_and_se.R#L1522] |
| `A_0_list` | list | NULL | Custom pre-treatment adjustment matrices | Advanced use only | [verified: R/compute_efficient_estimator_and_se.R#L1523] |
| `eventTime` | numeric | `0` | Event-time lag(s) for event-study; scalar or vector | Set to vector (e.g., `0:23`) for event-study plot | [verified: R/compute_efficient_estimator_and_se.R#L1524] |
| `return_full_vcv` | logical | FALSE | Return full variance-covariance matrix | Set TRUE for joint event-study tests | [verified: R/compute_efficient_estimator_and_se.R#L1525] |
| `compute_fisher` | logical | FALSE | Compute Fisher Randomization Test | Set TRUE for permutation-based inference | [verified: R/compute_efficient_estimator_and_se.R#L1526] |
| `num_fisher_permutations` | numeric | 500 | Number of FRT permutations | 500 for exploration; 5000 for publication | [verified: R/compute_efficient_estimator_and_se.R#L1527] |
| `skip_data_check` | logical | FALSE | Skip input validation | Never set TRUE as end-user | [verified: R/compute_efficient_estimator_and_se.R#L1528] |

**Parameters NOT exposed (hardcoded internally):**

| Hidden Parameter | Hardcoded Value | Meaning |
|---|---|---|
| `beta` | `1` | Fixed DiD adjustment (no optimization) |
| `use_DiD_A0` | `TRUE` | Scalar DiD-style pre-treatment difference |
| `use_last_treated_only` | `TRUE` | **ONLY last-treated cohort** serves as control group |

## Quick Example

```r
library(staggered)

# Load built-in dataset
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# Rename columns to match defaults
names(df)[match(c("period", "complaints", "first_trained", "uid"),
                names(df))] <- c("t", "y", "g", "i")

# SA estimator: simple weighted average
result_sa <- staggered_sa(df = df, estimand = "simple")
print(result_sa)

# Compare all three estimators
result_eff <- staggered(df = df, estimand = "simple")
result_cs  <- staggered_cs(df = df, estimand = "simple")

cat("SE comparison:\n")
cat("  Efficient:", result_eff$se, "\n")
cat("  CS:       ", result_cs$se, "(ratio:", result_cs$se / result_eff$se, ")\n")
cat("  SA:       ", result_sa$se, "(ratio:", result_sa$se / result_eff$se, ")\n")
```

## Return Value

Identical structure to `staggered()`:

| Column | Description |
|---|---|
| `estimate` | Point estimate (SA estimator, $\beta = 1$, last-treated control) |
| `se` | Refined standard error |
| `se_neyman` | Conservative (Neyman) standard error |
| `eventTime` | Event-time index (if vector `eventTime` provided) |
| `fisher_pval` | Fisher p-value (if `compute_fisher = TRUE`) |
| `fisher_pval_se_neyman` | Fisher p-value with Neyman SE (if `compute_fisher = TRUE`) |
| `num_fisher_permutations` | FRT permutation count (if `compute_fisher = TRUE`) |

## Relationship to Other Estimators

`staggered_sa()` is a **thin wrapper** (28 lines) that delegates to `staggered()` with fixed parameters:

```r
# These two calls produce identical results:
staggered_sa(df, estimand = "simple")

staggered(df, estimand = "simple", beta = 1,
          use_DiD_A0 = TRUE, use_last_treated_only = TRUE)
# ...EXCEPT staggered_sa() additionally drops units with g <= min(t)
```

**Control group selection logic (internal):**
```r
control_cohort_indices <- which((g_list > t) & (g_list == max(g_list)))
```
[verified: R/compute_efficient_estimator_and_se.R#L511-L513]

**Relationship to `staggered()`:** SA is a special case with $\beta = 1$ and last-treated-only control group. It is the most constrained variant — both fixing the adjustment coefficient AND restricting the comparison pool.

**Relationship to `staggered_cs()`:** Both fix $\beta = 1$, but SA restricts controls to the last-treated (or never-treated) cohort only, whereas CS uses all not-yet-treated cohorts. When the never-treated cohort dominates (i.e., is much larger than other late cohorts), SA and CS may yield similar point estimates, but they are NOT generically identical. SA is always weakly less efficient than CS.

**Key distinction:** The SA vs CS equivalence only holds in the limiting case where the never-treated group is the sole control cohort for both estimators. In stepped-wedge designs where all units are eventually treated, SA and CS produce different estimates because SA restricts to the last-treated cohort while CS uses all not-yet-treated.

## Efficiency Properties

The SA estimator suffers the **most severe efficiency loss** among the three estimators because it restricts comparisons to a single (often small) control cohort:

$$\text{Var}(\hat{\theta}^{SA}) \geq \text{Var}(\hat{\theta}^{CS}) \geq \text{Var}(\hat{\theta}_{\beta^*})$$

**Efficiency loss in simulations (Roth & Sant'Anna 2023):**
- Standard deviations **3×+ larger** than the efficient estimator when last cohort is small
- Equivalent sample size loss: **9×+** (you would need 9× more data to match efficient estimator precision)
- In Wood et al. application: < 1% of units in last cohort → extreme variance inflation

**Why the loss is so severe:**
- All treatment effects are estimated against a single cohort (mean $\bar{Y}_{g_{\max}}$)
- Variance of $\bar{Y}_{g_{\max}}$ scales as $S_{g_{\max}} / N_{g_{\max}}$ — tiny $N_{g_{\max}}$ → huge variance contribution
- The efficient estimator weights all not-yet-treated cohorts optimally, spreading the variance burden

**When loss is tolerable:**
- Large last-treated cohort (> 20% of N): variance inflation is moderate
- Stepped-wedge with balanced cohort sizes: all cohorts similar, last cohort adequate
- Never-treated group exists and is large: SA = CS in this case

**When loss is catastrophic:**
- Highly skewed cohort sizes with tiny last-treated group
- Many small late-adopter cohorts (typical in voluntary program adoption)

## Common Pitfalls

1. **Using SA as primary estimator without justification:** SA should rarely be the lead result. It is appropriate mainly for replication, robustness checks, or stepped-wedge designs. Default to `staggered()` for primary analysis.

2. **Ignoring the SE ratio:** Always compare `result_sa$se / result_eff$se`. If this ratio exceeds 2, the efficiency loss is substantial and you should strongly prefer the efficient estimator (if random timing is credible).

3. **Not checking last-cohort size:** Before using `staggered_sa()`, check `table(df$g)` to see how many units are in the last-treated cohort. If it's < 5% of N, expect very imprecise estimates.

4. **Expecting SA ≠ CS when never-treated exists:** If your data contains `g = Inf` (never-treated units), SA and CS produce identical results because the "last-treated" cohort IS the never-treated group. The SA vs CS distinction only matters in stepped-wedge designs.

5. **Assuming SA standard errors match the original `sunab()` function:** The `staggered` package uses design-based (Neyman) inference, not the cluster-robust SEs from Sun & Abraham's original implementation. Point estimates match, SEs differ.

## References

- Sun, L. & Abraham, S. (2021). "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects." *Journal of Econometrics* 225(2):175-199.
- Roth, J. & Sant'Anna, P.H.C. (2023). "Efficient Estimation for Staggered Rollout Designs." *Journal of Political Economy: Microeconomics* 1(4):669-709.
- Callaway, B. & Sant'Anna, P.H.C. (2021). "Difference-in-Differences with Multiple Time Periods." *Journal of Econometrics* 225(2):200-230.
