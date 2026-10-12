# 03_test_llm.R
# Test run: sends the first 5 reviews of the main sample to the local Ollama
# model with the Part A prompt and reports predictions, true values and timing.
# Only the review text is sent; rating and recommendation are never shown to
# the model. Prints no review text and writes no files.
# Requires the Ollama server: ~/.local/ollama/ollama serve
# Run from the repository root: Rscript scripts/03_test_llm.R

library(readr)
library(httr2)

ollama_url  <- "http://127.0.0.1:11434"
model       <- "llama3.2:3b"
prompt_path <- file.path("prompts", "part_a_v0.txt")
sample_path <- file.path("data", "private", "main_sample.csv")
n_test      <- 5

# Fixed settings so repeated runs give the same answers.
model_options <- list(temperature = 0, seed = 42)

# Ollama constrains the reply to this JSON structure.
answer_schema <- list(
  type       = "object",
  properties = list(
    recommend = list(type = "boolean"),
    rating    = list(type = "integer", enum = 1:5)
  ),
  required   = list("recommend", "rating")
)

template <- paste(readLines(prompt_path, warn = FALSE), collapse = "\n")
template_parts <- strsplit(template, "{text}", fixed = TRUE)[[1]]
stopifnot(length(template_parts) == 2)

build_prompt <- function(text) paste0(template_parts[1], text, template_parts[2])

ask_model <- function(text) {
  resp <- request(ollama_url) |>
    req_url_path("/api/generate") |>
    req_body_json(list(
      model   = model,
      prompt  = build_prompt(text),
      format  = answer_schema,
      stream  = FALSE,
      options = model_options
    )) |>
    req_timeout(300) |>
    req_perform() |>
    resp_body_json()

  answer <- jsonlite::fromJSON(resp$response)
  data.frame(
    pred_recommend = as.integer(isTRUE(answer$recommend)),
    pred_rating    = as.integer(answer$rating),
    seconds        = round(resp$total_duration / 1e9, 2)
  )
}

# Check the server and record the exact model version.
version <- request(ollama_url) |> req_url_path("/api/version") |>
  req_perform() |> resp_body_json()
models <- request(ollama_url) |> req_url_path("/api/tags") |>
  req_perform() |> resp_body_json()
digest <- Filter(function(m) m$name == model, models$models)[[1]]$digest

cat("Ollama", version$version, "| model", model, "| digest", substr(digest, 1, 12), "\n")
cat("Options: temperature =", model_options$temperature, ", seed =", model_options$seed, "\n\n")

main_sample <- read_csv(sample_path, show_col_types = FALSE)
test_rows <- head(main_sample, n_test)

results <- do.call(rbind, lapply(test_rows$text, ask_model))
results <- cbind(
  review_id        = test_rows$review_id,
  true_recommend   = test_rows$recommended,
  results[c("pred_recommend")],
  true_rating      = test_rows$rating,
  results[c("pred_rating", "seconds")]
)

print(results, row.names = FALSE)

cat("\nRecommend correct:", sum(results$true_recommend == results$pred_recommend), "of", n_test, "\n")
cat("Rating exact:     ", sum(results$true_rating == results$pred_rating), "of", n_test, "\n")
cat("Rating within 1:  ", sum(abs(results$true_rating - results$pred_rating) <= 1), "of", n_test, "\n")
cat("Seconds per review (excluding the first, which loads the model):",
    round(mean(results$seconds[-1]), 2), "\n")
cat("Estimated time for 500 reviews:",
    round(500 * mean(results$seconds[-1]) / 60, 1), "minutes\n")
