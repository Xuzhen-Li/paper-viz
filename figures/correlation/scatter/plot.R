# Scatter (house style): three groups, per-group fit with grey CI, R² and P per group in the panel.
# Group names in the stat lines double as the legend. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

show_regression <- TRUE
colour_by_group <- TRUE
show_density <- FALSE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
group_order <- c("MCF7", "A549", "HepG2")
df$group <- factor(df$group, levels = group_order)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# all three are >= 3:1 on white, so labels keep the group colour
pal <- c(MCF7 = hp[["blue"]], A549 = hp[["red"]], HepG2 = hp[["green"]])
footnote <- "Simulated data for illustration; not biological results"
if (!isTRUE(colour_by_group)) pal[] <- hp[["blue"]]

x_lim <- range(df$x) + c(-1, 1) * 0.04 * diff(range(df$x))
y_lim <- c(min(df$y) - 0.04 * diff(range(df$y)), max(df$y) + 0.22 * diff(range(df$y)))

p <- ggplot(df, aes(x, y))
if (isTRUE(show_density)) {
  p <- p + geom_density_2d(aes(colour = group), linewidth = pv_house_lw("minor"), bins = 5)
}
if (isTRUE(show_regression)) {
  p <- p +
    geom_smooth(aes(group = group), method = "lm", formula = y ~ x, colour = NA,
                fill = grey[["ci"]], alpha = 0.5) +
    geom_smooth(aes(colour = group), method = "lm", formula = y ~ x, se = FALSE,
                linewidth = pv_house_lw("emph"))
}
p <- p +
  geom_point(aes(fill = group), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
             stroke = HOUSE_POINT$stroke, colour = "black")

if (isTRUE(colour_by_group)) {
  st <- do.call(rbind, lapply(seq_along(group_order), function(i) {
    s <- summary(stats::lm(y ~ x, data = df[df$group == group_order[i], ]))
    data.frame(group = factor(group_order[i], levels = group_order), i = i,
               lab = sprintf("'%s  '*italic(R)*'\u00b2 = %.2f, '*%s", group_order[i], s$r.squared,
                             pv_fmt_p(stats::coef(s)[2, 4])))
  }))
  st$y <- y_lim[2] - (st$i - 0.5) * 0.065 * diff(y_lim)
  p <- p + geom_text(data = st, aes(x = x_lim[1] + 0.02 * diff(x_lim), y = y, label = lab, colour = group),
                     parse = TRUE, hjust = 0, vjust = 0.5)
}

p <- p +
  scale_colour_manual(values = pal) +
  scale_fill_manual(values = pal) +
  coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
  labs(x = "Gene A expression (log2 CPM)", y = "Gene B expression (log2 CPM)", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
