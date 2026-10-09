# House-style density: filled curves, dashed group means with labels, Kruskal–Wallis P in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

group_order <- c("Wild", "Wine", "Table")
bw_adjust <- 1.1
x_limits <- c(38, 78)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
cols <- c(Wild = pal[["green"]], Wine = pal[["red"]], Table = pal[["blue"]])
df$group <- factor(df$group, levels = group_order)

mu <- data.frame(group = factor(group_order, levels = group_order),
                 m = vapply(group_order, function(g) mean(df$days[df$group == g]), numeric(1)))
peak <- vapply(group_order, function(g) {
  dd <- stats::density(df$days[df$group == g], adjust = bw_adjust); max(dd$y)
}, numeric(1))
mu$ly <- peak + 0.006
ord <- order(mu$m)
mu$hj <- 0.5
mu$hj[ord[1]] <- 1.08
mu$hj[ord[length(ord)]] <- -0.08
kw <- stats::kruskal.test(days ~ group, data = df)$p.value
y_top <- ceiling((max(mu$ly) + 0.032) * 100) / 100

p <- ggplot(df, aes(days)) +
  geom_density(aes(colour = group, fill = group), linewidth = pv_house_lw(1.4), adjust = bw_adjust,
               alpha = 0.25) +
  geom_rug(aes(colour = group), length = unit(1.2, "mm"), linewidth = pv_house_lw(0.3), alpha = 0.3) +
  geom_segment(data = mu, aes(x = m, xend = m, y = 0, yend = ly - 0.002, colour = group), linetype = "22",
               linewidth = pv_house_lw(0.7)) +
  geom_text(data = mu, aes(x = m, y = ly, label = sprintf("%s\n%.0f d", group, m), colour = group,
                           hjust = hj), vjust = 0, size = pv_pt2size(7), lineheight = 0.9,
            fontface = "bold") +
  annotate("text", x = x_limits[1] + 1, y = y_top * 0.98, hjust = 0, vjust = 1, parse = TRUE,
           label = paste0("'Kruskal\u2013Wallis '*", pv_fmt_p(kw)), size = pv_pt2size(7)) +
  scale_colour_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_x_continuous(limits = x_limits, breaks = seq(40, 75, 10), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, y_top), breaks = seq(0, y_top, 0.05), expand = c(0, 0)) +
  labs(x = "Days from flowering to v\u00e9raison", y = "Density") +
  theme_house()

pv_save_house(p, "figure", width = "single", height_mm = 70)
message("wrote preview.png")
