# Volcano. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

lfc_cut <- 1
p_cut <- 0.01

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$nlp <- -log10(df$pvalue)
df$direction <- ifelse(
  df$pvalue >= p_cut | abs(df$log2_fold_change) < lfc_cut, "ns",
  ifelse(df$log2_fold_change > 0, "up", "down")
)
cols <- c(ns = pv_palette("categorical", 8)[8], up = pv_palette("categorical", 4)[4], down = pv_palette("categorical", 3)[3])
# black is index 8 and would hide points; use grey for ns
cols["ns"] <- "#6B6B6B"

p <- ggplot2::ggplot(df, ggplot2::aes(log2_fold_change, nlp, colour = direction)) +
  ggplot2::geom_point(size = 0.8, alpha = 0.7) +
  ggplot2::scale_colour_manual(values = cols, guide = "none") +
  ggplot2::geom_vline(xintercept = c(-lfc_cut, lfc_cut), linetype = "dashed", linewidth = 0.3) +
  ggplot2::geom_hline(yintercept = -log10(p_cut), linetype = "dashed", linewidth = 0.3) +
  ggplot2::labs(x = "log2 fold change", y = "-log10(p)") +
  theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 70)
message("wrote preview.png")
