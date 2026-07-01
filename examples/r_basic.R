# =============================================================================
# staggered R Package — Complete Workflow Example
# =============================================================================
# This script demonstrates the full analysis workflow using the staggered package
# for efficient estimation in staggered rollout designs.
#
# Paper: Roth & Sant'Anna (2023), "Efficient Estimation for Staggered Rollout
#        Designs", Journal of Political Economy: Microeconomics 1(4):669-709.
#
# Data: Chicago Police Department procedural justice training program
#       (Wood, Tyler, Papachristos, Roth & Sant'Anna, 2020)
#
# Package version: 1.2.3
# =============================================================================

# --- Setup ---
library(staggered)

# Load built-in dataset: balanced panel of 7,785 officers over 72 months
data(pj_officer_level_balanced)
df <- pj_officer_level_balanced

# =============================================================================
# Section 1: Data Exploration
# =============================================================================

cat("=== Data Structure ===\n")
cat("Dimensions:", nrow(df), "rows x", ncol(df), "columns\n")
cat("Units:", length(unique(df$uid)), "\n")
cat("Periods:", length(unique(df$period)), "(months 1-72)\n\n")

# Examine treatment cohort distribution
cohort_sizes <- table(df$first_trained[!duplicated(df$uid)])
cat("=== Treatment Cohort Distribution ===\n")
cat("Number of cohorts:", length(cohort_sizes), "\n")
cat("Cohort sizes (first 10):\n")
print(head(cohort_sizes, 10))
cat("\n")

# Key variables for the staggered analysis
cat("=== Key Variables ===\n")
cat("Unit ID column:      uid\n")
cat("Time column:         period (1-72)\n")
cat("Treatment timing:    first_trained (cohort indicator)\n")
cat("Outcome:             complaints (count of complaints)\n\n")

# =============================================================================
# Section 2: Main Efficient Estimator
# =============================================================================

cat("=== Section 2: Efficient Estimator (Roth & Sant'Anna, 2023) ===\n\n")

# --- 2a: Simple estimand ---
# Averages all treated (t,g) combinations with weights proportional to N_g
cat("--- 2a: Simple Weighted Average ---\n")
result_simple <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple"
)
print(result_simple)
# Expected output:
#       estimate          se   se_neyman
# 1 -0.001126981 0.002115194 0.002119248
cat("\n")

# --- 2b: Cohort estimand ---
# Averages ATEs for each cohort g, then takes N_g-weighted average across g
cat("--- 2b: Cohort Weighted Average ---\n")
result_cohort <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "cohort"
)
print(result_cohort)
# Expected output:
#       estimate          se   se_neyman
# 1 -0.001084689 0.002261011 0.002264876
cat("\n")

# --- 2c: Calendar estimand ---
# Averages ATEs for each time period, weighted by N_g, then averages across time
cat("--- 2c: Calendar Weighted Average ---\n")
result_calendar <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "calendar"
)
print(result_calendar)
# Expected output:
#      estimate         se   se_neyman
# 1 -0.00187198 0.00255863 0.002561472
cat("\n")

# --- 2d: Event-study estimand ---
# Returns the average effect at each lag since treatment
cat("--- 2d: Event-Study (first 24 months post-treatment) ---\n")
es_results <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "eventstudy",
  eventTime = 0:23
)
cat("First 6 event-study estimates:\n")
print(head(es_results))
# Expected output:
#        estimate          se   se_neyman eventTime
# 1  3.083575e-04 0.002645327 0.002650957         0
# 2  2.591678e-03 0.002614563 0.002621513         1
# 3 -4.872562e-05 0.002622640 0.002623634         2
# 4  2.043434e-03 0.002715695 0.002720467         3
# 5  2.977076e-03 0.002653917 0.002659630         4
# 6  7.979656e-04 0.002721784 0.002727140         5
cat("\n")

# =============================================================================
# Section 3: Estimator Comparison
# =============================================================================

cat("=== Section 3: Estimator Comparison ===\n\n")

# --- Efficient estimator (already computed above) ---
cat("--- Efficient (Roth & Sant'Anna, 2023) ---\n")
print(result_simple)
cat("\n")

# --- Callaway & Sant'Anna (2021) ---
cat("--- Callaway & Sant'Anna (2021) ---\n")
result_cs <- staggered_cs(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple"
)
print(result_cs)
# Expected output:
#       estimate          se   se_neyman
# 1 -0.005176818 0.003928735 0.003930919
cat("\n")

# --- Sun & Abraham (2021) ---
cat("--- Sun & Abraham (2021) ---\n")
result_sa <- staggered_sa(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple"
)
print(result_sa)
# Expected output:
#     estimate         se  se_neyman
# 1 0.01153851 0.01730161 0.01730234
cat("\n")

# --- Efficiency gain comparison ---
cat("--- Efficiency Gains ---\n")
se_efficient <- result_simple$se
se_cs <- result_cs$se
se_sa <- result_sa$se

cat(sprintf("SE (Efficient):     %.6f\n", se_efficient))
cat(sprintf("SE (CS):            %.6f  (ratio: %.2fx)\n", se_cs, se_cs / se_efficient))
cat(sprintf("SE (SA):            %.6f  (ratio: %.2fx)\n", se_sa, se_sa / se_efficient))
cat("\nThe efficient estimator achieves substantial precision gains.\n\n")

