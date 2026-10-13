# Correlation matrix (house style): circle or square cells on the blue-red diverging scale,
# stars for P < sig_cut, colour bar inside the empty lower triangle. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

cell_shape <- "circle"
show_significance <- TRUE
upper_only <- TRUE
sig_cut <- 0.05

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
vars <- unique(c(df$var_a, df$var_b))
r_mat <- matrix(0, length(vars), length(vars), dimnames = list(vars, vars))
diag(r_mat) <- 1
r_mat[cbind(df$var_a, df$var_b)] <- df$r
r_mat[cbind(df$var_b, df$var_a)] <- df$r
ord <- vars[stats::hclust(stats::as.dist(1 - r_mat))$order]
df$var_a <- factor(df$var_a, levels = ord)
df$var_b <- factor(df$var_b, levels = ord)
ia <- as.integer(df$var_a)
ib <- as.integer(df$var_b)
# each pair is stored once; put it on the x < y side so the upper triangle is complete
swap <- ia > ib
df[swap, c("var_a", "var_b")] <- df[swap, c("var_b", "var_a")]
ia <- as.integer(df$var_a)
ib <- as.integer(df$var_b)
if (!isTRUE(upper_only)) {
  mirror <- df; mirror[, c("var_a", "var_b")] <- df[, c("var_b", "var_a")]
  df <- rbind(df, mirror); ia <- as.integer(df$var_a); ib <- as.integer(df$var_b)
}
keep <- if (isTRUE(upper_only)) ia < ib else ia != ib
plot_df <- df[keep, , drop = FALSE]
plot_df$stars <- ifelse(plot_df$p < sig_cut, "*", "")
fills <- pv_palette("house_div")   # blue (negative) to red (positive), centred on 0
grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"
n_sig <- sum(df$p[keep] < sig_cut & as.integer(df$var_a)[keep] < as.integer(df$var_b)[keep])

p <- ggplot(plot_df, aes(var_a, var_b, fill = r))
if (cell_shape == "square") {
  p <- p + geom_tile(colour = "white", linewidth = pv_house_lw(0.3))
} else {
  p <- p + geom_point(aes(size = abs(r)), shape = 21, stroke = HOUSE_POINT$stroke, colour = grey[["dark"]])
  p <- p + scale_size_area(max_size = 5.2, limits = c(0, 1), guide = "none")
}
if (isTRUE(show_significance)) {
  p <- p + geom_text(aes(label = stars), vjust = 0.75, colour = "black")
}
k <- length(ord)
# annotation sits a fixed fraction (23.5%) of the panel height above the bottom edge, clear of the
# colour bar, so it stays in the empty lower triangle for any k (k = 15 gives about 4)
note_y <- 0.5 + 0.235 * k
if (isTRUE(upper_only)) {
  p <- p + annotate("text", x = k, y = note_y, hjust = 1, vjust = 0, lineheight = 0.95,
                    label = sprintf("* P < %.2f\n%d of %d pairs", sig_cut, n_sig, nrow(plot_df)))
}
p <- p +
  scale_fill_gradientn(colours = fills, limits = c(-1, 1), breaks = c(-1, 0, 1), name = "r",
                       guide = guide_colourbar(direction = "horizontal", title.position = "top",
                                               barwidth = unit(16, "mm"), barheight = unit(2, "mm"))) +
  scale_x_discrete(drop = FALSE) +
  scale_y_discrete(drop = FALSE) +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house(legend = "inside") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
        legend.position.inside = c(0.98, 0.02), legend.justification.inside = c(1, 0),
        legend.title = element_text(face = "italic"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
