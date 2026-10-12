# 04_run_part_a.R
# Part A: asks the local model, from the review text only, whether each reviewer
# recommends the item and which rating they gave. Runs all 500 sampled reviews.
# Writes outputs/part_a_predictions_<model>.csv (predictions only, no review text).
# The true rating and recommendation are never sent to the model.
# Run from the repository root: Rscript scripts/04_run_part_a.R [model]
# (default model: llama3.2:3b)

library(readr)
source(file.path("scripts", "ollama_helpers.R"))

args        <- commandArgs(trailingOnly = TRUE)
model       <- if (length(args) >= 1) args[1] else "llama3.2:3b"
prompt_path <- file.path("prompts", "part_a_v0.txt")
sample_path <- file.path("data", "private", "main_sample.csv")
out_path    <- file.path("outputs", paste0("part_a_predictions_", model_slug(model), ".csv"))

model_options <- list(temperature = 0, seed = 42)

answer_schema <- list(
  type       = "object",
  properties = list(
    recommend = list(type = "boolean"),
    rating    = list(type = "integer", enum = 1:5)
  ),
  required   = list("recommend", "rating")
)

if (file.exists(out_path)) {
  stop(out_path, " already exists. Delete or rename it yourself to re-run.")
}

info <- ollama_info(model)
build_prompt <- load_prompt(prompt_path)
prompt_md5 <- unname(tools::md5sum(prompt_path))

cat("Ollama", info$version, "| model", model, "| digest", substr(info$digest, 1, 12), "\n")
cat("Prompt", prompt_path, "| md5", prompt_md5, "\n")

main_sample <- read_csv(sample_path, show_col_types = FALSE)
n <- nrow(main_sample)
cat("Reviews to annotate:", n, "\n\n")

# One review at a time; a failed call is recorded as NA instead of stopping the run.
results <- vector("list", n)
start <- Sys.time()

for (i in seq_len(n)) {
  results[[i]] <- tryCatch({
    reply <- ask_ollama(build_prompt(main_sample$text[i]), model, answer_schema, model_options)
    data.frame(
      pred_recommend = as.integer(isTRUE(reply$answer$recommend)),
      pred_rating    = as.integer(reply$answer$rating),
      seconds        = round(reply$seconds, 3),
      raw_response   = reply$raw,
      error          = NA_character_
    )
  }, error = function(e) {
    data.frame(pred_recommend = NA_integer_, pred_rating = NA_integer_,
               seconds = NA_real_, raw_response = NA_character_,
               error = conditionMessage(e))
  })
  if (i %% 50 == 0) cat("  done", i, "of", n, "\n")
}

predictions <- cbind(review_id = main_sample$review_id, do.call(rbind, results))
predictions$model          <- model
predictions$model_digest   <- info$digest
predictions$ollama_version <- info$version
predictions$prompt_file    <- prompt_path
predictions$prompt_md5     <- prompt_md5
predictions$temperature    <- model_options$temperature
predictions$seed           <- model_options$seed

write_csv(predictions, out_path, na = "")

cat("\nFinished in", round(as.numeric(difftime(Sys.time(), start, units = "mins")), 1), "minutes\n")
cat("Failed calls:", sum(!is.na(predictions$error)), "\n")
cat("Wrote:", out_path, "\n")
