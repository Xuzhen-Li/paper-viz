# Hexbin density of a bivariate scatter (house style): house_warm counts, colour bar inside,
# Pearson r and n in the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
bins <- 22
show_counts <- FALSE
legend_title <- "Count"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
seq_cols <- pv_palette("house_warm")
grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration;\nnot biological results"
r <- stats::cor(df$x, df$y)

p <- ggplot(df, aes(x, y)) +
  geom_hex(bins = bins, colour = "white", linewidth = pv_house_lw(0.2)) +
  scale_fill_gradientn(colours = seq_cols, name = legend_title,
                       breaks = function(l) c(ceiling(l[1] / 10), floor(l[2] / 10)) * 10,  # two end ticks
                       guide = guide_colourbar(direction = "horizontal", title.position = "top",
                                               barwidth = unit(8, "mm"), barheight = unit(1.8, "mm"))) +
  annotate("text", x = -Inf, y = Inf, hjust = -0.08, vjust = 1.3, lineheight = 0.95,
           label = sprintf("r = %.2f\nn = %s", r, format(nrow(df), big.mark = ","))) +
  scale_x_continuous(expand = expansion(mult = 0.02)) +
  scale_y_continuous(expand = expansion(mult = 0.02)) +
  labs(x = "Feature X", y = "Feature Y", caption = footnote) +
  theme_house(legend = "inside") +
  theme(legend.position.inside = c(0.985, 0.02), legend.justification.inside = c(1, 0),
        legend.title = element_text(size = 7, margin = margin(b = 0.6, unit = "mm")),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_counts)) {
  p <- p + stat_bin_hex(aes(label = after_stat(count)), bins = bins, geom = "text",
                        size = pv_pt2size(6), colour = "black")
}

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
