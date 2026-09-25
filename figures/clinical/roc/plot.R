# ROC curves. Multi-marker overlay, optional landmark status, AUC in the legend.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

markers_keep <- c("AFP", "DCP", "ALT")
show_auc <- TRUE
time_dependent <- FALSE
landmark_time <- 18

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$marker %in% markers_keep, , drop = FALSE]
if (isTRUE(time_dependent)) {
  event <- df$label == 1 & df$time <= landmark_time
  control <- df$time > landmark_time
  df <- df[event | control, , drop = FALSE]
  df$label <- as.integer(event[event | control])
}

curves <- lapply(split(df, df$marker), function(sub) {
  roc <- pROC::roc(sub$label, sub$score, quiet = TRUE, direction = "<")
  auc <- as.numeric(pROC::auc(roc))
  data.frame(
    fpr = 1 - roc$specificities,
    tpr = roc$sensitivities,
    marker = unique(sub$marker),
    auc = auc
  )
})
plot_df <- do.call(rbind, curves)
plot_df$marker <- factor(plot_df$marker, levels = markers_keep)
lab <- if (isTRUE(show_auc)) {
  auc_map <- tapply(plot_df$auc, plot_df$marker, function(z) unique(z)[1])
  sprintf("%s (AUC %.2f)", markers_keep, auc_map[markers_keep])
} else {
  markers_keep
}
names(lab) <- markers_keep
plot_df$legend <- factor(lab[as.character(plot_df$marker)], levels = lab)
plot_df <- plot_df[order(plot_df$legend, plot_df$fpr, plot_df$tpr), ]
pal <- pv_palette("categorical", length(markers_keep))
names(pal) <- lab

p <- ggplot2::ggplot(plot_df, ggplot2::aes(fpr, tpr, colour = legend)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linewidth = 0.3, colour = "grey60", linetype = "dashed") +
  ggplot2::geom_line(linewidth = 0.6) +
  ggplot2::scale_colour_manual(values = pal, name = NULL) +
  ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  ggplot2::labs(
    x = "False positive rate",
    y = "True positive rate",
    title = if (isTRUE(time_dependent)) sprintf("Status at %s months", landmark_time) else NULL
  ) +
  theme_viz()

pv_save(p, "figure", width_mm = 120, height_mm = 110)
message("wrote preview.png")
