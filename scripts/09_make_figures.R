# 09_make_figures.R
# Makes the three figures used in the README from the saved outputs.
# Writes PNGs to outputs/figures/. Uses base R graphics only.
# Figure 2 needs the reviewers' ratings from data/private/main_sample.csv, but
# only averages per rating level are plotted. No review text is used.
# Run from the repository root: Rscript scripts/09_make_figures.R

library(readr)

fig_dir <- file.path("outputs", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Style -------------------------------------------------------------------------
# Model colours: categorical slots 1-2 of a reference palette documented as
# colourblind-safe (its validator was not run for this project). Each model also has its own marker shape and a direct label, so
# identity never depends on colour alone.
models     <- c("llama3.2:3b", "gemma3:4b")
model_col  <- c("llama3.2:3b" = "#2a78d6", "gemma3:4b" = "#eb6834")
model_pch  <- c("llama3.2:3b" = 16, "gemma3:4b" = 15)
ink        <- "#0b0b0b"
ink_soft   <- "#52514e"
ink_muted  <- "#898781"
grid_col   <- "#e1e0d9"
surface    <- "#fcfcfb"

open_png <- function(name, width = 1800, height = 1100) {
  png(file.path(fig_dir, name), width = width, height = height, res = 220, bg = surface)
  par(family = "sans", col.axis = ink_soft, col.lab = ink_soft, fg = ink_muted,
      las = 1, mgp = c(2.4, 0.6, 0), tcl = -0.25)
}

# Figure 1: Part A primary metrics --------------------------------------------
part_a <- read_csv(file.path("outputs", "part_a_metrics.csv"), show_col_types = FALSE)
metric_labels <- c(rec_kappa = "Recommendation\n(Cohen's kappa)",
                   rating_qw_kappa = "Star rating\n(weighted kappa)")

open_png("fig1_part_a_agreement.png")
par(mar = c(4.2, 9.5, 3.6, 7))
plot(NA, xlim = c(0, 1), ylim = c(0.5, 2.5), axes = FALSE, xlab = "", ylab = "")
abline(v = seq(0, 1, 0.2), col = grid_col, lwd = 1)
axis(1, at = seq(0, 1, 0.2), lwd = 0, lwd.ticks = 0)
axis(2, at = 2:1, labels = metric_labels, lwd = 0, cex.axis = 0.95, col.axis = ink)
title(xlab = "Agreement with the reviewer's own label (95% CI)")
offset <- c("llama3.2:3b" = 0.13, "gemma3:4b" = -0.13)
for (i in seq_along(metric_labels)) {
  y <- 3 - i
  for (m in models) {
    r <- part_a[part_a$model == m & part_a$metric == names(metric_labels)[i], ]
    segments(r$ci_low, y + offset[m], r$ci_high, y + offset[m], col = model_col[m], lwd = 2)
    points(r$estimate, y + offset[m], pch = model_pch[m], col = model_col[m], cex = 1.4)
    text(r$ci_high, y + offset[m], sprintf("  %.2f  %s", r$estimate, m),
         adj = 0, cex = 0.8, col = ink_soft, xpd = TRUE)
  }
}
mtext("Part A: how well each model recovers reviewers' own judgements",
      side = 3, line = 1.8, adj = 0, cex = 1.05, font = 2, col = ink)
mtext("n = 500 reviews; dots = estimate, lines = 95% bootstrap CI",
      side = 3, line = 0.6, adj = 0, cex = 0.8, col = ink_soft)
legend("bottomright", legend = models, pch = model_pch, col = model_col,
       lwd = 2, bty = "n", cex = 0.8, text.col = ink_soft, inset = c(0, -0.02))
dev.off()

# Figure 2: Part A calibration (mean predicted vs. true rating) ----------------
truth <- read_csv(file.path("data", "private", "main_sample.csv"),
                  show_col_types = FALSE)[c("review_id", "rating")]
calibration <- do.call(rbind, lapply(models, function(m) {
  p <- read_csv(file.path("outputs", paste0("part_a_predictions_", gsub("[^A-Za-z0-9.]+", "-", m), ".csv")),
                show_col_types = FALSE)
  d <- merge(truth, p[c("review_id", "pred_rating")], by = "review_id")
  data.frame(model = m, rating = 1:5,
             mean_pred = as.numeric(tapply(d$pred_rating, factor(d$rating, 1:5), mean)),
             n = as.integer(table(factor(d$rating, 1:5))))
}))
write_csv(calibration, file.path("outputs", "part_a_calibration.csv"))

open_png("fig2_part_a_calibration.png")
par(mar = c(4.6, 4.2, 3.6, 7))
plot(NA, xlim = c(1, 5), ylim = c(1, 5), axes = FALSE,
     xlab = "Reviewer's own star rating", ylab = "Model's average predicted rating")
abline(h = 1:5, v = 1:5, col = grid_col, lwd = 1)
abline(0, 1, col = ink_muted, lty = 2, lwd = 1.5)
text(4.15, 4.55, "perfect calibration", col = ink_muted, cex = 0.75, srt = 45)
n_labels <- paste0(1:5, "\n(n = ", calibration$n[calibration$model == models[1]], ")")
axis(1, at = 1:5, labels = n_labels, lwd = 0, padj = 0.5, cex.axis = 0.8)
axis(2, at = 1:5, lwd = 0)
for (m in models) {
  r <- calibration[calibration$model == m, ]
  lines(r$rating, r$mean_pred, col = model_col[m], lwd = 2)
  points(r$rating, r$mean_pred, pch = model_pch[m], col = model_col[m], cex = 1.3)
  text(5, r$mean_pred[5], paste0("  ", m), adj = 0, cex = 0.8, col = ink_soft, xpd = TRUE)
}
mtext("Part A: both models under-rate most reviews",
      side = 3, line = 1.8, adj = 0, cex = 1.05, font = 2, col = ink)
mtext("Below the dashed line = model predicts lower than the reviewer; 80% of reviews are 4-5 stars",
      side = 3, line = 0.6, adj = 0, cex = 0.8, col = ink_soft)
legend("topleft", legend = models, pch = model_pch, col = model_col,
       lwd = 2, bty = "n", cex = 0.8, text.col = ink_soft)
dev.off()

# Figure 3: Part B cue prevalence and agreement between models -----------------
part_b <- read_csv(file.path("outputs", "part_b_agreement.csv"), show_col_types = FALSE)
cues <- c("expertise_claim", "hedging", "social_proof")
cue_labels <- c(expertise_claim = "Expertise claim", hedging = "Hedging",
                social_proof = "Social proof")
prev <- part_b[part_b$metric == "kappa", ]
prev_of <- function(cue, m) {
  r <- prev[prev$cue == cue, ]
  100 * if (r$model_a == m) r$prevalence_a else r$prevalence_b
}

open_png("fig3_part_b_cues.png")
par(mar = c(4.2, 8.5, 3.6, 8.5))
plot(NA, xlim = c(0, 30), ylim = c(0.5, 3.5), axes = FALSE, xlab = "", ylab = "")
abline(v = seq(0, 30, 5), col = grid_col, lwd = 1)
axis(1, at = seq(0, 30, 5), labels = paste0(seq(0, 30, 5), "%"), lwd = 0)
axis(2, at = 3:1, labels = cue_labels[cues], lwd = 0, col.axis = ink)
title(xlab = "Share of the 500 reviews coded as containing the cue")
for (i in seq_along(cues)) {
  y <- 4 - i
  x <- sapply(models, function(m) prev_of(cues[i], m))
  segments(min(x), y, max(x), y, col = grid_col, lwd = 4)
  for (m in models) points(x[m], y, pch = model_pch[m], col = model_col[m], cex = 1.5)
  k <- prev[prev$cue == cues[i], ]
  text(30, y, sprintf("  kappa = %.2f", k$estimate), adj = 0, cex = 0.85,
       col = ink, xpd = TRUE)
}
mtext("Part B: the two models disagree on how often trust cues occur",
      side = 3, line = 1.8, adj = 0, cex = 1.05, font = 2, col = ink)
mtext("Same codebook and prompt; kappa = agreement between the two models",
      side = 3, line = 0.6, adj = 0, cex = 0.8, col = ink_soft)
legend("bottomright", legend = models, pch = model_pch, col = model_col,
       bty = "n", cex = 0.8, text.col = ink_soft)
dev.off()

cat("Wrote 3 figures to", fig_dir, "and outputs/part_a_calibration.csv\n")
