# Ranked lollipops (house style): stems from zero, items flagged in the signif column in the accent
# colour, key and count written inside the panel (no legend). Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
rank_items <- TRUE
highlight_signif <- TRUE
map_importance <- FALSE
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# red and blue are both >= 3:1 on white, so the key text keeps the point colour
signif_colour <- hp[["red"]]
base_colour <- hp[["blue"]]
footnote <- "Simulated data for\nillustration; not\nbiological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$signif <- as.logical(df$signif)
if (rank_items) df <- df[order(df$value), ]
df$y <- seq_len(nrow(df))
df$mark <- factor(ifelse(highlight_signif & df$signif, "Significant", "Other"), levels = c("Significant", "Other"))
cols <- c(Significant = signif_colour, Other = base_colour)
df$pt <- if (map_importance) pmax(1.2, 1.2 + df$value / max(df$value) * 1.6) else HOUSE_POINT$size
n <- nrow(df)
x_max <- max(df$value) * 1.08
key <- data.frame(mark = factor(c("Significant", "Other"), levels = levels(df$mark)),
                  lab = c(sprintf("Significant (%d)", sum(df$mark == "Significant")),
                          sprintf("Not significant (%d)", sum(df$mark == "Other"))),
                  y = c(2.9, 1.6))
if (!isTRUE(highlight_signif)) key <- key[2, ]

p <- ggplot(df, aes(value, y)) +
  geom_segment(aes(x = 0, xend = value, yend = y, colour = mark), linewidth = pv_house_lw("minor")) +
  geom_point(aes(fill = mark, size = pt), shape = HOUSE_POINT$shape, stroke = HOUSE_POINT$stroke,
             colour = "black") +
  geom_text(data = key, aes(x = x_max * 0.98, y = y, label = lab, colour = mark), hjust = 1) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_size_identity() +
  scale_y_continuous(breaks = df$y, labels = df$item) +
  coord_cartesian(xlim = c(0, x_max), ylim = c(0.4, n + 0.6), expand = FALSE) +
  labs(x = "Importance", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x2")
message("wrote preview.png")
