# UpSet bars and dot matrix. Choose how many sets and how to sort.
# Run from this directory.
source("../../../styles/r/theme_viz.R")
library(patchwork)

n_sets <- 5
sort_by <- "degree"
max_intersections <- 16
set_levels <- c("ATAC", "H3K27ac", "H3K4me3", "CTCF", "RNA")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
use <- set_levels[seq_len(min(n_sets, length(set_levels)))]
df <- df[df$set %in% use, , drop = FALSE]
df$set <- factor(df$set, levels = use)
wide <- reshape(df, idvar = "element", timevar = "set", direction = "wide")
colnames(wide) <- sub("^present\\.", "", colnames(wide))
wide <- wide[rowSums(wide[, use, drop = FALSE]) > 0, , drop = FALSE]
bits <- as.matrix(wide[, use, drop = FALSE])
code <- apply(bits, 1, paste0, collapse = "")
tab <- aggregate(wide$element, by = list(code = code), FUN = length)
colnames(tab)[2] <- "n"
tab$degree <- nchar(gsub("0", "", tab$code))
if (sort_by == "degree") {
  tab <- tab[order(tab$degree, tab$n, decreasing = TRUE), ]
} else {
  tab <- tab[order(tab$n, decreasing = TRUE), ]
}
tab <- head(tab, max_intersections)
tab$code <- factor(tab$code, levels = rev(tab$code))

set_n <- sapply(use, function(s) sum(wide[[s]]))
set_df <- data.frame(set = factor(use, levels = rev(use)), n = set_n[use])
set_lab <- setNames(sprintf("%s (%d)", use, set_n[use]), use)

dot <- do.call(rbind, lapply(seq_len(nrow(tab)), function(i) {
  on <- strsplit(as.character(tab$code[i]), "")[[1]] == "1"
  data.frame(code = tab$code[i], set = factor(use, levels = rev(use)), on = on)
}))
on_pts <- dot[dot$on, , drop = FALSE]

p_bar <- ggplot2::ggplot(tab, ggplot2::aes(code, n)) +
  ggplot2::geom_col(fill = "#333333", width = 0.72) +
  ggplot2::labs(x = NULL, y = "Intersection") +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    plot.margin = ggplot2::margin(2, 6, 0, 2)
  )

p_dot <- ggplot2::ggplot(dot, ggplot2::aes(code, set)) +
  ggplot2::geom_line(
    data = on_pts,
    ggplot2::aes(code, set, group = code),
    linewidth = 0.45, colour = "#222222"
  ) +
  ggplot2::geom_point(ggplot2::aes(colour = on, size = on), shape = 16) +
  ggplot2::scale_colour_manual(values = c(`TRUE` = "#222222", `FALSE` = "grey80"), guide = "none") +
  ggplot2::scale_size_manual(values = c(`TRUE` = 2.2, `FALSE` = 1.3), guide = "none") +
  ggplot2::scale_y_discrete(labels = set_lab[rev(use)]) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_text(size = 6),
    plot.margin = ggplot2::margin(0, 6, 2, 2)
  )

p <- p_bar / p_dot + patchwork::plot_layout(heights = c(0.7, 1))

pv_save(p, "figure", width_mm = 160, height_mm = 100)
message("wrote preview.png")
