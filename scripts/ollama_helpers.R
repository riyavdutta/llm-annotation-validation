# ollama_helpers.R
# Shared functions for calling the local Ollama server. Sourced by other scripts.
# Requires the server: ~/.local/ollama/ollama serve

library(httr2)

ollama_url <- "http://127.0.0.1:11434"

# Reads a prompt template and returns a function that inserts a review's text
# at the {text} placeholder.
load_prompt <- function(path) {
  template <- paste(readLines(path, warn = FALSE), collapse = "\n")
  parts <- strsplit(template, "{text}", fixed = TRUE)[[1]]
  stopifnot(length(parts) == 2)
  function(text) paste0(parts[1], text, parts[2])
}

# Returns the Ollama version and the model's digest, for recording with results.
ollama_info <- function(model) {
  version <- request(ollama_url) |> req_url_path("/api/version") |>
    req_perform() |> resp_body_json()
  models <- request(ollama_url) |> req_url_path("/api/tags") |>
    req_perform() |> resp_body_json()
  match <- Filter(function(m) m$name == model, models$models)
  if (length(match) == 0) stop("Model ", model, " is not installed in Ollama.")
  list(version = version$version, digest = match[[1]]$digest)
}

# Sends one prompt and returns the parsed JSON answer plus timing.
ask_ollama <- function(prompt, model, schema, options) {
  resp <- request(ollama_url) |>
    req_url_path("/api/generate") |>
    req_body_json(list(
      model   = model,
      prompt  = prompt,
      format  = schema,
      stream  = FALSE,
      options = options
    )) |>
    req_timeout(300) |>
    req_perform() |>
    resp_body_json()

  list(
    answer  = jsonlite::fromJSON(resp$response),
    raw     = resp$response,
    seconds = resp$total_duration / 1e9
  )
}
