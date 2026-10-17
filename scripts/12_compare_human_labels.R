# 12_compare_human_labels.R
# Compares each model's Part B coding with the author's labels on the
# 100-review human sample (data/human_labels.csv), using the author's label
# as the reference.
#
# (a) Weighted estimates for the 500 reviews (hedging and social_proof):
#     sensitivity, specificity and Cohen's kappa, weighting each review by
#     1 / inclusion_prob from data/private/human_sample_strata.csv.
#     95% percentile bootstrap intervals: 2,000 resamples, drawn with
#     replacement within each source ("expertise", "social", "unflagged") so
#     the design is kept; set.seed(2026) before each model-cue bootstrap.
#     expertise_claim: unweighted 2x2 counts only (no weighted estimates).
# (b) Unweighted counts for expertise_claim and social_proof: of the sampled
#     reviews the model flagged, how many the author labelled 1; and how many
#     of the 60 unflagged reviews the author labelled 1 (missed by both models).
# (c) Counts only, no model involved: for each cue, how many reviews the author
#     labelled 1 overall and within each source, with n per source.
# (d) The author's weighted prevalence of each cue across the 500 reviews
#     (weights 1 / inclusion_prob), with a 95% percentile bootstrap interval
#     resampling within source (2,000 resamples, set.seed(2026) per cue).
#
# Writes outputs/human_comparison.csv: statistics only, no review text and no
# review IDs. Prints the same statistics.
# Run from the repository root: Rscript scripts/12_compare_human_labels.R

library(readr)

labels_path <- file.path("data", "human_labels.csv")
strata_path <- file.path("data", "private", "human_sample_strata.csv")
out_path    <- file.path("outputs", "human_comparison.csv")
n_boot      <- 2000
cues        <- c("expertise_claim", "hedging", "social_proof")
weighted_cues <- c("hedging", "social_proof")

human  <- read_csv(labels_path, show_col_types = FALSE)
strata <- read_csv(strata_path, show_col_types = FALSE)
design <- merge(human[c("review_id", cues)], strata[c("review_id", "source", "inclusion_prob")],
                by = "review_id")
stopifnot(nrow(design) == 100, !anyNA(design[cues]))
design$weight <- 1 / design$inclusion_prob

pred_files <- list.files("outputs", pattern = "^part_b_predictions_.*\\.csv$", full.names = TRUE)
if (length(pred_files) == 0) stop("No Part B prediction files found in outputs/.")

# Weighted agreement statistics ------------------------------------------------
# h = author's label (reference), m = model's code, w = weight.
weighted_stats <- function(h, m, w) {
  p11 <- sum(w * (h == 1 & m == 1)); p10 <- sum(w * (h == 1 & m == 0))
  p01 <- sum(w * (h == 0 & m == 1)); p00 <- sum(w * (h == 0 & m == 0))
  total <- p11 + p10 + p01 + p00
  observed <- (p11 + p00) / total
  expected <- ((p11 + p10) * (p11 + p01) + (p01 + p00) * (p10 + p00)) / total^2
  c(
    sensitivity = p11 / (p11 + p10),
    specificity = p00 / (p00 + p01),
    kappa       = (observed - expected) / (1 - expected)
  )
}

# Row indices of one bootstrap resample, drawn within each source.
resample_within_source <- function(source) {
  unlist(lapply(split(seq_along(source), source), function(rows) {
    rows[sample.int(length(rows), length(rows), replace = TRUE)]
  }), use.names = FALSE)
}

results <- list()
add <- function(...) results[[length(results) + 1]] <<- data.frame(...)

