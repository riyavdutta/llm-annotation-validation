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
