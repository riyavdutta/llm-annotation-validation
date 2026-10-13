# AI Use Log

This log records the sessions in which an AI assistant changed this
repository: what it was asked to do, what it did, and what the author decided
or checked. Sessions that left no change in the repository are not recorded.

Division of work: the author set the scope of each step, made the design
decisions and made every git commit. The AI wrote and ran the code (including
the sampling scripts, on the author's instructions), drafted the codebook
definitions, ran the models and drafted the README. No review was labelled by
a human. Past session entries are kept as written; later corrections are
recorded in the session that made them.

---

## Session 1: 2026-10-12

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

## Session 2: 2026-10-12

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

## Session 3: 2026-10-12

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

## Session 4: 2026-10-13

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

---

## Session 5: 2026-10-13

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Next step at the AI's suggestion. The AI proposed the
full Part A run before Part B, with the v0 prompt used unchanged.

### What the AI did

- Wrote `scripts/ollama_helpers.R`: shared functions to load a prompt, record
  the Ollama version and model digest, and call the model.
- Wrote and ran `scripts/04_run_part_a.R`: all 500 sampled reviews, text only,
  `llama3.2:3b` (digest `a80c4f17acd5`), Ollama 0.34.4, `prompts/part_a_v0.txt`
  (md5 `c2ecd5d097f1a429efa6978f1b68cda0`), `temperature = 0`, `seed = 42`.
  7.2 minutes, 0 failed calls. Output: `outputs/part_a_predictions.csv`
  (predictions and run settings only, no review text).
- Wrote and ran `scripts/05_evaluate_part_a.R`. Primary metrics were fixed in
  the script before results were seen: Cohen's kappa (recommendation) and
  quadratic-weighted kappa (rating). 95% CIs: percentile bootstrap, 2,000
  resamples, `set.seed(2026)`. Kappa computed in base R (no new packages).
- Checked: the 5 reviews from the session 4 test got identical predictions.

### Results (n = 500)

| Metric | Estimate | 95% CI |
|--------|----------|--------|
| Recommendation, Cohen's kappa | 0.458 | 0.387–0.530 |
| Recommendation, accuracy | 0.764 | 0.726–0.800 |
| (Majority baseline: always "recommend") | 0.830 | n/a |
| Recall, "not recommended" | 0.988 | 0.961–1.000 |
| Precision, "not recommended" | 0.418 | 0.352–0.485 |
| Rating, quadratic-weighted kappa | 0.752 | 0.708–0.790 |
| Rating, exact | 0.560 | 0.516–0.602 |
| Rating, within one star | 0.938 | 0.916–0.958 |
| Rating, mean absolute error | 0.510 | 0.456–0.566 |
| Rating, Spearman's rho | 0.790 | 0.749–0.827 |

- The model is systematically too negative. It labelled 117 of 415
  recommending reviewers as "not recommending" and under-predicts ratings at
  every level (mean prediction for true 4 = 3.50, true 3 = 2.37).
- It orders reviews well (rho 0.79, QWK 0.75) but is miscalibrated.
  Recommendation accuracy is below the majority baseline.

### Not done

The prompt was not changed after seeing results. No Part B work, no commit
or push.

---

## Session 6: 2026-10-13

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Add a second local model, prepare Part B, run Part A
on the second model. Full Part B run deferred until the author approves the
codebook.

### Second model (author approved the download)

- `gemma3:4b`, Ollama ID `68ceab7e468a`, 3.4 GB (incl. an 851 MB vision
  component that is not used), from the official Ollama library; digest
  verified by Ollama. The first download stalled at 6% and was restarted;
  Ollama resumed it.

### What the AI did

- Wrote `codebook/codebook_v0.md`: the v0 cue definitions drafted in session 3,
  with sources. Three open decisions set to the AI's suggested defaults, to be
  confirmed by the author: D1 body measurements/fit are not expertise; D2
  "for me"/"on my body" are not hedging unless they clearly soften a claim;
  D3 compliments from people the reviewer knows count as social proof.
- Wrote `prompts/part_b_v0.txt` from the codebook (true/false per cue).
- `scripts/04_run_part_a.R` now takes the model as an argument and writes
  `outputs/part_a_predictions_<model>.csv`. The existing llama file was
  renamed accordingly (content unchanged). Added `model_slug()` to
  `scripts/ollama_helpers.R`.
- `scripts/05_evaluate_part_a.R` now evaluates every model and writes one
  combined `outputs/part_a_metrics.csv` plus per-model confusion matrices.
  Re-scoring llama gave identical numbers to session 5.
- Wrote `scripts/06_run_part_b.R` (with `--test` mode), and, before any Part B
  results existed, `scripts/07_evaluate_part_b.R` (cue prevalence; agreement
  between the two models: kappa primary, plus percent agreement and Gwet's
  AC1) and `scripts/08_predict_helpfulness.R` (negative binomial regression of
  `positive_feedback` on the cues, controlling for log word count and rating).
- Dry-ran scripts 07 and 08 on random fake codings in a scratch folder (not in
  the repository). This showed AC1 = 0.87 for random coding of a 5%-prevalence
  cue, so kappa was made the primary agreement measure.
- Ran Part A on `gemma3:4b` with the unchanged prompt: 500 reviews, 15.5 min,
  0 failed calls. The Mac used most of its swap during the run (8 GB RAM).
- Part B test, 5 reviews, both models: pipeline works; both models gave
  identical codings on these 5.

### Part A results, both models (n = 500, 95% bootstrap CI)

| Metric | llama3.2:3b | gemma3:4b |
|--------|-------------|-----------|
| Recommendation kappa (primary) | 0.458 (0.387–0.530) | 0.728 (0.649–0.802) |
| Recommendation accuracy (baseline 0.830) | 0.764 | 0.916 |
| Rating quadratic-weighted kappa (primary) | 0.752 (0.708–0.790) | 0.669 (0.622–0.713) |
| Rating exact | 0.560 | 0.422 |
| Rating within one star | 0.938 | 0.926 |
| Spearman's rho | 0.790 | 0.766 |

- Neither model is better on both tasks. Gemma is much better at
  recommendation (above the majority baseline); llama is better at ratings.
- Both under-predict ratings. Gemma rated 163 of 290 five-star reviews as 4.
- Model comparison is descriptive: the CIs are per model, not a paired test
  of the difference, which was not pre-specified.

### Not done

No full Part B run (awaiting codebook approval). No prompt changed after
seeing results. No commit or push.
- The codebook was first saved as `docs/codebook_v0.md`, but `.gitignore`
  line 43 (`docs/`, from the R template) ignores that folder. Moved to
  `codebook/codebook_v0.md`; `.gitignore` unchanged.

---

## Session 7: 2026-10-13

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** "Let us proceed to the next part." Given in reply to
the request to approve codebook decisions D1–D3; the AI treated it as
approval of v0 as written.

### What the AI did

- Froze the codebook as `codebook/codebook_v1.md`: definitions identical to
  v0 (checked with `diff`), status and provenance updated. v0 kept.
- Ran `scripts/06_run_part_b.R` on all 500 reviews with both models,
  `prompts/part_b_v0.txt` (md5 `716c49f57ce6dd0a3336ce887ef077f9`),
  `temperature = 0`, `seed = 42`.
  - `llama3.2:3b`: 9.7 min, 0 failed calls.
  - `gemma3:4b`: 63.5 min, 3 failed calls (timeouts with no reply; the Mac was
    short of memory). Successful calls: median 3.9 s, max 10.5 s.
- Added a `--retry-failed` option to `06_run_part_b.R` (same prompt, model
  digest and settings, checked by the script) and re-ran the 3 failed reviews:
  all succeeded within seconds. The other 497 rows were verified unchanged
  against a backup copy.
- **Deviation from plan:** `llama3.2:3b` coded `expertise_claim` as absent in
  all 500 reviews, so it cannot enter a regression. `scripts/08_predict_helpfulness.R`
  now leaves out a cue with no variation for that model and reports it
  (column `dropped_cues`). Tested on fake data before use.
- Ran `scripts/07_evaluate_part_b.R` and `scripts/08_predict_helpfulness.R`.

### Results: cue prevalence and agreement between models (n = 500)

| Cue | gemma3:4b | llama3.2:3b | Both | Kappa (95% CI) | AC1 |
|-----|-----------|-------------|------|----------------|-----|
| expertise_claim | 1.2% (6) | 0.0% (0) | 0 | 0.00 | 0.99 |
| hedging | 26.6% | 12.6% | 41 | 0.30 (0.20–0.39) | 0.67 |
| social_proof | 10.2% | 1.4% (7) | 7 | 0.22 (0.08–0.36) | 0.90 |

- Agreement between the models is poor to fair on every cue. Gemma codes
  hedging twice as often and social proof seven times as often as llama; all
  7 of llama's social-proof reviews were also coded by gemma.
- AC1 is high only because the cues are rare (as the dry run predicted), so
  kappa is the measure reported.

### Results: do cues predict helpful votes? (negative binomial, IRR, 95% CI)

| Term | gemma3:4b | llama3.2:3b |
|------|-----------|-------------|
| expertise_claim | 1.46 (0.36–5.83), 6 cases | not estimable (0 cases) |
| hedging | 0.84 (0.58–1.22) | 0.86 (0.52–1.41) |
| social_proof | 0.55 (0.33–0.94), p = 0.03 | 0.29 (0.07–1.30), p = 0.11 |
| log(word_count) | 1.54 (1.15–2.08) | 1.50 (1.13–1.99) |

- Only review length predicts helpful votes consistently.
- Social proof is linked to fewer votes with gemma's coding (p = 0.03) but not
  significantly with llama's. With 6 cue tests, p = 0.03 does not survive a
  Bonferroni correction (0.05 / 6 = 0.008).
- Without human labels it cannot be said which model's coding is correct.

### Not done

No prompt or codebook changed after seeing results. No commit or push.

---

## Session 8: 2026-10-13

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Draft the README and figures.

### What the AI did

- Wrote and ran `scripts/09_make_figures.R` (base R graphics): three PNGs in
  `outputs/figures/` (Part A agreement with CIs; Part A mean predicted vs.
  true rating; Part B cue prevalence per model with kappa) and
  `outputs/part_a_calibration.csv` (averages per rating level only). Model
  colours from a colourblind-checked reference palette; each model also has
  its own marker shape and direct label. The palette validator could not be
  run (Node.js not installed). All figures were rendered and inspected.
- Wrote `README.md`: question, key findings, data, design, results tables,
  limitations, how to reproduce, AI assistance statement, licences. All
  numbers were taken from the files in `outputs/` and re-checked; the 3-star
  recommendation figure (22 of 60) and zero-vote share (46.2%) were verified
  against the sample.

### Correction to earlier entries

- Sessions 5 and 6 stated that the models under-predict ratings "at every
  level". That is wrong. Figure 2 shows that for 1-star reviews both models
  predict higher than the reviewer (llama 1.60, gemma 1.80), and gemma is
  exact on average for 2-star reviews (2.00). Predictions are compressed
  towards the middle: too low for 3–5 stars (79.6% of the sample is 4–5
  stars), too high for 1 star (n = 10). The README uses the corrected
  description.

### Not done

No new model runs, no analysis changes. No commit or push.

---

## Session 9: 2026-10-13

**Tool:** Claude Code (desktop app), model Claude Opus 5.5 (`claude-opus-5-5`)
**Task given by author:** Read-only checks of the README; README corrections
in the author's wording; a full audit of the project; then fix what the audit
found. Nothing under `prompts/` or `codebook/` was changed.

### README corrections in the author's wording (committed in 843c2f8, 3c032e5)

- Key finding 2: "squeeze ratings towards the middle" replaced with mean
  signed errors (−0.43 llama3.2:3b, −0.61 gemma3:4b). The old text gave 80%
  as the share of 3–5-star reviews; the correct figure is 91.6% (80% is the
  share of 4–5-star reviews).
- Key finding 3 and results text: the old wording said the social-proof
  finding "depends on which model did the coding". The two IRRs (0.55 and
  0.29) point the same way and their CIs overlap; only one reaches p < 0.05.
  Reworded accordingly.
- Figure 2 retitled "Part A: both models under-rate most reviews"; regenerated
  with `09_make_figures.R`, figures 1 and 3 byte-identical.
- Codebook sentence: "Frozen before the Part B run" replaced with a statement
  git history supports (definitions identical to `codebook_v0.md`, committed in
  5f6f1b3 before the Part B outputs in b344c2d).
- Em dashes in this log's session headings replaced with colons.
- Session 8 said all README numbers were "re-checked". That check missed the
  80% error, the overstated social-proof sentence and the rounding errors
  below.

### Audit (no files changed during the audit)

- Raw file SHA-256 matches session 1. Scripts 00, 01 and 02 re-run in a
  scratch folder: same counts; `pilot_ids.csv`, `main_ids.csv`,
  `main_sample.csv` and `pilot_sheet.csv` byte-identical.
- Scripts 05, 07, 08 and 09 re-run in the repository: every committed output
  and figure byte-identical.
- Determinism: 5 reviews (`set.seed(7)` from the sample: ids 13057, 12402,
  7906, 21042, 9377) re-sent to both models with both prompts and the stored
  settings. 20 of 20 answers identical to the stored predictions.
- Prompt hashes inside all four predictions files match the committed prompts.
  Each prompt and codebook file was added once and never modified.
- No file under `data/private/` or `data/raw/` has ever been committed. The
  longest stored model reply is 75 characters (JSON only, no review text).
- Every README statistic recomputed without intermediate rounding. Four values
  had been rounded twice (3 decimals in `outputs/`, then 2 in the README).
- Kaggle page checked: `Positive Feedback Count` is described as "the number
  of other customers who found this review positive"; licence CC0: Public
  Domain.
- Commit 519d629 ("…stop tracking .DS_Store") changed only this log; the
  `.DS_Store` files remained tracked.

### Fixes made after the audit

- Opening of this log rewritten: it previously said sampling, codebook writing
  and human labelling were done by the author. The AI wrote and ran the
  sampling scripts and drafted the codebook, and no human labelling exists.
- README rounding corrections:

  | Value | Was | Now |
  |-------|-----|-----|
  | gemma3:4b precision, "not recommended" | 0.71 | 0.70 (0.7048) |
  | gemma3:4b expertise IRR | 1.46 | 1.45 (1.4549) |
  | gemma3:4b social-proof IRR, CI lower bound | 0.33 | 0.32 |
  | llama3.2:3b log word count IRR, CI lower bound | 1.13 | 1.12 |

  The last three values also appear in the session 7 table above, which is
  kept as written.
- README pre-specification text: no longer says the models were fixed before
  results existed; states that gemma3:4b was added after llama3.2:3b's Part A
  results, and lists the 3 re-run Part B calls as a deviation.
- README defines "helpfulness votes" as an interpretation of Kaggle's
  `Positive Feedback Count`; determinism claim now cites the 20-of-20 check;
  Reproduce section starts the server before pulling models and asks readers
  to compare model IDs; dataset licence (CC0) stated.
- `.gitignore`: added `.DS_Store`. Removing the two tracked `.DS_Store` files
  from git is left to the author (`git rm --cached`).

### Not done

No model output, analysis script, prompt or codebook changed. No commit or
push.
