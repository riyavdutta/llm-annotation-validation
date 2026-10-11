# 01_make_pilot_sheet.R
# Draws 30 reviews for the author's pilot labelling and writes:
#   data/private/pilot_sheet.csv   (git-ignored; review text + empty label columns)
#   data/processed/pilot_ids.csv   (review_id only, to exclude from the main sample)
# Prints counts only, never review text.
# Run from the repository root: Rscript scripts/01_make_pilot_sheet.R

library(readr)

raw_path   <- file.path("data", "raw", "Womens Clothing E-Commerce Reviews.csv")
sheet_path <- file.path("data", "private", "pilot_sheet.csv")
ids_path   <- file.path("data", "processed", "pilot_ids.csv")
n_pilot    <- 30

# Refuse to overwrite: the sheet may already contain hand-entered labels.
if (file.exists(sheet_path)) {
  stop(sheet_path, " already exists. Delete or rename it yourself to regenerate.")
}

reviews <- read_csv(raw_path, show_col_types = FALSE, name_repair = "unique_quiet")
stopifnot(all(c("Title", "Review Text") %in% names(reviews)))

# review_id = row number in the original file (1-based).
# The file's unnamed first column equals review_id - 1.
reviews$review_id <- seq_len(nrow(reviews))

# Join title and review text --------------------------------------------------
# Missing = NA or blank, as in 00_inspect_data.R. When both parts are present
# they are joined with a line break so no punctuation is added to either.
is_missing <- function(x) is.na(x) | trimws(x) == ""

title_ok <- !is_missing(reviews$Title)
text_ok  <- !is_missing(reviews$`Review Text`)

reviews$text <- ifelse(
  title_ok & text_ok, paste(reviews$Title, reviews$`Review Text`, sep = "\n"),
  ifelse(title_ok, reviews$Title, reviews$`Review Text`)
)

available <- reviews[title_ok | text_ok, ]

cat("Rows in raw file:            ", nrow(reviews), "\n")
cat("Rows dropped (both missing): ", nrow(reviews) - nrow(available), "\n")
cat("Reviews available:           ", nrow(available), "\n")
cat("  with title and text:       ", sum(title_ok & text_ok), "\n")
cat("  text only:                 ", sum(!title_ok & text_ok), "\n")
cat("  title only:                ", sum(title_ok & !text_ok), "\n")

# Sample ----------------------------------------------------------------------
set.seed(2026)
pilot <- available[sample(nrow(available), n_pilot), ]

pilot_sheet <- data.frame(
  review_id       = pilot$review_id,
  text            = pilot$text,
  expertise_claim = NA_character_,
  hedging         = NA_character_,
  social_proof    = NA_character_,
  notes           = NA_character_
)

write_csv(pilot_sheet, sheet_path, na = "")
write_csv(data.frame(review_id = pilot$review_id), ids_path)

# Checks (counts only) --------------------------------------------------------
cat("\nSampled:                     ", nrow(pilot_sheet), "\n")
cat("Unique review_ids:           ", length(unique(pilot_sheet$review_id)), "\n")
cat("Empty text fields:           ", sum(is_missing(pilot_sheet$text)), "\n")
cat("Wrote:", sheet_path, "\n")
cat("Wrote:", ids_path, "\n")
