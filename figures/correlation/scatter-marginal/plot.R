# Scatter with marginal density, histogram, or boxplot (house style). Reads data.csv only.
# Per-group fits with grey CI; R² and P per group in the main panel double as the legend.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# --- adjustable ---
marginal <- "density" # density | histogram | boxplot
show_regression <- TRUE
# ------------------

marginal <- match.arg(marginal, c("density", "histogram", "boxplot"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
group_order <- c("MCF7", "A549", "HepG2")
df$group <- factor(df$group, levels = group_order)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- c(MCF7 = hp[["blue"]], A549 = hp[["red"]], HepG2 = hp[["green"]])   # all >= 3:1 on white
footnote <- "Simulated data for illustration; not biological results"

xr <- range(df$x); yr <- range(df$y)
xlim <- xr + c(-0.04, 0.04) * diff(xr)
ylim <- c(yr[1] - 0.04 * diff(yr), yr[2] + 0.30 * diff(yr))   # headroom for the stat lines

margin_theme <- theme_house() +
  theme(axis.title = element_blank(), axis.title.x = element_blank(), axis.title.y = element_blank(),
        axis.text = element_blank(), axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.ticks.length = unit(0, "mm"), panel.border = element_blank(),
        plot.margin = margin(0, 0, 0, 0))

build_marginal <- function(along = c("x", "y")) {
  along <- match.arg(along)
  lim <- if (along == "x") xlim else ylim
  if (marginal == "boxplot") {
    p <- if (along == "x") ggplot(df, aes(x = x, y = group, fill = group)) else
      ggplot(df, aes(x = group, y = y, fill = group))
    p <- p + geom_boxplot(width = 0.62, linewidth = pv_house_lw("ref"), outlier.shape = NA, alpha = 0.6,
                          colour = "black")
  } else {
    p <- if (along == "x") ggplot(df, aes(x = x, fill = group)) else ggplot(df, aes(y = y, fill = group))
    if (marginal == "density") {
      p <- p + geom_density(aes(colour = group), linewidth = pv_house_lw(1.2), alpha = 0.3, adjust = 0.85)
    } else {
      p <- p + geom_histogram(binwidth = diff(lim) / 18, boundary = lim[1], position = "identity",
                              alpha = 0.4, colour = "white", linewidth = pv_house_lw(0.3))
    }
  }
  # variable axis: exact limits shared with the main panel; count/density axis: 8% headroom
  grow <- if (marginal == "boxplot") expansion(add = 0.6) else expansion(mult = c(0, 0.08))
  if (along == "x") {
    p <- p + scale_x_continuous(expand = c(0, 0)) + coord_cartesian(xlim = lim)
    p <- if (marginal == "boxplot") p + scale_y_discrete(expand = grow) else p + scale_y_continuous(expand = grow)
  } else {
    p <- p + scale_y_continuous(expand = c(0, 0)) + coord_cartesian(ylim = lim)
    p <- if (marginal == "boxplot") p + scale_x_discrete(expand = grow) else p + scale_x_continuous(expand = grow)
  }
  if (marginal == "density") p <- p + scale_colour_manual(values = pal)
  p + scale_fill_manual(values = pal) + margin_theme
}

p_main <- ggplot(df, aes(x, y))
if (isTRUE(show_regression)) {
  p_main <- p_main +
    geom_smooth(aes(group = group), method = "lm", formula = y ~ x, colour = NA,
                fill = grey[["ci"]], alpha = 0.5) +
    geom_smooth(aes(colour = group), method = "lm", formula = y ~ x, se = FALSE,
                linewidth = pv_house_lw("emph"))
}
st <- do.call(rbind, lapply(seq_along(group_order), function(i) {
  s <- summary(stats::lm(y ~ x, data = df[df$group == group_order[i], ]))
  data.frame(group = factor(group_order[i], levels = group_order), i = i,
             lab = sprintf("'%s  '*italic(R)*'\u00b2 = %.2f, '*%s", group_order[i], s$r.squared,
                           pv_fmt_p(stats::coef(s)[2, 4])))
}))
st$y <- ylim[2] - (st$i - 0.5) * 0.07 * diff(ylim)
p_main <- p_main +
  geom_point(aes(fill = group), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
             stroke = HOUSE_POINT$stroke, colour = "black") +
  geom_text(data = st, aes(x = xlim[1] + 0.02 * diff(xlim), y = y, label = lab, colour = group),
            parse = TRUE, hjust = 0) +
  scale_colour_manual(values = pal) +
  scale_fill_manual(values = pal) +
  coord_cartesian(xlim = xlim, ylim = ylim, expand = FALSE) +
  labs(x = "Gene A (log2 CPM)", y = "Gene B (log2 CPM)") +
  theme_house()

p <- patchwork::wrap_plots(A = build_marginal("x"), B = p_main, C = build_marginal("y"),
                           design = "AAAAA#\nBBBBBC", heights = c(1, 4.2)) +
  patchwork::plot_annotation(caption = footnote, theme = theme(
    plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], family = house_family(),
                                margin = margin(t = 0.8, unit = "mm")),
    plot.caption.position = "plot", plot.margin = margin(0.4, 0.4, 0.9, 0.4, "mm")))

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
