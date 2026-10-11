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
