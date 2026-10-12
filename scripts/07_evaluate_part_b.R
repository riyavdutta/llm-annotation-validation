# 07_evaluate_part_b.R
# Part B reliability: how often each trust cue is coded as present, and how
# well two models agree on each cue.
# Analysis fixed before any full Part B run:
#   - prevalence of each cue per model
#   - per cue, between the two models: Cohen's kappa (primary), plus percent
#     agreement and Gwet's AC1. Kappa drops when a cue is rare even if coders
#     mostly agree; AC1 does not, but AC1 can also be high for random coding
#     of a rare cue (dry run: 0.87 at 5% prevalence), so it is never read alone.
#   - 95% CIs by percentile bootstrap (2,000 resamples)
# Uses the two files outputs/part_b_predictions_*.csv.
# Writes outputs/part_b_agreement.csv. No review text.
# Run from the repository root: Rscript scripts/07_evaluate_part_b.R

library(readr)

n_boot <- 2000
cues <- c("expertise_claim", "hedging", "social_proof")

pred_files <- list.files("outputs", pattern = "^part_b_predictions_.*\\.csv$", full.names = TRUE)
if (length(pred_files) != 2) stop("Expected exactly 2 Part B prediction files, found ", length(pred_files), ".")

a <- read_csv(pred_files[1], show_col_types = FALSE)
b <- read_csv(pred_files[2], show_col_types = FALSE)
model_a <- a$model[1]
model_b <- b$model[1]

d <- merge(a[c("review_id", cues)], b[c("review_id", cues)], by = "review_id", suffixes = c("_a", "_b"))
d <- d[complete.cases(d), ]
cat("Models:", model_a, "vs.", model_b, "| reviews with both codings:", nrow(d), "\n")

# Agreement statistics for two binary codings ----------------------------------
agreement <- function(x, y) {
  p_obs <- mean(x == y)
  # Cohen's kappa: chance agreement from each coder's own prevalence.
  p_exp_kappa <- mean(x) * mean(y) + (1 - mean(x)) * (1 - mean(y))
  # Gwet's AC1: chance agreement from the average prevalence.
  pi <- (mean(x) + mean(y)) / 2
  p_exp_ac1 <- 2 * pi * (1 - pi)
  c(
    agreement = p_obs,
    kappa     = (p_obs - p_exp_kappa) / (1 - p_exp_kappa),
    ac1       = (p_obs - p_exp_ac1) / (1 - p_exp_ac1)
  )
}

results <- do.call(rbind, lapply(cues, function(cue) {
  x <- d[[paste0(cue, "_a")]]
  y <- d[[paste0(cue, "_b")]]
  est <- agreement(x, y)
  set.seed(2026)
  boot <- replicate(n_boot, {
    i <- sample(length(x), replace = TRUE)
    agreement(x[i], y[i])
  })
  ci <- apply(boot, 1, quantile, probs = c(0.025, 0.975), na.rm = TRUE)
  data.frame(
    cue          = cue,
    prevalence_a = round(mean(x), 3),
    prevalence_b = round(mean(y), 3),
    both_present = sum(x == 1 & y == 1),
    metric       = names(est),
    estimate     = round(est, 3),
    ci_low       = round(ci[1, ], 3),
    ci_high      = round(ci[2, ], 3)
  )
}))
results$model_a <- model_a
results$model_b <- model_b

cat("\nPrevalence: share of reviews coded 1 by", model_a, "(a) and", model_b, "(b)\n\n")
print(results[c("cue", "prevalence_a", "prevalence_b", "both_present",
                "metric", "estimate", "ci_low", "ci_high")], row.names = FALSE)

write_csv(results, file.path("outputs", "part_b_agreement.csv"))
cat("\nWrote outputs/part_b_agreement.csv\n")
