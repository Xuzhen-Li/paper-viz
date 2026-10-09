# House-style small multiples: shared axes, one region per panel, trend ± s.e. per decade in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

n_cols <- 4
alpha_sig <- 0.05

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
regions <- unique(df$region)
df$region <- factor(df$region, levels = regions)
pal <- pv_palette("house")
grey <- pv_palette("house_grey")

stars <- function(p) if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else " (n.s.)"
tr <- do.call(rbind, lapply(regions, function(r) {
  s <- summary(stats::lm(anomaly_c ~ I(year / 10), data = df[df$region == r, ]))
  b <- stats::coef(s)[2, ]
  data.frame(region = factor(r, levels = regions), slope = b[[1]], se = b[[2]], p = b[[4]])
}))
tr$col <- ifelse(tr$p >= alpha_sig, grey[["dark"]], ifelse(tr$slope > 0, pal[["red"]], pal[["blue"]]))
tr$lab <- sprintf("%s%.2f \u00b1 %.2f \u00b0C per decade%s", ifelse(tr$slope >= 0, "+", "\u2212"), abs(tr$slope),
                  tr$se, vapply(tr$p, stars, character(1)))
df$col <- tr$col[match(df$region, tr$region)]
y_lim <- c(floor(min(df$anomaly_c) * 2) / 2, ceiling(max(df$anomaly_c) * 2) / 2 + 0.9)
x_lim <- range(df$year) + c(-1, 1)

p <- ggplot(df, aes(year, anomaly_c)) +
  geom_hline(yintercept = 0, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_line(colour = grey[["mid"]], linewidth = pv_house_lw("minor")) +
  geom_smooth(aes(colour = col, fill = col), method = "lm", formula = y ~ x, linewidth = pv_house_lw("emph"),
              alpha = 0.2) +
  geom_text(data = tr, aes(x = x_lim[1] + 1.5, y = y_lim[2] - 0.1, label = region), hjust = 0, vjust = 1,
            size = pv_pt2size(7), fontface = "bold", colour = "black") +
  geom_text(data = tr, aes(x = x_lim[1] + 1.5, y = y_lim[2] - 0.5, label = lab, colour = col), hjust = 0,
            vjust = 1, size = pv_pt2size(7)) +
  facet_wrap(~region, ncol = n_cols) +
  scale_colour_identity() +
  scale_fill_identity() +
  scale_x_continuous(limits = x_lim, breaks = seq(1990, 2020, 10), expand = c(0, 0)) +
  scale_y_continuous(limits = y_lim, breaks = seq(-1, 2, 1), expand = c(0, 0),
                     labels = function(x) gsub("-", "\u2212", format(x))) +
  labs(x = "Year", y = "Temperature anomaly (\u00b0C)") +
  theme_house() +
  theme(strip.text = element_blank(), panel.spacing.x = unit(1.5, "mm"), panel.spacing.y = unit(1.5, "mm"))

pv_save_house(p, "figure", width = "double", height_mm = 84)
message("wrote preview.png")
