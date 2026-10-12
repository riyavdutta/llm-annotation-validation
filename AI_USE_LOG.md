# AI Use Log

This log records every session in which an AI assistant worked on this
repository: what it was asked to do, what it did, and what the human author
checked. Sampling, codebook writing and human labelling are done by the
author, not the AI.

---

## Session 1 — 2026-10-12

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Step 1 only: project setup and read-only data inspection.

### Raw data file

| Field    | Value |
|----------|-------|
| File     | `Womens Clothing E-Commerce Reviews.csv` |
| Location | `data/raw/` (moved from the repository root; it was not a zip) |
| Size     | 8,483,448 bytes |
| SHA-256  | `bd93cc515747ad1f87b8bc863c9e40da758509e6db6506a96d06976e61e36ee0` |
| Source   | Downloaded by the author. The AI downloaded nothing. |

### What the AI did

- Created folders `data/raw`, `data/processed`, `prompts`, `scripts`, `outputs`.
- Moved the CSV from the repository root into `data/raw/`.
- `.gitignore`: `.env` (line 51) and `data/raw/` (line 52) were already
  present. Added the missing final newline. No other line changed.
- Confirmed with `git check-ignore -v` that the CSV is ignored by
  `.gitignore:52:data/raw/`.
- Wrote `scripts/00_inspect_data.R` (readr + base R) and ran it.
  It is read-only and writes no files.

### Inspection results (`scripts/00_inspect_data.R`)

- Rows: 23,486 (matches expected).
- 11 columns. The first column has no header (a row index from 0); readr
  names it `...1`.
- Missing `Review Text`: 845. Missing `Title`: 3,810.
- Review length in words (n = 22,641 non-missing): min 2, median 59, max 115.
- Ratings: 1 = 842, 2 = 1,565, 3 = 2,871, 4 = 5,077, 5 = 13,131.

### Not done (author's steps)

No sampling, no API calls, no codebook, no labels, no git commit or push.

### Notes

- The author asked the AI to follow `CLAUDE.md`, but no `CLAUDE.md` exists
  in the repository at this point.

---

## Session 2 — 2026-10-12

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Create the pilot labelling sheet only.

### What the AI did

- `.gitignore`: added `data/private/` as a new last line (line 53). Trailing
  newline kept. No other line changed. Created `data/private/`.
  `git check-ignore -v` confirms `data/private/pilot_sheet.csv` is ignored by
  `.gitignore:53:data/private/`.
- Checked, without printing any text, that no `Title` or `Review Text` value is
  the literal string "NA" (which readr would read as missing), and that the
  file's unnamed first column equals row number − 1 for every row.
- Wrote and ran `scripts/01_make_pilot_sheet.R` (readr + base R), as the author
  instructed. Settings chosen by the author: 30 reviews, `set.seed(2026)`,
  title and review text joined, rows with both missing dropped.

### Choices made by the AI (author to review)

- `review_id` = 1-based row number in the raw CSV (= unnamed first column + 1).
- Title and review text are joined with a line break, so no punctuation is
  added. If only one is present, that one is used alone.
- "Missing" = NA or blank after trimming spaces, as in `00_inspect_data.R`.
- Sample order is kept as drawn (random), not sorted by `review_id`.
- The script stops if `data/private/pilot_sheet.csv` already exists, so a
  re-run cannot overwrite labels entered by hand.

### Results

- Rows in raw file: 23,486. Dropped (title and text both missing): 844.
- Reviews available: 22,642 (19,675 title + text; 2,966 text only; 1 title only).
- Sampled: 30, all unique `review_id`s, no empty text fields.
- `data/private/pilot_sheet.csv` (git-ignored): columns `review_id`, `text`,
  `expertise_claim`, `hedging`, `social_proof`, `notes`; the last four empty.
- `data/processed/pilot_ids.csv`: `review_id` only, 30 rows, same order as the
  sheet. This file is **not** git-ignored.

### Not done

The AI did not print or read any review text, label anything, define cues,
draft a codebook, call any API, or commit or push.

### Notes

- `CLAUDE.md` still does not exist in the repository.

---

## Session 3 — 2026-10-12

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Help with labelling; then change the design; then install a free local LLM.

