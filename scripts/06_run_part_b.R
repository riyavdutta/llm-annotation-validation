# 06_run_part_b.R
# Part B: codes three trust cues (expertise_claim, hedging, social_proof) in
# each sampled review with the local model, using prompts/part_b_v0.txt, which
# was written from the definitions in codebook/codebook_v0.md (unchanged in v1).
#
# Usage, from the repository root:
#   Rscript scripts/06_run_part_b.R <model> --test   first 5 reviews, prints only
#   Rscript scripts/06_run_part_b.R <model>          all 500, writes
#                                                    outputs/part_b_predictions_<model>.csv
#   Rscript scripts/06_run_part_b.R <model> --retry-failed
#                                                    re-runs only rows whose call failed
#                                                    (e.g. timeouts), same settings, and
#                                                    updates those rows in the output file
# Only the review text is sent to the model. No review text is printed or saved.

library(readr)
source(file.path("scripts", "ollama_helpers.R"))

args        <- commandArgs(trailingOnly = TRUE)
model       <- if (length(args) >= 1 && !startsWith(args[1], "--")) args[1] else "llama3.2:3b"
test_mode   <- "--test" %in% args
retry_mode  <- "--retry-failed" %in% args
prompt_path <- file.path("prompts", "part_b_v0.txt")
sample_path <- file.path("data", "private", "main_sample.csv")
out_path    <- file.path("outputs", paste0("part_b_predictions_", model_slug(model), ".csv"))

model_options <- list(temperature = 0, seed = 42)
cues <- c("expertise_claim", "hedging", "social_proof")

answer_schema <- list(
  type       = "object",
  properties = setNames(rep(list(list(type = "boolean")), 3), cues),
  required   = as.list(cues)
)

if (!test_mode && !retry_mode && file.exists(out_path)) {
  stop(out_path, " already exists. Delete or rename it yourself to re-run.")
}
if (retry_mode && !file.exists(out_path)) {
  stop(out_path, " does not exist; nothing to retry.")
}

info <- ollama_info(model)
build_prompt <- load_prompt(prompt_path)
prompt_md5 <- unname(tools::md5sum(prompt_path))

cat("Ollama", info$version, "| model", model, "| digest", substr(info$digest, 1, 12), "\n")
cat("Prompt", prompt_path, "| md5", prompt_md5, "\n")

main_sample <- read_csv(sample_path, show_col_types = FALSE)
if (test_mode) main_sample <- head(main_sample, 5)
if (retry_mode) {
  previous <- read_csv(out_path, show_col_types = FALSE)
  stopifnot(previous$prompt_md5[1] == prompt_md5, previous$model_digest[1] == info$digest)
  failed_ids <- previous$review_id[!is.na(previous$error)]
  main_sample <- main_sample[main_sample$review_id %in% failed_ids, ]
}
n <- nrow(main_sample)
cat(if (test_mode) "TEST MODE: " else if (retry_mode) "RETRY MODE: " else "",
    "reviews to annotate: ", n, "\n\n", sep = "")

# One review at a time; a failed call is recorded as NA instead of stopping the run.
results <- vector("list", n)
start <- Sys.time()

for (i in seq_len(n)) {
  results[[i]] <- tryCatch({
    reply <- ask_ollama(build_prompt(main_sample$text[i]), model, answer_schema, model_options)
    coded <- lapply(cues, function(cue) as.integer(isTRUE(reply$answer[[cue]])))
    data.frame(setNames(coded, cues),
               seconds = round(reply$seconds, 3),
               raw_response = reply$raw,
               error = NA_character_)
  }, error = function(e) {
    data.frame(setNames(rep(list(NA_integer_), 3), cues),
               seconds = NA_real_, raw_response = NA_character_,
               error = conditionMessage(e))
  })
  if (i %% 50 == 0) cat("  done", i, "of", n, "\n")
}

predictions <- cbind(review_id = main_sample$review_id, do.call(rbind, results))

cat("Finished in", round(as.numeric(difftime(Sys.time(), start, units = "mins")), 1), "minutes\n")
cat("Failed calls:", sum(!is.na(predictions$error)), "\n")
cat("Cue present (% of reviews):\n")
print(round(100 * colMeans(predictions[cues], na.rm = TRUE), 1))

if (test_mode) {
  cat("\n")
  print(predictions[c("review_id", cues, "seconds")], row.names = FALSE)
  cat("\nTest mode: nothing written.\n")
} else if (retry_mode) {
  rows <- match(predictions$review_id, previous$review_id)
  previous[rows, c(cues, "seconds", "raw_response", "error")] <-
    predictions[c(cues, "seconds", "raw_response", "error")]
  write_csv(previous, out_path, na = "")
  cat("Updated", length(rows), "row(s) in", out_path,
      "| still failed:", sum(!is.na(previous$error)), "\n")
} else {
  predictions$model          <- model
  predictions$model_digest   <- info$digest
  predictions$ollama_version <- info$version
  predictions$prompt_file    <- prompt_path
  predictions$prompt_md5     <- prompt_md5
  predictions$temperature    <- model_options$temperature
  predictions$seed           <- model_options$seed
  write_csv(predictions, out_path, na = "")
  cat("Wrote:", out_path, "\n")
}
