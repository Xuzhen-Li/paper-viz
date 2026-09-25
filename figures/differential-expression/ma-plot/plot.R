# MA plot. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
lfc_cut <- 1
p_cut <- 0.01
show_labels <- TRUE
n_label <- 8
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$A <- log2(df$base_mean)
df$direction <- ifelse(
  df$pvalue >= p_cut | abs(df$log2fc) < lfc_cut, "ns",
  ifelse(df$log2fc > 0, "up", "down")
)
cols <- c(ns = "#6B6B6B", up = pv_palette("categorical", 4)[4], down = pv_palette("categorical", 1)[1])

p <- ggplot2::ggplot(df, ggplot2::aes(A, log2fc, colour = direction)) +
  ggplot2::geom_point(size = 0.55, alpha = 0.65) +
  ggplot2::scale_colour_manual(values = cols, guide = "none") +
  ggplot2::geom_hline(yintercept = c(-lfc_cut, 0, lfc_cut), linetype = c("dashed", "solid", "dashed"), linewidth = 0.3, colour = c("black", "grey60", "black")) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.06, 0.14))) +
  ggplot2::labs(x = "log2 mean expression", y = "log2 fold change") +
  theme_viz()

if (isTRUE(show_labels) && n_label > 0) {
  lab <- df[df$direction != "ns", , drop = FALSE]
  lab <- lab[order(lab$pvalue, -abs(lab$log2fc)), , drop = FALSE]
  lab <- utils::head(lab, n_label)
  p <- p + ggrepel::geom_text_repel(
    data = lab,
    ggplot2::aes(label = gene),
    size = 2,
    colour = "black",
    segment.size = 0.2,
    max.overlaps = 20,
    show.legend = FALSE,
    seed = 1
  )
}

pv_save(p, "figure", width_mm = 89, height_mm = 74)
message("wrote preview.png")
