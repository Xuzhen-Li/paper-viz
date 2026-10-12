# House example: dense open-circle time series, one colour per series,
# bold series labels at the line ends in the series colour, plateau stats printed in the panel.
source("../../../styles/r/theme_house.R")
library(ggplot2)
d <- read.csv("data.csv")
pal <- pv_palette("house"); grey <- pv_palette("house_grey")
d$series <- paste(d$genotype, d$height)
cols <- c("WT upper" = pal[["magenta"]], "hsp-ko upper" = pal[["orange"]],
          "hsp-ko lower" = pal[["purple"]], "WT lower" = pal[["green"]])
plat <- aggregate(temp_c ~ series, d[d$time_s >= 2400, ], mean)
pm <- setNames(plat$temp_c, plat$series)
ends <- d[d$time_s == max(d$time_s), ]
ends$lab <- sprintf("%s (%s leaf)", ends$genotype, ends$height)
# label y from the series' extreme over the label's x span (x >= 1800 covers the longest label):
# above the max for the upper series of each pair, below the min for the other, 1 unit clear.
side <- c("WT upper" = 1, "hsp-ko upper" = -1, "hsp-ko lower" = 1, "WT lower" = -1)
span <- d[d$time_s >= 1800, ]
ends$y <- vapply(ends$series, function(s) {
  v <- span$temp_c[span$series == s]
  if (side[[s]] > 0) max(v) + 1 else min(v) - 1
}, numeric(1))
dup <- pm[["WT upper"]] - pm[["WT lower"]]; dko <- pm[["hsp-ko upper"]] - pm[["hsp-ko lower"]]
p <- ggplot(d, aes(time_s, temp_c, colour = series)) +
  geom_point(shape = 1, size = 1.1, stroke = pv_pt2lw(0.6)) +
  geom_text(data = ends, aes(x = 3640, y = y, label = lab), hjust = 1, fontface = "bold") +
  annotate("text", x = 80, y = 43.6, hjust = 0, vjust = 1, lineheight = 0.95, colour = grey[["dark"]],
           label = paste("Upper - lower leaf, 2400\u20133600 s",
                         sprintf("WT +%.1f \u00b0C, hsp-ko +%.1f \u00b0C", dup, dko), sep = "\n")) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = seq(0, 3600, 900)) +
  scale_y_continuous(breaks = seq(20, 44, 4)) +
  coord_cartesian(xlim = c(0, 3700), ylim = c(20, 44), expand = FALSE) +
  labs(x = "Time (s)", y = "Leaf temperature (\u00b0C)",
       caption = "Simulated data for illustration; not biological results") +
  theme_house() +
  theme(plot.caption = element_text(hjust = 0, colour = grey[["mid"]]), plot.caption.position = "plot",
        plot.margin = margin(2, 3, 1, 1, "mm"))
pv_save_house(p, "figure", cells = "2x2")
