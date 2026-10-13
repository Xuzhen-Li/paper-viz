# Parallel coordinates (house style): each axis scaled to 0-1, one group highlighted over grey,
# group names written at the right end in the line colour, group medians as thick lines.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# --- adjustable ---
highlight_group <- "Batch-A"  # one group name, or "none" to colour every group
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
axes <- unique(df$axis)
df$axis <- factor(df$axis, levels = axes)
df$group <- factor(df$group, levels = unique(df$group))
scaled <- lapply(split(df, df$axis), function(d) {
  rng <- range(d$value)
  d$y <- if (diff(rng) == 0) 0.5 else (d$value - rng[1]) / diff(rng)
  d
})
df <- do.call(rbind, scaled)
df$xn <- as.integer(df$axis)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"
groups <- levels(df$group)
# blue, red, green, purple: all >= 3:1 on white, so the end labels keep the line colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]],
                          hp[["brown"]], hp[["magenta"]])[seq_along(groups)], groups)
n_items <- tapply(df$item, df$group, function(v) length(unique(v)))
med <- stats::aggregate(y ~ group + xn, data = df, FUN = stats::median)
last <- length(axes)

base <- ggplot(df, aes(xn, y, group = item)) +
  geom_vline(xintercept = seq_along(axes), linewidth = pv_house_lw("ref"), colour = grey[["ci"]]) +
  scale_x_continuous(breaks = seq_along(axes), labels = axes, expand = expansion(add = c(0.15, 0.15))) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.5, 1), expand = expansion(add = 0.03)) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Scaled value (0-1)", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot",
        plot.margin = margin(1.6, 13, 0.9, 0.4, "mm"))

if (highlight_group == "none") {
  ends <- med[med$xn == last, ]
  ends$lab <- sprintf("%s\n(n = %d)", ends$group, n_items[as.character(ends$group)])
  p <- base +
    geom_line(aes(colour = group), alpha = 0.35, linewidth = pv_house_lw("minor")) +
    geom_line(data = med, aes(xn, y, group = group, colour = group), linewidth = pv_house_lw("emph")) +
    geom_text(data = ends, aes(x = last + 0.2, y = y, label = lab, colour = group), hjust = 0,
              lineheight = 0.9, inherit.aes = FALSE) +
    scale_colour_manual(values = cols)
} else {
  other <- df[df$group != highlight_group, , drop = FALSE]
  hi <- df[df$group == highlight_group, , drop = FALSE]
  hmed <- med[med$group == highlight_group, ]
  y_end <- hmed$y[hmed$xn == last]
  hcol <- hp[["blue"]]
  p <- base +
    geom_line(data = other, colour = grey[["light"]], linewidth = pv_house_lw("minor")) +
    geom_line(data = hi, colour = hcol, alpha = 0.5, linewidth = pv_house_lw("minor")) +
    geom_line(data = hmed, aes(xn, y, group = 1), colour = hcol, linewidth = pv_house_lw("emph"),
              inherit.aes = FALSE) +
    annotate("text", x = last + 0.2, y = y_end, hjust = 0, lineheight = 0.9, colour = hcol,
             label = sprintf("%s\nmedian\n(n = %d)", highlight_group, n_items[[highlight_group]])) +
    annotate("text", x = last + 0.2, y = if (y_end > 0.5) 0.12 else 0.88, hjust = 0, lineheight = 0.9,
             colour = grey[["mid"]], label = sprintf("Other\n(n = %d)", sum(n_items) - n_items[[highlight_group]]))
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
