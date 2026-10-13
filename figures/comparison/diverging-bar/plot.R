# Diverging bars (house style): bars centred at zero in the two ends of house_div, class names with
# counts written inside the panel in the bar colour (no legend). Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
sort_bars <- TRUE
center_at_zero <- TRUE
class_levels <- c("Decreased", "Increased")

div <- pv_palette("house_div"); grey <- pv_palette("house_grey")
# both ends of house_div are >= 3:1 on white (blue 4.5:1, red 5.5:1), so labels keep the bar colour
cols <- stats::setNames(div[c(1, length(div))], class_levels)
footnote <- "Simulated data for\nillustration; not\nbiological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$class <- factor(df$class, levels = class_levels)
ord <- if (sort_bars) order(df$value) else rev(seq_len(nrow(df)))
df$y[ord] <- seq_len(nrow(df))
ref <- if (center_at_zero) 0 else stats::median(df$value)
n <- nrow(df)
x_lim <- range(c(df$value, 0)) * 1.08
key <- data.frame(class = factor(class_levels, levels = class_levels),
                  n = as.integer(table(df$class)[class_levels]))
key$lab <- sprintf("%s\nn = %d", key$class, key$n)
# Decreased key bottom right, Increased key top left: the empty corners of a sorted diverging plot
key$x <- c(x_lim[2] * 0.96, x_lim[1] * 0.96)
key$y <- c(1.6, n - 0.6)
key$hjust <- c(1, 0)

p <- ggplot(df) +
  geom_col(aes(value, y, fill = class), orientation = "y", width = 0.7) +
  geom_vline(xintercept = ref, linewidth = pv_house_lw("frame"), colour = "black") +
  geom_text(data = key, aes(x = x, y = y, label = lab, colour = class, hjust = hjust), lineheight = 0.95) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  scale_y_continuous(breaks = df$y, labels = df$item) +
  coord_cartesian(xlim = x_lim, ylim = c(0.4, n + 0.6), expand = FALSE) +
  labs(x = "Change from baseline", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x2")
message("wrote preview.png")
