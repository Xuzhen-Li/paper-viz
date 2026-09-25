# Site frequency spectrum. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
use_folded <- TRUE
pops_show <- c("Wild N", "Landrace E", "Cultivar A")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$pop %in% pops_show & df$folded == as.integer(use_folded), ]
df$pop <- factor(df$pop, levels = pops_show)
df$prop <- ave(df$count, df$pop, FUN = function(x) x / sum(x))
pal <- pv_palette("categorical", length(pops_show))
names(pal) <- pops_show
x_lab <- if (isTRUE(use_folded)) "Minor allele count" else "Derived allele count"

p <- ggplot2::ggplot(df, ggplot2::aes(bin, prop, colour = pop, group = pop)) +
  ggplot2::geom_line(linewidth = 0.5) +
  ggplot2::geom_point(size = 1.15) +
  ggplot2::scale_colour_manual(values = pal, name = "Population") +
  ggplot2::scale_x_continuous(breaks = c(1, 5, 10, 15, 20)) +
  ggplot2::labs(x = x_lab, y = "Proportion of sites") +
  theme_viz() +
  ggplot2::theme(legend.key = ggplot2::element_blank())

pv_save(p, "figure", width_mm = 140, height_mm = 90)
message("wrote preview.png")
