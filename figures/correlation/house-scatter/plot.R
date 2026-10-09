# House-style scatter: three groups, per-group fit, R² and P in the panel, direct labels.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(ggrepel)

label_names <- c("Cabernet Sauvignon", "Pinot Noir", "Saperavi", "Gamay", "Kyoho", "VS133")
group_order <- c("Wild", "Wine", "Table")
point_size <- 2.6

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
cols <- c(Wild = pal[["green"]], Wine = pal[["red"]], Table = pal[["blue"]])
df$group <- factor(df$group, levels = group_order)

stat_lab <- vapply(group_order, function(g) {
  s <- summary(stats::lm(anthocyanin_mg_g ~ log10(berry_weight_g), data = df[df$group == g, ]))
  sprintf("italic(R)^2*' = %.2f, '*%s", s$r.squared, pv_fmt_p(stats::coef(s)[2, 4]))
}, character(1))
stats_df <- data.frame(group = factor(group_order, levels = group_order), x = 13.5,
                       y = c(13.6, 12.5, 11.4), lab = stat_lab)
glab <- data.frame(group = factor(group_order, levels = group_order),
                   x = c(0.335, 3.5, 7.2), y = c(9.3, 7.4, 4.9), hj = c(0, 0.5, 0.5))
df$lab <- ifelse(df$name %in% label_names, df$name, "")
nx <- c(Wild = -0.10, Wine = -0.22, Table = 0.05)[as.character(df$group)]
ny <- c(Wild = -1.6, Wine = -1.4, Table = 1.2)[as.character(df$group)]

p <- ggplot(df, aes(berry_weight_g, anthocyanin_mg_g)) +
  geom_smooth(aes(group = group), method = "lm", formula = y ~ x, colour = NA,
              fill = pv_palette("house_grey")[["ci"]], alpha = 0.5) +
  geom_smooth(aes(colour = group), method = "lm", formula = y ~ x, se = FALSE,
              linewidth = pv_house_lw("emph")) +
  geom_point(aes(fill = group), shape = 21, size = point_size, stroke = HOUSE_POINT$stroke,
             colour = "black") +
  geom_text_repel(aes(label = lab, colour = group), nudge_x = nx, nudge_y = ny,
                  size = pv_pt2size(6), box.padding = 0.4, point.padding = 0.1, max.time = 2,
                  max.iter = 20000, point.size = 2.9, force = 4, force_pull = 0.5,
                  min.segment.length = 0.15, segment.size = pv_house_lw(0.4), max.overlaps = Inf,
                  seed = 3, ylim = c(1.2, 13)) +
  geom_text(data = glab, aes(x, y, label = group, colour = group, hjust = hj), size = pv_pt2size(8),
            fontface = "bold") +
  geom_text(data = stats_df, aes(x, y, label = lab, colour = group), parse = TRUE,
            hjust = 1, vjust = 1, size = pv_pt2size(7)) +
  scale_colour_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_x_log10(limits = c(0.3, 14), breaks = c(0.5, 1, 2, 5, 10),
                labels = c("0.5", "1", "2", "5", "10"), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 14), breaks = seq(0, 14, 2), expand = c(0, 0)) +
  labs(x = "Berry weight (g, log scale)", y = expression("Anthocyanin (mg g"^"\u22121"*" FW)")) +
  theme_house()

pv_save_house(p, "figure", width = "single", height_mm = 76)
message("wrote preview.png")
