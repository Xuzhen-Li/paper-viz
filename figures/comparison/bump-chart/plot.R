# Bump chart (house style): ranks over time, named items coloured and the rest grey, item names
# written at the line ends in the line colour, rank change of the highlighted items in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

highlight_items <- c("TP53", "KRAS")
time_levels <- paste0("T", 1:6)

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue and red are >= 3:1 on white, so highlighted names keep the line colour;
# grey lines (#BFBFBF, < 3:1) get their names in mid grey #6B6B6B (5.3:1)
hi_cols <- c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["magenta"]])[seq_along(highlight_items)]
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$time <- factor(df$time, levels = time_levels)
df$x <- as.numeric(df$time)
df$mark <- ifelse(df$item %in% highlight_items, df$item, "Other")
mark_levels <- c(highlight_items, "Other")
df$mark <- factor(df$mark, levels = mark_levels)
line_cols <- stats::setNames(c(hi_cols, grey[["ci"]]), mark_levels)
text_cols <- stats::setNames(c(hi_cols, grey[["mid"]]), mark_levels)
df <- df[order(df$mark != "Other"), ]   # highlighted lines drawn last (on top)
n_t <- length(time_levels)
ends <- df[df$time == time_levels[n_t], , drop = FALSE]
starts <- df[df$time == time_levels[1], , drop = FALSE]
chg <- vapply(highlight_items, function(it) {
  sprintf("%s: rank %d to %d", it, starts$rank[starts$item == it], ends$rank[ends$item == it])
}, character(1))
n_rank <- max(df$rank)
y_bottom <- n_rank + 1.45   # one line of rank-change text under the last rank

p <- ggplot(df, aes(x, rank, group = item)) +
  geom_line(aes(colour = mark, linewidth = mark == "Other")) +
  geom_point(aes(fill = mark), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
             stroke = HOUSE_POINT$stroke, colour = "black") +
  geom_text(data = ends, aes(x = n_t + 0.22, label = item, colour = I(text_cols[as.character(mark)])),
            hjust = 0) +
  annotate("text", x = 0.8, y = y_bottom - 0.12, hjust = 0, vjust = 0, lineheight = 0.95,
           label = paste(chg, collapse = "; "), colour = "black") +
  scale_colour_manual(values = line_cols, guide = "none") +
  scale_fill_manual(values = line_cols, guide = "none") +
  scale_linewidth_manual(values = c(`TRUE` = pv_house_lw("minor"), `FALSE` = pv_house_lw("main")),
                         guide = "none") +
  scale_x_continuous(breaks = seq_len(n_t), labels = time_levels) +
  scale_y_reverse(breaks = seq_len(n_rank)) +
  coord_cartesian(xlim = c(0.7, n_t + 1.05), ylim = c(y_bottom, 0.6),
                  expand = FALSE) +
  labs(x = "Time point", y = "Rank", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
