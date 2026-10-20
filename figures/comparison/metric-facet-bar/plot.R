# Multi-metric faceted bars (house style): one small panel per metric, each with its own y axis
# starting at zero, bars = mean over folds with an s.d. error bar, the mean written above each bar
# and the best method per metric (by the `direction` column) written in bold.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
n_cols <- 4                    # panels per row (4 panels in one 4x1 row)
fig_cells <- "4x1"             # house grid cells (183 x 43 mm)
show_values <- TRUE            # mean above each bar
mark_best <- TRUE              # bold value for the best method in each panel
show_direction <- TRUE         # add "higher/lower is better" to the panel title
digits <- c("Accuracy (%)" = 1, "F1 score" = 3, "AUROC" = 3, "Runtime (min)" = 1)
headroom <- 1.22               # y top = headroom x (mean + s.d.) of the tallest bar, per panel
footnote <- "Simulated data; not real benchmark results. Bars: mean \u00b1 s.d. of %d folds; bold = best"   # %d = number of folds in data.csv

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
method_cols <- c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["brown"]], hp[["magenta"]])

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$method <- factor(df$method, levels = unique(df$method))
footnote <- sprintf(footnote, length(unique(df$fold)))
m_lv <- unique(df$metric)
s <- do.call(rbind, lapply(split(df, list(df$metric, df$method), drop = TRUE), function(d) {
  data.frame(metric = d$metric[1], direction = d$direction[1], method = d$method[1],
             mean = mean(d$value), sd = stats::sd(d$value), stringsAsFactors = FALSE)
}))
s$method <- factor(s$method, levels = levels(df$method))
dirs <- tapply(s$direction, s$metric, `[`, 1)
strip <- if (isTRUE(show_direction)) {
  sprintf("%s, %s is better", m_lv, dirs[m_lv])
} else m_lv
s$panel <- factor(strip[match(s$metric, m_lv)], levels = strip)
s$best <- stats::ave(seq_len(nrow(s)), s$metric, FUN = function(i) {
  v <- s$mean[i]
  if (s$direction[i[1]] == "lower") v == min(v) else v == max(v)
}) == 1
dg <- ifelse(s$metric %in% names(digits), digits[s$metric], 2)
s$lab <- mapply(function(v, d) formatC(v, format = "f", digits = d), s$mean, dg)
# per-panel y top, set by an invisible point so every panel keeps 0 at the bottom
tops <- tapply(s$mean + s$sd, s$panel, max) * headroom
blank <- data.frame(panel = factor(names(tops), levels = strip), y = as.numeric(tops),
                    method = factor(levels(s$method)[1], levels = levels(s$method)))
s$lab_y <- s$mean + s$sd + 0.035 * as.numeric(tops[as.character(s$panel)])
cols <- stats::setNames(method_cols[seq_len(nlevels(s$method))], levels(s$method))

p <- ggplot(s, aes(method, mean)) +
  geom_blank(data = blank, aes(method, y)) +
  geom_col(aes(fill = method), width = 0.7, colour = NA) +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.25,
                linewidth = pv_house_lw("errorbar"))
if (isTRUE(show_values)) {
  p <- p + geom_text(aes(y = lab_y, label = lab,
                         fontface = ifelse(mark_best & best, "bold", "plain")),
                     vjust = 0, size = pv_pt2size(7), colour = "#1A1A1A")
}
p <- p +
  facet_wrap(~panel, nrow = ceiling(length(strip) / n_cols), scales = "free_y") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0)),
                     breaks = function(l) pretty(c(0, l[2] / headroom), n = 3)) +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() +
  theme(panel.spacing.x = unit(3, "mm"),
        strip.text = element_text(size = 7, hjust = 0, margin = margin(b = 0.8, unit = "mm")),
        axis.text.x = element_text(size = 7, colour = "black", angle = 0,
                                   margin = margin(t = 0.7, unit = "mm")),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = fig_cells)
message("wrote preview.png")
