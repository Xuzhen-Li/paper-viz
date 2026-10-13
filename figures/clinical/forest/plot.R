# Forest plot (house style): hazard ratio and 95% CI per study on a log axis, dashed line at HR = 1,
# HR [CI] written beside each row and the study count in the panel. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

show_values <- TRUE   # HR [low, high] written just above each CI line
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue is >= 3:1 on white, so the point colour is also used for the value text
point_col <- hp[["blue"]]
footnote <- "Simulated data for\nillustration; not\nbiological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$y <- rev(seq_len(nrow(df)))
df$lab <- sprintf("%.2f [%.2f, %.2f]", df$hr, df$ci_low, df$ci_high)
n_up <- sum(df$ci_low > 1); n_down <- sum(df$ci_high < 1)
x_lim <- c(min(df$ci_low) / 1.2, max(df$ci_high) * 1.2)
y_lim <- c(0.4, nrow(df) + 1.75)

p <- ggplot(df, aes(hr, y)) +
  geom_vline(xintercept = 1, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_segment(aes(x = ci_low, xend = ci_high, yend = y), linewidth = pv_house_lw(0.9),
                 colour = point_col) +
  geom_point(shape = 16, size = 3, colour = point_col) +
  annotate("text", x = x_lim[1] * 1.06, y = nrow(df) + 1.2, hjust = 0, vjust = 0.5,
           label = sprintf("N = %d studies\n%d CI > 1, %d CI < 1", nrow(df), n_up, n_down),
           lineheight = 0.9)
if (isTRUE(show_values)) {
  p <- p + geom_text(aes(x = x_lim[1] * 1.06, y = y + 0.42, label = lab), hjust = 0, colour = point_col)
}
p <- p +
  scale_x_log10(breaks = c(0.5, 1, 2, 4), labels = c("0.5", "1", "2", "4")) +
  scale_y_continuous(breaks = df$y, labels = df$study) +
  coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
  labs(x = "Hazard ratio", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x2")
message("wrote preview.png")
