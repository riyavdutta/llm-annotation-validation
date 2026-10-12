# 05_evaluate_part_a.R
# Part A evaluation: compares the model's predictions with the reviewers' own
# recommendation and rating.
# Primary metrics (fixed before looking at results):
#   recommendation: Cohen's kappa
#   rating:         quadratic-weighted kappa
# Secondary: accuracy vs. majority baseline, per-class precision/recall,
# exact and within-one-star agreement, mean absolute error, Spearman's rho.
# 95% CIs by percentile bootstrap (2,000 resamples).
# Writes outputs/part_a_metrics.csv and two confusion matrices. No review text.
# Run from the repository root: Rscript scripts/05_evaluate_part_a.R

library(readr)

pred_path   <- file.path("outputs", "part_a_predictions.csv")
sample_path <- file.path("data", "private", "main_sample.csv")
n_boot      <- 2000

predictions <- read_csv(pred_path, show_col_types = FALSE)
truth <- read_csv(sample_path, show_col_types = FALSE)[c("review_id", "rating", "recommended")]

d <- merge(truth, predictions[c("review_id", "pred_recommend", "pred_rating")], by = "review_id")
d <- d[!is.na(d$pred_recommend) & !is.na(d$pred_rating), ]
cat("Reviews evaluated:", nrow(d), "\n")

# Agreement statistics ---------------------------------------------------------
# Cohen's kappa; with weights = "quadratic", disagreements are penalised by the
# squared distance between categories (suited to ordered ratings).
kappa <- function(a, b, levels, weights = c("none", "quadratic")) {
  weights <- match.arg(weights)
  p <- prop.table(table(factor(a, levels), factor(b, levels)))
  k <- length(levels)
  w <- if (weights == "none") diag(k) else 1 - outer(1:k, 1:k, function(i, j) (i - j)^2) / (k - 1)^2
  observed <- sum(w * p)
  expected <- sum(w * outer(rowSums(p), colSums(p)))
  (observed - expected) / (1 - expected)
}

# All metrics for one data set; reused on each bootstrap resample.
compute_metrics <- function(d) {
  rec_tp_0 <- sum(d$recommended == 0 & d$pred_recommend == 0)
  c(
    rec_kappa          = kappa(d$recommended, d$pred_recommend, 0:1),
    rec_accuracy       = mean(d$recommended == d$pred_recommend),
    rec_majority_base  = max(mean(d$recommended), 1 - mean(d$recommended)),
    rec_recall_no      = rec_tp_0 / sum(d$recommended == 0),
    rec_precision_no   = rec_tp_0 / sum(d$pred_recommend == 0),
    rec_recall_yes     = mean(d$pred_recommend[d$recommended == 1] == 1),
    rating_qw_kappa    = kappa(d$rating, d$pred_rating, 1:5, "quadratic"),
    rating_exact       = mean(d$rating == d$pred_rating),
    rating_within_one  = mean(abs(d$rating - d$pred_rating) <= 1),
    rating_mae         = mean(abs(d$rating - d$pred_rating)),
    rating_spearman    = cor(d$rating, d$pred_rating, method = "spearman")
  )
}

estimates <- compute_metrics(d)

set.seed(2026)
boot <- replicate(n_boot, compute_metrics(d[sample(nrow(d), replace = TRUE), ]))
ci <- apply(boot, 1, quantile, probs = c(0.025, 0.975), na.rm = TRUE)

metrics <- data.frame(
  metric   = names(estimates),
  estimate = round(estimates, 3),
  ci_low   = round(ci[1, ], 3),
  ci_high  = round(ci[2, ], 3)
)
metrics[metrics$metric == "rec_majority_base", c("ci_low", "ci_high")] <- NA

cat("\n== Metrics (95% bootstrap CI) ==\n")
print(metrics, row.names = FALSE)

# Confusion matrices: rows = reviewer, columns = model -------------------------
conf_rec <- table(reviewer = factor(d$recommended, 0:1), model = factor(d$pred_recommend, 0:1))
conf_rating <- table(reviewer = factor(d$rating, 1:5), model = factor(d$pred_rating, 1:5))

cat("\n== Recommendation (rows = reviewer, cols = model; 0 = no, 1 = yes) ==\n")
print(conf_rec)
cat("\n== Rating (rows = reviewer, cols = model) ==\n")
print(conf_rating)

cat("\n== Mean predicted rating by true rating ==\n")
print(round(tapply(d$pred_rating, d$rating, mean), 2))

write_csv(metrics, file.path("outputs", "part_a_metrics.csv"), na = "")
write_csv(as.data.frame(conf_rec), file.path("outputs", "part_a_confusion_recommend.csv"))
write_csv(as.data.frame(conf_rating), file.path("outputs", "part_a_confusion_rating.csv"))
cat("\nWrote outputs/part_a_metrics.csv and two confusion-matrix files.\n")
