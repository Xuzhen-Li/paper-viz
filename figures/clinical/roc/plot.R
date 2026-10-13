# ROC curves (house style): one curve per marker, marker names with AUC written in the panel in the
# curve colour (no legend), optional landmark status. pROC only computes; ggplot2 draws.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

markers_keep <- c("AFP", "DCP", "ALT")
show_auc <- TRUE
time_dependent <- FALSE
landmark_time <- 18

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green: all >= 3:1 on white, so the marker labels keep the curve colour
pal <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["magenta"]],
                         hp[["brown"]])[seq_along(markers_keep)], markers_keep)
footnote <- "Simulated data for illustration;\nnot biological results"

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
  data.frame(fpr = 1 - roc$specificities, tpr = roc$sensitivities,
             marker = unique(sub$marker), auc = as.numeric(pROC::auc(roc)))
})
plot_df <- do.call(rbind, curves)
plot_df$marker <- factor(plot_df$marker, levels = markers_keep)
plot_df <- plot_df[order(plot_df$marker, plot_df$fpr, plot_df$tpr), ]
key <- data.frame(marker = factor(markers_keep, levels = markers_keep), i = seq_along(markers_keep))
key$auc <- vapply(markers_keep, function(m) plot_df$auc[plot_df$marker == m][1], numeric(1))
key$lab <- if (isTRUE(show_auc)) sprintf("%s  AUC %.2f", key$marker, key$auc) else markers_keep
n_case <- sum(df$label == 1 & df$marker == markers_keep[1])
n_ctrl <- sum(df$label == 0 & df$marker == markers_keep[1])

p <- ggplot(plot_df, aes(fpr, tpr, colour = marker)) +
  geom_abline(slope = 1, intercept = 0, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_step(linewidth = pv_house_lw("main"), direction = "vh") +
  geom_text(data = key, aes(x = 0.98, y = 0.04 + 0.11 * (nrow(key) - i + 1), label = lab), hjust = 1,
            vjust = 0) +
  annotate("text", x = 0.98, y = 0.04, hjust = 1, vjust = 0,
           label = sprintf("%d cases, %d controls", n_case, n_ctrl)) +
  scale_colour_manual(values = pal, guide = "none") +
  scale_x_continuous(breaks = c(0, 0.5, 1), labels = c("0", "0.5", "1")) +
  scale_y_continuous(breaks = c(0, 0.5, 1), labels = c("0", "0.5", "1")) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = TRUE) +
  labs(x = "False positive rate", y = "True positive rate",
       title = if (isTRUE(time_dependent)) sprintf("Status at %s months", landmark_time) else NULL,
       caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
