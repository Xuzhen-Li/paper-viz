# House-style heatmap: blue–red diverging around 0, values in every cell, rows ordered by clustering.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

limit <- 3
cluster_rows <- TRUE
dark_cut <- 1.6
colourbar_mm <- 27

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
stress <- unique(df$stress)
days <- sort(unique(df$day))
df$col <- (match(df$stress, stress) - 1) * length(days) + match(df$day, days)
wide <- tapply(df$log2fc, list(df$gene, df$col), mean)
genes <- if (isTRUE(cluster_rows)) rownames(wide)[stats::hclust(stats::dist(wide))$order] else unique(df$gene)
df$row <- match(df$gene, rev(genes))
df$txt <- ifelse(abs(df$log2fc) > dark_cut, "white", "black")
ncol_ <- length(stress) * length(days)
grp <- data.frame(x = (seq_along(stress) - 1) * length(days) + (length(days) + 1) / 2,
                  lab = stress)

p <- ggplot(df, aes(col, row)) +
  geom_tile(aes(fill = pmax(pmin(log2fc, limit), -limit)), colour = "white", linewidth = pv_house_lw(0.3)) +
  geom_text(aes(label = gsub("-", "\u2212", sprintf("%.1f", log2fc)), colour = txt), size = pv_pt2size(6)) +
  geom_vline(xintercept = length(days) + 0.5, colour = "white", linewidth = pv_house_lw(2)) +
  annotate("text", x = grp$x, y = length(genes) + 0.75, label = grp$lab, vjust = 0, size = pv_pt2size(7)) +
  scale_colour_identity() +
  scale_fill_gradientn(colours = pv_palette("house_div"), limits = c(-limit, limit),
                       breaks = seq(-limit, limit, 1.5),
                       labels = function(x) gsub("-", "\u2212", format(x)), name = expression(log[2] ~ FC)) +
  scale_x_continuous(breaks = seq_len(ncol_), labels = rep(paste(days, "d"), length(stress)),
                     expand = c(0, 0)) +
  scale_y_continuous(breaks = seq_along(genes), labels = rev(genes), expand = c(0, 0)) +
  guides(fill = guide_colourbar(theme = theme(legend.key.width = unit(2, "mm"),
                                               legend.key.height = unit(colourbar_mm, "mm")))) +
  coord_cartesian(clip = "off") +
  labs(x = "Days of stress", y = NULL) +
  theme_house() +
  theme(panel.border = element_blank(), axis.ticks = element_blank(),
        axis.text.y = element_text(face = "italic"),
        legend.position = "right", legend.title = element_text(size = 7, margin = margin(b = 2, unit = "mm")),
        legend.margin = margin(0, 0, 0, 1, "mm"), legend.box.spacing = unit(1, "mm"),
        plot.margin = margin(4.2, 0.8, 0.4, 0.4, "mm"))

pv_save_house(p, "figure", width = "single", height_mm = 80)
message("wrote preview.png")
