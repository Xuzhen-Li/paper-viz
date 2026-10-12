# Beeswarm (house style): quasirandom shape-21 points, median bar, Wilcoxon P over brackets,
# n per group in the group colour. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
show_signif <- TRUE
use_facet <- FALSE
group_levels <- c("Ctrl", "Dose1", "Dose2", "Dose3")
comparisons <- list(c("Ctrl", "Dose1"), c("Dose2", "Dose3"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green, purple: all >= 3:1 on white, so n labels keep the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]],
                          hp[["brown"]], hp[["magenta"]])[seq_along(group_levels)], group_levels)
footnote <- "Simulated data for illustration; not biological results"
raw_point <- utils::modifyList(HOUSE_POINT, list(size = 1.4))
panel_of <- function(g) factor(ifelse(as.character(g) %in% group_levels[1:2], "Low dose", "High dose"),
                               levels = c("Low dose", "High dose"))
df$panel <- panel_of(df$group)

rng <- range(df$value)
step <- diff(rng) * 0.1
n_y <- rng[1] - 0.08 * diff(rng)
st <- data.frame(group = factor(group_levels, levels = group_levels),
                 n = as.integer(table(df$group)[group_levels]),
                 med = vapply(group_levels, function(g) stats::median(df$value[df$group == g]), numeric(1)))
st$panel <- panel_of(st$group)

p <- ggplot(df, aes(group, value)) +
  ggbeeswarm::geom_quasirandom(aes(fill = group), shape = raw_point$shape, size = raw_point$size,
                               stroke = raw_point$stroke, colour = "black", alpha = 0.8, width = 0.3) +
  geom_errorbar(data = st, aes(x = group, ymin = med, ymax = med), inherit.aes = FALSE, width = 0.5,
                linewidth = pv_house_lw("emph")) +
  geom_text(data = st, aes(x = group, y = n_y, label = paste0("n = ", n), colour = group),
            inherit.aes = FALSE) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = c(0, 0)) +
  labs(x = NULL, y = "Response", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

y_top <- rng[2] + step
if (isTRUE(show_signif)) {
  br <- do.call(rbind, lapply(comparisons, function(pair) {
    sub <- droplevels(df[df$group %in% pair, ])
    data.frame(x = match(pair[1], group_levels), xend = match(pair[2], group_levels),
               y = max(sub$value) + step * 0.6, panel = panel_of(pair[1]),
               label = pv_fmt_p(stats::wilcox.test(value ~ group, data = sub)$p.value))
  }))
  if (isTRUE(use_facet)) br[, c("x", "xend")] <- br[, c("x", "xend")] - 2 * (br$panel == "High dose")
  y_top <- max(br$y) + step * 1.6
  p <- p +
    geom_segment(data = br, aes(x = x, xend = xend, y = y, yend = y), inherit.aes = FALSE,
                 linewidth = pv_house_lw("ref")) +
    geom_segment(data = br, aes(x = x, xend = x, y = y, yend = y - step * 0.3), inherit.aes = FALSE,
                 linewidth = pv_house_lw("ref")) +
    geom_segment(data = br, aes(x = xend, xend = xend, y = y, yend = y - step * 0.3), inherit.aes = FALSE,
                 linewidth = pv_house_lw("ref")) +
    geom_text(data = br, aes(x = (x + xend) / 2, y = y + step * 0.25, label = label), parse = TRUE,
              vjust = 0, inherit.aes = FALSE)
}
p <- p + coord_cartesian(ylim = c(n_y - 0.07 * diff(rng), y_top))

if (isTRUE(use_facet)) {
  p <- p + facet_wrap(~panel, scales = "free_x")
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
