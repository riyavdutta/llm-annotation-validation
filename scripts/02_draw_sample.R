# 02_draw_sample.R
# Draws the main analysis sample of 500 reviews, excluding the 30 pilot reviews.
# Writes:
#   data/private/main_sample.csv    (git-ignored; text + reviewer-given variables)
#   data/processed/main_ids.csv     (review_id only)
# Prints counts only, never review text.
# Run from the repository root: Rscript scripts/02_draw_sample.R

library(readr)

raw_path    <- file.path("data", "raw", "Womens Clothing E-Commerce Reviews.csv")
pilot_path  <- file.path("data", "processed", "pilot_ids.csv")
sample_path <- file.path("data", "private", "main_sample.csv")
ids_path    <- file.path("data", "processed", "main_ids.csv")
n_sample    <- 500

if (file.exists(sample_path)) {
  stop(sample_path, " already exists. Delete or rename it yourself to regenerate.")
}

reviews <- read_csv(raw_path, show_col_types = FALSE, name_repair = "unique_quiet")
pilot_ids <- read_csv(pilot_path, show_col_types = FALSE)$review_id

# Same review_id and text construction as 01_make_pilot_sheet.R.
reviews$review_id <- seq_len(nrow(reviews))

is_missing <- function(x) is.na(x) | trimws(x) == ""

title_ok <- !is_missing(reviews$Title)
text_ok  <- !is_missing(reviews$`Review Text`)

reviews$text <- ifelse(
  title_ok & text_ok, paste(reviews$Title, reviews$`Review Text`, sep = "\n"),
  ifelse(title_ok, reviews$Title, reviews$`Review Text`)
)

available <- reviews[(title_ok | text_ok) & !(reviews$review_id %in% pilot_ids), ]

cat("Rows in raw file:                ", nrow(reviews), "\n")
cat("With title or text:              ", sum(title_ok | text_ok), "\n")
cat("Pilot reviews excluded:          ", length(pilot_ids), "\n")
cat("Available for main sample:       ", nrow(available), "\n")

# Simple random sample ---------------------------------------------------------
set.seed(2026)
main <- available[sample(nrow(available), n_sample), ]

main_sample <- data.frame(
  review_id          = main$review_id,
  text               = main$text,
  rating             = main$Rating,
  recommended        = main$`Recommended IND`,
  positive_feedback  = main$`Positive Feedback Count`,
  word_count         = lengths(strsplit(trimws(main$text), "\\s+"))
)

write_csv(main_sample, sample_path)
write_csv(data.frame(review_id = main_sample$review_id), ids_path)

# Checks (counts only) ---------------------------------------------------------
cat("\nSampled:                         ", nrow(main_sample), "\n")
cat("Unique review_ids:               ", length(unique(main_sample$review_id)), "\n")
cat("Overlap with pilot:              ", sum(main_sample$review_id %in% pilot_ids), "\n")

cat("\nRating in sample vs. full file (%):\n")
print(round(rbind(
  sample = 100 * prop.table(table(factor(main_sample$rating, levels = 1:5))),
  full   = 100 * prop.table(table(factor(reviews$Rating, levels = 1:5)))
), 1))

cat("\nRecommended = 1:                 ",
    round(100 * mean(main_sample$recommended), 1), "% (full file:",
    round(100 * mean(reviews$`Recommended IND`), 1), "%)\n")
cat("Positive feedback = 0:           ",
    round(100 * mean(main_sample$positive_feedback == 0), 1), "%\n")
cat("Word count (min / median / max): ",
    min(main_sample$word_count), "/", median(main_sample$word_count), "/",
    max(main_sample$word_count), "\n")

cat("\nWrote:", sample_path, "\n")
cat("Wrote:", ids_path, "\n")
