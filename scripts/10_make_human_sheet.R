# 10_make_human_sheet.R
# Builds a 100-review sheet for blind human coding of the three trust cues.
#
# Sampling, from the 500-review main sample, set.seed(31):
#   1. every review that either model coded as expertise_claim
#   2. 34 reviews chosen at random from those that either model coded as
#      social_proof (excluding any already picked in step 1)
#   3. 60 reviews chosen at random from those that neither model coded as
#      expertise_claim or social_proof
# Steps 1-2 form the "flagged" stratum, step 3 the "unflagged" stratum.
# Flagged reviews are over-represented on purpose, so any later estimate over
# all 500 reviews must weight each review by 1 / inclusion_prob.
# The 100 reviews are then shuffled (set.seed(31) again) so that sheet order
# does not reveal the stratum.
#
# Writes (both git-ignored):
#   data/private/human_coding_sheet.csv   review_id, text, and empty columns
#                                         expertise_claim, hedging,
#                                         social_proof, uncertain, notes
#   data/private/human_sample_strata.csv  review_id, stratum ("flagged" or
#                                         "unflagged"), source ("expertise",
#                                         "social" or "unflagged"), pool_size
#                                         (reviews in the pool the source was
#                                         drawn from), inclusion_prob (number
#                                         sampled from that pool / pool_size)
# The sheet contains no model output or flag information.
# Prints counts only: no review text, no review_ids, no model predictions.
# Run from the repository root: Rscript scripts/10_make_human_sheet.R

library(readr)

sample_path <- file.path("data", "private", "main_sample.csv")
sheet_path  <- file.path("data", "private", "human_coding_sheet.csv")
strata_path <- file.path("data", "private", "human_sample_strata.csv")
n_social    <- 34
n_random    <- 60
n_total     <- 100

# Refuse to overwrite: the sheet may already contain hand-entered codes.
if (file.exists(sheet_path) || file.exists(strata_path)) {
  stop("Output file already exists. Delete or rename it yourself to regenerate.")
}

main_sample <- read_csv(sample_path, show_col_types = FALSE)

pred_files <- list.files("outputs", pattern = "^part_b_predictions_.*\\.csv$", full.names = TRUE)
if (length(pred_files) == 0) stop("No Part B prediction files found in outputs/.")

# Review ids that at least one model coded 1 for a cue.
flagged_by_any <- function(cue) {
  ids <- unlist(lapply(pred_files, function(f) {
    p <- read_csv(f, show_col_types = FALSE)
    p$review_id[!is.na(p[[cue]]) & p[[cue]] == 1]
  }))
  sort(unique(ids))
}

expertise_ids <- flagged_by_any("expertise_claim")
social_ids    <- flagged_by_any("social_proof")
neither_ids   <- sort(setdiff(main_sample$review_id, union(expertise_ids, social_ids)))

social_pool <- setdiff(social_ids, expertise_ids)
stopifnot(length(social_pool) >= n_social, length(neither_ids) >= n_random)

# Sampling --------------------------------------------------------------------
set.seed(31)
social_pick  <- social_pool[sample(length(social_pool), n_social)]
random_pick  <- neither_ids[sample(length(neither_ids), n_random)]

flagged_pick <- c(expertise_ids, social_pick)
n_expertise  <- length(expertise_ids)

# Pool sizes for each source; every expertise-flagged review is taken.
pool_expertise <- length(expertise_ids)
pool_social    <- length(social_pool)
pool_unflagged <- length(neither_ids)

picked <- data.frame(
  review_id      = c(flagged_pick, random_pick),
  stratum        = c(rep("flagged", length(flagged_pick)), rep("unflagged", n_random)),
  source         = c(rep("expertise", n_expertise), rep("social", n_social),
                     rep("unflagged", n_random)),
  pool_size      = c(rep(pool_expertise, n_expertise), rep(pool_social, n_social),
                     rep(pool_unflagged, n_random)),
  inclusion_prob = c(rep(n_expertise / pool_expertise, n_expertise),
                     rep(n_social / pool_social, n_social),
                     rep(n_random / pool_unflagged, n_random))
)

stopifnot(nrow(picked) == n_total, !anyDuplicated(picked$review_id))

# Shuffle with the same seed so the sheet order does not reveal the stratum.
set.seed(31)
picked <- picked[sample(nrow(picked)), ]

# Sheet: text only, no model output or flags -----------------------------------
text <- main_sample$text[match(picked$review_id, main_sample$review_id)]
stopifnot(!anyNA(text))

sheet <- data.frame(
  review_id       = picked$review_id,
  text            = text,
  expertise_claim = NA_character_,
  hedging         = NA_character_,
  social_proof    = NA_character_,
  uncertain       = NA_character_,
  notes           = NA_character_
)

write_csv(sheet, sheet_path, na = "")
write_csv(picked, strata_path)

# Counts only ------------------------------------------------------------------
cat("Pool sizes in the 500-review sample:\n")
cat("  expertise (flagged for expertise_claim by either model):         ", pool_expertise, "\n")
cat("  social (flagged for social_proof by either model, not expertise):", pool_social, "\n")
cat("  unflagged (flagged for neither):                                 ", pool_unflagged, "\n")
cat("\nSheet: ", nrow(sheet), " reviews (flagged ", sum(picked$stratum == "flagged"),
    ", unflagged ", sum(picked$stratum == "unflagged"), "), unique ids: ",
    length(unique(sheet$review_id)), "\n", sep = "")
cat("Wrote:", sheet_path, "\n")
cat("Wrote:", strata_path, "\n")