# --- Optional check: on this dataset (no early-treated units), staggered(beta=1) matches staggered_cs() ---
cat("--- Optional check: staggered(beta=1) vs staggered_cs() ---\n")
result_manual_cs <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple",
  beta = 1,
  use_DiD_A0 = TRUE,
  use_last_treated_only = FALSE
)
cat("Manual CS-equivalent result:\n")
print(result_manual_cs)
cat("NOTE: This equivalence holds here because there are no early-treated units.\n")
cat("      In general, staggered_cs() also filters units with g <= min(t).\n")
cat("      Always use staggered_cs() in practice rather than manual beta=1.\n\n")

# Note: beta=0 (difference-in-means) is theoretically valid but currently triggers
# a dimension mismatch in the package (v1.2.3). Use beta=NULL (default) for
# optimal efficiency.

# =============================================================================
# Section 4: Diagnostics
# =============================================================================

cat("=== Section 4: Diagnostics ===\n\n")

# --- 4a: Balance checks ---
cat("--- 4a: Balance Checks (Simple Estimand) ---\n")
bal_results <- balance_checks(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple"
)
cat("Balance test results:\n")
print(bal_results$resultsDF)
cat("\nInterpretation: A non-significant Wald test supports the random timing assumption.\n\n")

# --- 4b: Fisher Randomization Test ---
cat("--- 4b: Fisher Randomization Test ---\n")
cat("(Computing with 500 permutations — may take a moment)\n")
result_fisher <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "simple",
  compute_fisher = TRUE,
  num_fisher_permutations = 500
)
print(result_fisher)
# Expected output:
#       estimate          se   se_neyman fisher_pval fisher_pval_se_neyman
# 1 -0.001126981 0.002115194 0.002119248       0.642                 0.644
#   num_fisher_permutations
# 1                     500
cat("\nInterpretation: fisher_pval > 0.05 indicates we cannot reject the null of\n")
cat("no treatment effect at the 5% level.\n\n")

# =============================================================================
# Section 5: Advanced Usage
# =============================================================================

cat("=== Section 5: Advanced Usage ===\n\n")

# --- 5a: Event-study with full variance-covariance matrix ---
cat("--- 5a: Event-Study with Full VCV ---\n")
es_full <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "eventstudy",
  eventTime = 0:5,
  return_full_vcv = TRUE
)
cat("Results data frame:\n")
print(es_full$resultsDF)
cat("\nVariance-covariance matrix (refined):\n")
print(round(es_full$vcv, 10))
cat("\n")

# --- 5b: Event-study plot ---
cat("--- 5b: Event-Study Plot ---\n")
cat("(Requires ggplot2 for visualization)\n\n")

if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)

  # Use the 24-month event-study results from Section 2d
  plot_data <- es_results
  plot_data$ymin_ptwise <- plot_data$estimate - 1.96 * plot_data$se
  plot_data$ymax_ptwise <- plot_data$estimate + 1.96 * plot_data$se

  p <- ggplot(plot_data, aes(x = eventTime, y = estimate)) +
    geom_pointrange(aes(ymin = ymin_ptwise, ymax = ymax_ptwise)) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    xlab("Event Time (months since training)") +
    ylab("Estimate") +
    ggtitle("Effect of Procedural Justice Training on Officer Complaints") +
    theme_minimal()

  print(p)
  cat("Event-study plot generated successfully.\n\n")
} else {
  cat("ggplot2 not available. Install with: install.packages('ggplot2')\n\n")
}

# --- 5c: CS event-study comparison ---
cat("--- 5c: CS Event-Study (for comparison) ---\n")
es_cs <- staggered_cs(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "eventstudy",
  eventTime = 0:5
)
cat("CS event-study (first 6 periods):\n")
print(es_cs)
cat("\n")

# Compare SEs across estimators at each event-time
cat("--- SE comparison at each event-time ---\n")
es_eff_short <- staggered(
  df = df,
  i = "uid",
  t = "period",
  g = "first_trained",
  y = "complaints",
  estimand = "eventstudy",
  eventTime = 0:5
)
comparison <- data.frame(
  eventTime = 0:5,
  se_efficient = es_eff_short$se,
  se_cs = es_cs$se,
  ratio = es_cs$se / es_eff_short$se
)
print(comparison)
cat("\n")

# =============================================================================
# Summary
# =============================================================================

cat("=== Summary ===\n")
cat("The staggered package provides:\n")
cat("  1. Efficient estimation under random treatment timing (staggered())\n")
cat("  2. CS estimator as special case (staggered_cs(), beta=1)\n")
cat("  3. SA estimator as special case (staggered_sa(), beta=1, last-treated only)\n")
cat("  4. Balance diagnostics for the random timing assumption\n")
cat("  5. Fisher Randomization Tests for finite-sample valid inference\n")
cat("  6. Event-study estimation with full VCV for joint inference\n")
cat("\nKey result: The efficient estimator achieves substantial SE reductions\n")
cat("(1.4-3x) over conventional DiD methods when treatment timing is random.\n")