### Discussion and decisions

- The author shared a screenshot of the first two pilot-sheet rows. The AI
  explained how to approach labelling but did not label them.
- At the author's request, the AI drafted initial (v0) definitions for
  `expertise_claim`, `hedging` and `social_proof` in chat. Not yet saved to
  the repository.
- The author decided not to hand-label reviews. New proposed design, with no
  manual coding:
  - **Part A:** validate the LLM against labels the reviewers gave themselves
    (`Recommended IND`, `Rating`).
  - **Part B:** LLM codes the three trust cues; check reliability across
    repeated runs and whether the cues predict `Positive Feedback Count`.
  - The pilot sheet (`data/private/pilot_sheet.csv`) is no longer used.
- The author ruled out paid APIs. Decision: run an open model locally.

### Local LLM installation (author approved the download)

| Item | Value |
|------|-------|
| Ollama version | v0.34.4 (CLI build `ollama-darwin.tgz`, 160 MB), from `github.com/ollama/ollama/releases` |
| Why this version | Latest release ≥ 2 weeks old at the end of its patch line; newer v0.40.x was 0–16 days old |
| Download SHA-256 | `e9c8fddaab5f48f47f2c4ae3d23d0732f5182417125353faeed2188e34a22799` (matches the official `sha256sum.txt`) |
| Signature | Valid Apple Developer ID: Infra Technologies, Inc (3MU9H2V9Y9) |
| Installed to | `~/.local/ollama/` (user folder, outside the repository, no admin rights) |
| Server | `127.0.0.1:11434` (this machine only) |
| Model | `llama3.2:3b`, Ollama ID `a80c4f17acd5`, 2.0 GB, stored in `~/.ollama/models/` |
| Hardware | Apple M2, 8 GB RAM |

- Smoke test with two invented sentences (no review data), `temperature = 0`,
  `seed = 42`: both answers correct; ~17 s for the first call (model load),
  ~0.2 s once loaded.

### Not done

No review text was sent to the model. No sampling for the new design, no
prompts, no labels, no code in the repository changed. No commit or push.

---

## Session 4 — 2026-10-13

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Draw the main sample and test the local LLM on 5 reviews.

### What the AI did

- Wrote and ran `scripts/02_draw_sample.R`: simple random sample of 500 reviews
  with `set.seed(2026)`, from the 22,612 reviews that have a title or text and
  are not among the 30 pilot reviews. Same `review_id` and title + text join
  as `01_make_pilot_sheet.R`.
  - `data/private/main_sample.csv` (git-ignored): `review_id`, `text`,
    `rating`, `recommended`, `positive_feedback`, `word_count`.
  - `data/processed/main_ids.csv`: `review_id` only.
- Wrote `prompts/part_a_v0.txt`: asks the model, from the review text only,
  whether the reviewer recommends the item and which rating (1–5) they gave.
- Wrote and ran `scripts/03_test_llm.R` (readr + httr2): sends the first 5
  sampled reviews to `llama3.2:3b` via the local Ollama server. Only the text
  is sent. The reply is constrained to JSON. `temperature = 0`, `seed = 42`.
  Prints predictions and timing only, writes no files.

### Results

- Sample: 500 unique reviews, 0 overlap with the pilot. Ratings 1–5 (%):
  2.0 / 6.4 / 12.0 / 21.6 / 58.0 (full file: 3.6 / 6.7 / 12.2 / 21.6 / 55.9).
  Recommended: 83.0% (full file: 82.2%). Positive feedback = 0: 46.2%.
  Words: min 5, median 62, max 112.
- Test (5 reviews): recommendation correct 3/5, rating exact 4/5, rating
  within one star 5/5. About 0.9 s per review after the model loaded
  (est. ~7 minutes for 500). Far too few to judge accuracy; this only shows
  the pipeline works.
- A second identical run gave identical predictions (deterministic setup).

### Notes for the design

- Only 10 one-star reviews in the sample; rating accuracy for 1 star will be
  imprecise.
- Because identical settings give identical output, repeating a run cannot
  measure reliability. Part B reliability needs variation, e.g. reworded
  prompts or different seeds.

### Not done

No full run, no trust-cue prompt, no commit or push.
