# House-style scatter: three groups, per-group fit, R² and P in the panel, direct labels.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

label_names <- c("Cabernet Sauvignon", "Pinot Noir", "Saperavi", "Gamay", "Kyoho", "VS133")
group_order <- c("Wild", "Wine", "Table")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
cols <- c(Wild = pal[["green"]], Wine = pal[["red"]], Table = pal[["blue"]])
df$group <- factor(df$group, levels = group_order)

stat_lab <- vapply(group_order, function(g) {
  s <- summary(stats::lm(anthocyanin_mg_g ~ log10(berry_weight_g), data = df[df$group == g, ]))
  sprintf("italic(R)*'\u00b2 = %.2f, '*%s", s$r.squared, pv_fmt_p(stats::coef(s)[2, 4], exact = TRUE))  # 2x2 bumped: exponent 0.7 x 9 pt = 6.3 pt
}, character(1))
stats_df <- data.frame(group = factor(group_order, levels = group_order), x = 13.5,
                       y = c(13.6, 12.5, 11.4), lab = stat_lab)
glab <- data.frame(group = factor(group_order, levels = group_order),
                   x = c(0.335, 3.5, 7.2), y = c(9.3, 7.4, 4.9), hj = c(0, 0.5, 0.5))
df$lab <- ifelse(df$name %in% label_names, df$name, "")
# Names sit at fixed positions (no repel solver), so the PDF and PNG layouts match on every
# device. Each name sits beside the fit, away from the points, with a straight leader that
# stops just short of the name. Positions are in data units (x on the original scale).
lab_pos <- data.frame(
  name = c("VS133", "Saperavi", "Pinot Noir", "Gamay", "Cabernet Sauvignon", "Kyoho"),
  lx   = c(0.62,    0.66,       1.09,         1.24,    1.40,                 6.95),
  ly   = c(8.2,     6.9,        5.3,          3.9,     2.3,                  2.8)
)
lab_df <- merge(df[df$lab != "", ], lab_pos, by = "name", sort = FALSE)
lab_df$vj <- ifelse(lab_df$ly < lab_df$anthocyanin_mg_g, 1, 0)   # name below or above its point
lab_df$sy <- lab_df$ly + ifelse(lab_df$vj == 1, 0.25, -0.25)

p <- ggplot(df, aes(berry_weight_g, anthocyanin_mg_g)) +
  geom_smooth(aes(group = group), method = "lm", formula = y ~ x, colour = NA,
              fill = pv_palette("house_grey")[["ci"]], alpha = 0.5) +
  geom_smooth(aes(colour = group), method = "lm", formula = y ~ x, se = FALSE,
              linewidth = pv_house_lw("emph")) +
  # leaders under the points, so each starts at the marker edge
  geom_segment(data = lab_df, aes(x = berry_weight_g, y = anthocyanin_mg_g, xend = lx, yend = sy,
                                  colour = group), linewidth = pv_house_lw(0.4)) +
  geom_point(aes(fill = group), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             colour = "black") +
  geom_text(data = lab_df, aes(lx, ly, label = name, colour = group, vjust = vj),
            size = pv_pt2size(6)) +
  geom_text(data = glab, aes(x, y, label = group, colour = group, hjust = hj), size = pv_pt2size(8),
            fontface = "bold") +
  geom_text(data = stats_df, aes(x, y, label = lab, colour = group), parse = TRUE,
            hjust = 1, vjust = 1, size = pv_pt2size(7)) +
  scale_colour_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_x_log10(limits = c(0.3, 14), breaks = c(0.5, 1, 2, 5, 10),
                labels = c("0.5", "1", "2", "5", "10"), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 14), breaks = seq(0, 14, 2), expand = c(0, 0)) +
  labs(x = "Berry weight (g, log scale)", y = "Anthocyanin (mg/g FW)") +
  theme_house()

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
