---
estimator: staggered
package: staggered
version: 1.2.3
language: R
paper: "Roth & Sant'Anna (2023)"
role: primary
---

# staggered (Efficient Estimator)

## Overview

The `staggered()` function implements the semiparametrically efficient estimator for staggered rollout designs proposed by Roth & Sant'Anna (2023). It optimally combines pre-treatment outcome information to minimize estimator variance within the class $\hat{\theta}_\beta = \hat{\theta}_0 - \hat{X}'\beta$, where $\hat{\theta}_0$ is the unadjusted plug-in estimator and $\hat{X}$ captures pre-treatment outcome differences between cohorts. By data-adaptively choosing $\beta = \beta^*$, it achieves standard error reductions of 1.4–3× relative to existing DiD-based methods (Callaway-Sant'Anna, Sun-Abraham) in realistic settings.

## Estimand

The estimand is a researcher-chosen weighted sum of average treatment effects of switching treatment dates:

$$\theta = \sum_{t,g,g'} a_{t,gg'} \tau_{t,gg'}$$

where $\tau_{t,gg'} = N^{-1}\sum_i [Y_{it}(g) - Y_{it}(g')]$ and weights satisfy $a_{t,gg'} = 0$ for $t < \min(g,g')$ (no anticipation).

Four standard aggregation targets are supported:

| Aggregation | Formula | Intuition |
|---|---|---|
| Simple | $\theta^{simple} = \frac{1}{\sum_t \sum_{g \leq t} N_g} \sum_t \sum_{g \leq t} N_g \cdot ATE(t,g)$ | Overall average effect weighted by cohort-size × post-periods |
| Cohort | $\theta^{cohort} = \frac{1}{\sum_g N_g} \sum_g N_g \cdot \bar{ATE}_g$ | Average effect across cohorts, each cohort weighted by size |
| Calendar | $\theta^{calendar} = \frac{1}{T} \sum_t \theta_t$ | Average effect per calendar period |
| Event-study | $\theta^{ES}_l = \frac{1}{\sum_{g:g+l \leq T} N_g} \sum_{g:g+l \leq T} N_g \cdot ATE(g+l, g)$ | Effect at relative time $l$ after treatment onset |

The efficient estimator does NOT change what is estimated — it only optimizes HOW it is estimated for maximum precision.

## Identification Assumptions

| # | Assumption | Type | Formal Statement | Intuition | Testable? |
|---|---|---|---|---|---|
| A1 | Random Treatment Timing | Identification | $P(D=d) = \frac{\prod_{g \in \mathcal{G}} N_g!}{N!}$ | Treatment timing is as-good-as-randomly assigned; any permutation of start dates (preserving cohort sizes) is equally likely | Partially (via `balance_checks()`) |
| A2 | No Anticipation | Identification | $Y_{it}(g) = Y_{it}(g')$ for all $g, g' > t$ | Units do not change behavior before treatment implementation | No (untestable) |
| A3 | Regularity | Technical | $N_g/N \to p_g \in (0,1)$; $S_g \to S_g^*$ (p.d.); Lindeberg condition holds | Cohort proportions stable; no single unit dominates | Implicitly (singleton cohorts auto-removed) |

**Key distinction from standard DiD:** Assumption A1 (random timing) is strictly stronger than parallel trends. Under parallel trends alone, the efficient estimator's point estimate is still consistent, but the efficiency gain formula may not hold.

## When to Use This Estimator

**Use when:**
- Treatment timing is plausibly random (randomized rollouts, lottery-based expansions, quasi-experiments with strong case for exogenous timing)
- Precision matters (e.g., ruling out small effects, limited sample size)
- You want the variance-minimizing estimator within the linear class

**Do NOT use when:**
- Only parallel trends (not random timing) is credible — point estimates remain valid, but you lose the efficiency optimality guarantee
- Treatment is not absorbing (reversals occur)
- Panel is severely unbalanced with no remedy

**Prefer over alternatives when:**
- You observe SE gains of 1.4× or more over CS (check via side-by-side comparison)
- Outcome autocorrelation is moderate (not near unit root) — this is where efficiency gains are largest
- The balance test (`balance_checks()`) supports the random timing assumption

## Parameters

| Parameter | Type | Default | Description | When to Change | Source |
|---|---|---|---|---|---|
| `df` | data.frame | (required) | Balanced panel with columns for i, t, g, y | — | [verified: R/compute_efficient_estimator_and_se.R#L955] |
| `i` | character | `"i"` | Column name for unit identifier | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L956] |
| `t` | character | `"t"` | Column name for time period | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L957] |
| `g` | character | `"g"` | Column name for treatment timing (first treated period; `Inf` = never treated) | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L958] |
| `y` | character | `"y"` | Column name for outcome variable | When your column has a different name | [verified: R/compute_efficient_estimator_and_se.R#L959] |
| `estimand` | character | NULL | Aggregation target: `"simple"`, `"cohort"`, `"calendar"`, or `"eventstudy"` | Always specify (required unless using custom `A_theta_list`) | [verified: R/compute_efficient_estimator_and_se.R#L960] |
| `A_theta_list` | list | NULL | Custom estimand weight matrices $A_{\theta,g}$ | Advanced: for non-standard aggregation schemes | [verified: R/compute_efficient_estimator_and_se.R#L961] |
| `A_0_list` | list | NULL | Custom pre-treatment adjustment matrices $A_{0,g}$ | Advanced: override default $\hat{X}$ construction | [verified: R/compute_efficient_estimator_and_se.R#L962] |
| `eventTime` | numeric | `0` | Event-time lag(s) $l$ for event-study estimand; scalar or vector | Set to vector (e.g., `0:23`) for full event-study plot | [verified: R/compute_efficient_estimator_and_se.R#L963] |
| `beta` | numeric | NULL (optimal) | Adjustment coefficient $\beta$; NULL triggers data-driven $\hat{\beta}^*$ | Set to `1` to replicate CS/DiD; set to `0` for difference-in-means | [verified: R/compute_efficient_estimator_and_se.R#L964] |
| `use_DiD_A0` | logical | TRUE (when `A_0_list` is NULL) | Use scalar DiD-style $\hat{X}$ (TRUE) vs full pre-treatment comparison vector (FALSE) | Keep TRUE — scalar prevents overfitting per Remark 5 of paper | [verified: R/compute_efficient_estimator_and_se.R#L965] |
| `return_full_vcv` | logical | FALSE | Return full variance-covariance matrix for event-study estimates | Set TRUE for joint hypothesis tests across event-times | [verified: R/compute_efficient_estimator_and_se.R#L966] |
| `use_last_treated_only` | logical | FALSE | Use only last-treated cohort as controls (TRUE) vs all not-yet-treated (FALSE) | Set TRUE to replicate Sun-Abraham comparison group | [verified: R/compute_efficient_estimator_and_se.R#L967] |
| `compute_fisher` | logical | FALSE | Compute Fisher Randomization Test p-value | Set TRUE for robust finite-sample inference (computationally intensive) | [verified: R/compute_efficient_estimator_and_se.R#L968] |
| `num_fisher_permutations` | numeric | 500 | Number of permutations for FRT | Use 500 for exploration; 5000 for publication-quality | [verified: R/compute_efficient_estimator_and_se.R#L969] |
| `skip_data_check` | logical | FALSE | Skip input validation (used internally for FRT recursion) | Never set TRUE as end-user | [verified: R/compute_efficient_estimator_and_se.R#L970] |

### The β Parameter in Detail

The β parameter is the core innovation of this estimator:

- **`beta = NULL` (default):** Computes the variance-minimizing $\hat{\beta}^* = \hat{V}_{\hat{X}}^{-1} \hat{V}_{\hat{X},\hat{\theta}_0}$ via LDLT decomposition. This achieves the semiparametric efficiency bound.
- **`beta = 0`:** Difference-in-means estimator (no pre-treatment adjustment). Valid but typically inefficient.
- **`beta = 1`:** Canonical DiD adjustment (equivalent to Callaway-Sant'Anna). Robust under parallel trends but sub-optimal under random timing.
- **General `beta`:** Any user-specified adjustment strength.

**Two-period intuition ($T=2$, $\mathcal{G} = \{2, \infty\}$):**
- $\beta = 0$: simple mean difference between treated and control post-treatment outcomes
- $\beta = 1$: standard difference-in-differences
- $\beta^*$: optimal weighted combination, equivalent to Lin (2013)'s efficient estimator for experiments with baseline covariates

## Quick Example

```r
library(staggered)
data(pj_officer_level_balanced)

result <- staggered(
  df = pj_officer_level_balanced,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple"
)
print(result)
```

## Return Value

**Standard return** (`return_full_vcv = FALSE`): A `data.frame` with columns:

| Column | Description |
|---|---|
| `estimate` | Point estimate $\hat{\theta}_{\hat{\beta}^*}$ |
| `se` | Refined standard error (Lemma 5, less conservative) |
| `se_neyman` | Neyman (conservative) standard error (Lemma 2) |
| `eventTime` | Event-time index (only when vector `eventTime` is provided) |
| `fisher_pval` | Fisher permutation p-value using refined SE (only if `compute_fisher = TRUE`) |
| `fisher_pval_se_neyman` | Fisher p-value using Neyman SE (only if `compute_fisher = TRUE`) |
| `num_fisher_permutations` | Number of FRT permutations used (only if `compute_fisher = TRUE`) |

**Full VCV return** (`return_full_vcv = TRUE`): A `list` with elements `resultsDF`, `vcv`, `vcv_neyman`.

## Relationship to Other Estimators

`staggered()` is the **general case** from which both `staggered_cs()` and `staggered_sa()` are derived as special cases:

| Estimator | Equivalent `staggered()` Call |
|---|---|
| `staggered_cs(df, estimand="simple")` | `staggered(df, estimand="simple", beta=1, use_DiD_A0=TRUE, use_last_treated_only=FALSE)` + early-treated filter |
| `staggered_sa(df, estimand="simple")` | `staggered(df, estimand="simple", beta=1, use_DiD_A0=TRUE, use_last_treated_only=TRUE)` + early-treated filter |
| Difference-in-means | `staggered(df, estimand="simple", beta=0)` |

The wrappers additionally remove units with $g \leq \min(t)$ (units treated before the first observed period), which `staggered()` does not do by default.

## Efficiency Properties

The efficient estimator achieves the semiparametric efficiency bound within the class of linear estimators under random treatment timing:

$$\text{Var}(\hat{\theta}_{\beta^*}) = V_{\hat{\theta}_0} - V_{\hat{\theta}_0,\hat{X}} V_{\hat{X}}^{-1} V_{\hat{X},\hat{\theta}_0}$$

**Efficiency gains in simulations (Roth & Sant'Anna 2023, Table 1):**
- vs Callaway-Sant'Anna: SE reduction factor of 1.39–1.85×
- vs Sun-Abraham: SE reduction factor of 3×+ (when last cohort is small)
- Equivalent sample size gain: 2–3.4× relative to CS; 9×+ relative to SA

**When gains are largest:**
- Moderate outcome autocorrelation (far from unit root)
- Many cohorts with heterogeneous sizes
- Last-treated cohort is small relative to total N

**When gains are minimal:**
- Outcome follows unit root process ($\rho \approx 1$): $\beta^* \approx 1$, so DiD is already near-optimal
- Only two periods and two groups (simple two-period DiD setting)

## Common Pitfalls

1. **Forgetting to specify `estimand`:** The function returns an error if both `estimand` and `A_theta_list` are NULL. Always specify one of `"simple"`, `"cohort"`, `"calendar"`, or `"eventstudy"`.

2. **Setting `use_DiD_A0 = FALSE` without justification:** The full pre-treatment comparison vector can overfit when dimension is large relative to $\sqrt{N}$. The default scalar DiD (`use_DiD_A0 = TRUE`) is recommended per Remark 5 of the paper.

3. **Interpreting efficiency gains as "free lunch":** The gains require random treatment timing (A1). If timing is confounded but DiD is correct, bias = $(\beta^* - 1) \cdot E[\hat{X}]$. When $\beta^*$ is far from 1, this bias can be substantial.

4. **Ignoring the balance check:** Always run `balance_checks()` to support the random timing assumption. Efficiency gains are meaningless if the identifying assumption fails.

5. **Using refined SE (`se`) vs Neyman SE (`se_neyman`):** The refined SE is less conservative and generally preferred for inference. The Neyman SE is valid but overly conservative when treatment effects are homogeneous within cohorts. Report both for transparency.

## References

- Roth, J. & Sant'Anna, P.H.C. (2023). "Efficient Estimation for Staggered Rollout Designs." *Journal of Political Economy: Microeconomics* 1(4):669-709.
- Callaway, B. & Sant'Anna, P.H.C. (2021). "Difference-in-Differences with Multiple Time Periods." *Journal of Econometrics* 225(2):200-230.
- Sun, L. & Abraham, S. (2021). "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects." *Journal of Econometrics* 225(2):175-199.
- Lin, W. (2013). "Agnostic Notes on Regression Adjustments to Experimental Data: Reexamining Freedman's Critique." *Annals of Applied Statistics* 7(1):295-318.
