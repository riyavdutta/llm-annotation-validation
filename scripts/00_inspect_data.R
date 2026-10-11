# 00_inspect_data.R
# Read-only inspection of the raw Women's E-Commerce Clothing Reviews CSV.
# Prints basic descriptives. Does not modify or write any data.
# Run from the repository root: Rscript scripts/00_inspect_data.R

library(readr)

raw_path <- file.path("data", "raw", "Womens Clothing E-Commerce Reviews.csv")
expected_rows <- 23486

reviews <- read_csv(raw_path, show_col_types = FALSE)

# Rows ------------------------------------------------------------------------
cat("== Number of rows ==\n")
cat(nrow(reviews), "rows (expected", expected_rows, ")\n")
if (nrow(reviews) != expected_rows) {
  cat("WARNING: row count differs from expected.\n")
}

# Columns ---------------------------------------------------------------------
cat("\n== Column names ==\n")
print(names(reviews))

# Missing values --------------------------------------------------------------
# Empty strings are counted alongside NA, since both mean "no text".
count_missing <- function(x) sum(is.na(x) | trimws(x) == "")

cat("\n== Missing values ==\n")
cat("Review Text:", count_missing(reviews$`Review Text`), "\n")
cat("Title:      ", count_missing(reviews$Title), "\n")

# Review length in words ------------------------------------------------------
# Words are runs of non-whitespace characters; computed on non-missing texts only.
has_text <- !is.na(reviews$`Review Text`) & trimws(reviews$`Review Text`) != ""
word_counts <- lengths(strsplit(trimws(reviews$`Review Text`[has_text]), "\\s+"))

cat("\n== Review length in words (non-missing texts, n =", length(word_counts), ") ==\n")
cat("Min:   ", min(word_counts), "\n")
cat("Median:", median(word_counts), "\n")
cat("Max:   ", max(word_counts), "\n")

# Rating distribution ---------------------------------------------------------
cat("\n== Rating distribution ==\n")
rating_counts <- table(reviews$Rating, useNA = "ifany")
print(data.frame(
  rating  = names(rating_counts),
  n       = as.integer(rating_counts),
  percent = round(100 * as.integer(rating_counts) / nrow(reviews), 1)
), row.names = FALSE)

# Random examples -------------------------------------------------------------
# For eyeballing the text only; this is not the study sample.
cat("\n== 5 random review texts (set.seed(42)) ==\n")
set.seed(42)
example_rows <- sample(which(has_text), 5)
for (i in example_rows) {
  cat("\n[row", i, "| rating", reviews$Rating[i], "]\n")
  cat(reviews$`Review Text`[i], "\n")
}
