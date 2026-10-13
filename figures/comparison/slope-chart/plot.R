# Slope chart (house style): every item from the first to the second stage, highlighted items
# coloured and named at both ends in the line colour, the rest grey, mean change in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
highlight <- c("P04", "P07", "P11")
label_ends <- TRUE
stage_levels <- c("Before", "After")

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green: all >= 3:1 on white, so the end labels keep the line colour
hi_cols <- c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["magenta"]])[seq_along(highlight)]
footnote <- "Simulated data for illustration;\nnot biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$stage <- factor(df$stage, levels = stage_levels)
df$x <- as.numeric(df$stage)
df$emph <- factor(ifelse(df$item %in% highlight, df$item, "Other"), levels = c(highlight, "Other"))
pal <- stats::setNames(c(hi_cols, grey[["ci"]]), c(highlight, "Other"))
df <- df[order(df$emph != "Other"), ]
w <- reshape(df[, c("item", "stage", "value")], idvar = "item", timevar = "stage", direction = "wide")
chg <- w[[paste0("value.", stage_levels[2])]] - w[[paste0("value.", stage_levels[1])]]
stat_lab <- sprintf("Mean change %+.1f\n%d of %d rise", mean(chg), sum(chg > 0), length(chg))
y_rng <- range(df$value)
y_lim <- c(y_rng[1] - 0.04 * diff(y_rng), y_rng[2] + 0.22 * diff(y_rng))

p <- ggplot(df, aes(x, value, group = item, colour = emph)) +
  geom_line(aes(linewidth = emph == "Other")) +
  geom_point(aes(fill = emph), shape = HOUSE_POINT$shape, size = 1.6, stroke = HOUSE_POINT$stroke,
             colour = "black") +
  annotate("text", x = 0.62, y = y_lim[2], hjust = 0, vjust = 1.15, lineheight = 0.95, label = stat_lab,
           colour = "black")
if (isTRUE(label_ends)) {
  ends <- df[df$emph != "Other", ]
  ends$hjust <- ifelse(ends$x == 1, 1, 0)
  ends$nx <- ifelse(ends$x == 1, 0.9, 2.1)
  # keep labels on the same side at least min_gap apart (in y units)
  min_gap <- 0.075 * diff(y_lim)
  ends <- do.call(rbind, lapply(split(ends, ends$x), function(d) {
    d <- d[order(d$value), ]
    d$ly <- d$value
    for (i in seq_len(nrow(d))[-1]) d$ly[i] <- max(d$ly[i], d$ly[i - 1] + min_gap)
    d
  }))
  p <- p + geom_text(data = ends, aes(x = nx, y = ly, label = item, hjust = hjust), vjust = 0.5)
}
p <- p +
  scale_colour_manual(values = pal, guide = "none") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_linewidth_manual(values = c(`TRUE` = pv_house_lw("minor"), `FALSE` = pv_house_lw("main")),
                         guide = "none") +
  scale_x_continuous(breaks = 1:2, labels = stage_levels) +
  coord_cartesian(xlim = c(0.55, 2.45), ylim = y_lim, expand = FALSE) +
  labs(x = NULL, y = "Index", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
