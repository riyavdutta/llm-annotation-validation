# 08_predict_helpfulness.R
# Part B predictive validity: do the coded trust cues predict how many other
# shoppers found a review helpful (Positive Feedback Count)?
# Analysis fixed before any full Part B run:
#   - negative binomial regression (counts are skewed, many zeros), per model:
#       positive_feedback ~ expertise_claim + hedging + social_proof
#                           + log(word_count) + factor(rating)
#   - results reported as incidence rate ratios (IRR) with 95% Wald CIs;
#     IRR > 1 means more helpful votes when the cue is present
#   - controls: review length and star rating, both known to relate to votes
# Writes outputs/part_b_helpfulness_models.csv. No review text.
# Run from the repository root: Rscript scripts/08_predict_helpfulness.R

library(readr)
library(MASS)  # glm.nb(); ships with R

cues <- c("expertise_claim", "hedging", "social_proof")
sample_path <- file.path("data", "private", "main_sample.csv")

main_sample <- read_csv(sample_path, show_col_types = FALSE)[
  c("review_id", "rating", "positive_feedback", "word_count")]

pred_files <- list.files("outputs", pattern = "^part_b_predictions_.*\\.csv$", full.names = TRUE)
if (length(pred_files) == 0) stop("No Part B prediction files found in outputs/.")

fit_model <- function(pred_file) {
  predictions <- read_csv(pred_file, show_col_types = FALSE)
  model <- predictions$model[1]
  d <- merge(main_sample, predictions[c("review_id", cues)], by = "review_id")
  d <- d[complete.cases(d), ]

  # Deviation from plan (session 7): a cue this model never (or always) codes
  # has no variation and cannot be estimated, so it is left out of this
  # model's regression and reported.
  usable <- cues[sapply(cues, function(cue) length(unique(d[[cue]])) > 1)]
  dropped <- setdiff(cues, usable)
  if (length(dropped) > 0) {
    cat("\nNote (", model, "): no variation in ", paste(dropped, collapse = ", "),
        "; left out of the regression.\n", sep = "")
  }

  formula <- reformulate(c(usable, "log(word_count)", "factor(rating)"),
                         response = "positive_feedback")
  fit <- glm.nb(formula, data = d)

  est <- coef(summary(fit))
  ci  <- confint.default(fit)
  out <- data.frame(
    model   = model,
    term    = rownames(est),
    irr     = round(exp(est[, "Estimate"]), 3),
    ci_low  = round(exp(ci[, 1]), 3),
    ci_high = round(exp(ci[, 2]), 3),
    p_value = signif(est[, "Pr(>|z|)"], 3),
    n       = nrow(d),
    theta   = round(fit$theta, 3),
    dropped_cues = if (length(dropped) > 0) paste(dropped, collapse = ";") else ""
  )

  cat("\n==================== ", model, " ====================\n", sep = "")
  cat("n =", nrow(d), "| theta =", round(fit$theta, 3), "\n")
  print(out[c("term", "irr", "ci_low", "ci_high", "p_value")], row.names = FALSE)
  out
}

all_fits <- do.call(rbind, lapply(pred_files, fit_model))
write_csv(all_fits, file.path("outputs", "part_b_helpfulness_models.csv"))
cat("\nWrote outputs/part_b_helpfulness_models.csv\n")