for (f in pred_files) {
  p <- read_csv(f, show_col_types = FALSE)
  model <- p$model[1]
  d <- merge(design, p[c("review_id", cues)], by = "review_id", suffixes = c("_human", "_model"))
  stopifnot(nrow(d) == 100, !anyNA(d))

  for (cue in cues) {
    h <- d[[paste0(cue, "_human")]]
    m <- d[[paste0(cue, "_model")]]

    # (a) weighted estimates with bootstrap CIs (hedging, social_proof)
    if (cue %in% weighted_cues) {
      est <- weighted_stats(h, m, d$weight)
      set.seed(2026)
      boot <- replicate(n_boot, {
        i <- resample_within_source(d$source)
        weighted_stats(h[i], m[i], d$weight[i])
      })
      ci <- apply(boot, 1, quantile, probs = c(0.025, 0.975), na.rm = TRUE)
      valid <- colSums(is.finite(t(boot)))
      for (s in names(est)) {
        add(model = model, cue = cue, analysis = "a_weighted_500", metric = s,
            estimate = round(est[[s]], 3), ci_low = round(ci[1, s], 3),
            ci_high = round(ci[2, s], 3), n = n_boot, note = paste("valid resamples:", valid[[s]]))
      }
    }

    # (a) expertise_claim: unweighted 2x2 counts only
    if (cue == "expertise_claim") {
      cells <- c(human1_model1 = sum(h == 1 & m == 1), human1_model0 = sum(h == 1 & m == 0),
                 human0_model1 = sum(h == 0 & m == 1), human0_model0 = sum(h == 0 & m == 0))
      for (s in names(cells)) {
        add(model = model, cue = cue, analysis = "a_counts_sample", metric = s,
            estimate = cells[[s]], ci_low = NA, ci_high = NA, n = 100, note = "unweighted")
      }
    }

    # (b) unweighted counts (expertise_claim, social_proof)
    if (cue %in% c("expertise_claim", "social_proof")) {
      flagged <- m == 1
      add(model = model, cue = cue, analysis = "b_counts_sample", metric = "model_flagged_in_sample",
          estimate = sum(flagged), ci_low = NA, ci_high = NA, n = 100, note = "unweighted")
      add(model = model, cue = cue, analysis = "b_counts_sample", metric = "of_flagged_author_labelled_1",
          estimate = sum(flagged & h == 1), ci_low = NA, ci_high = NA, n = sum(flagged), note = "unweighted")
      unflagged <- d$source == "unflagged"
      add(model = model, cue = cue, analysis = "b_counts_sample", metric = "of_60_unflagged_author_labelled_1",
          estimate = sum(unflagged & h == 1), ci_low = NA, ci_high = NA, n = sum(unflagged),
          note = "unweighted; missed by both models")
    }
  }
}

# (c) author's counts per cue, overall and by source (no model involved)
for (cue in cues) {
  h <- design[[cue]]
  add(model = "", cue = cue, analysis = "c_author_counts", metric = "labelled_1_overall",
      estimate = sum(h == 1), ci_low = NA, ci_high = NA, n = length(h), note = "unweighted")
  for (src in c("expertise", "social", "unflagged")) {
    in_src <- design$source == src
    add(model = "", cue = cue, analysis = "c_author_counts", metric = paste0("labelled_1_", src),
        estimate = sum(h[in_src] == 1), ci_low = NA, ci_high = NA, n = sum(in_src), note = "unweighted")
  }
}

# (d) author's weighted prevalence across the 500 reviews, bootstrap within source
weighted_prevalence <- function(h, w) sum(w * (h == 1)) / sum(w)
for (cue in cues) {
  h <- design[[cue]]
  est <- weighted_prevalence(h, design$weight)
  set.seed(2026)
  boot <- replicate(n_boot, {
    i <- resample_within_source(design$source)
    weighted_prevalence(h[i], design$weight[i])
  })
  add(model = "", cue = cue, analysis = "d_author_prevalence_500", metric = "weighted_prevalence",
      estimate = round(est, 3), ci_low = round(quantile(boot, 0.025), 3),
      ci_high = round(quantile(boot, 0.975), 3), n = n_boot, note = "weights 1 / inclusion_prob")
}

comparison <- do.call(rbind, results)
write_csv(comparison, out_path, na = "")

print(comparison, row.names = FALSE)
cat("\nWrote:", out_path, "\n")
