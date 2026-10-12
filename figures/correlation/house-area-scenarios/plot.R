# House example: stacked composition area under a pathway line, scenario lines,
# open-circle "commitment" marker, vertical gap arrows with printed values, direct labels.
source("../../../styles/r/theme_house.R")
library(ggplot2)
d <- read.csv("data.csv")
g <- function(s) d[d$series == s, ]
pal <- pv_palette("house"); div <- pv_palette("house_div"); grey <- pv_palette("house_grey")
tg <- g("target"); an <- g("annual_share_of_target")
area <- data.frame(year = tg$year, total = tg$value, annual = an$value)
at <- 2050
v <- function(s) g(s)$value[g(s)$year == at]
gap1 <- v("no_control") - v("target"); gap2 <- v("target") - v("ambitious")
stopifnot(gap1 > 0, gap2 > 0)
lw <- pv_house_lw("main")
p <- ggplot() +
  geom_ribbon(data = area, aes(year, ymin = 0, ymax = total), fill = div[4]) +
  geom_ribbon(data = area, aes(year, ymin = 0, ymax = annual), fill = div[3]) +
  geom_line(data = g("history"), aes(year, value), colour = "black", linewidth = lw * 1.4) +
  geom_line(data = g("no_control"), aes(year, value), colour = pal[["magenta"]], linewidth = lw) +
  geom_line(data = g("current_practice"), aes(year, value), colour = pal[["orange"]], linewidth = lw,
            linetype = "22") +
  geom_line(data = tg[tg$year >= 2020, ], aes(year, value), colour = pal[["sky"]], linewidth = lw) +
  geom_line(data = g("ambitious"), aes(year, value), colour = pal[["gold"]], linewidth = lw) +
  annotate("point", x = 2030, y = v2030 <- tg$value[tg$year == 2030], shape = 21, size = 2.6,
           stroke = 1, fill = "white", colour = pal[["blue"]]) +
  annotate("segment", x = at, xend = at, y = v("no_control") - 0.8, yend = v("target") + 0.8,
           colour = grey[["mid"]], linewidth = pv_lw <- pv_pt2lw(0.8),
           arrow = arrow(length = unit(1.4, "mm"), type = "closed")) +
  annotate("segment", x = at, xend = at, y = v("target") - 0.8, yend = v("ambitious") + 0.8,
           colour = grey[["mid"]], linewidth = pv_lw, arrow = arrow(length = unit(1.4, "mm"), type = "closed")) +
  annotate("text", x = at + 3, y = (v("no_control") + v("target")) / 2 + 9, hjust = 0, lineheight = 0.9,
           label = sprintf("Control gap\n(%.0f \u00d7 10\u00b3 seeds)", gap1)) +
  annotate("text", x = at + 3, y = 8.3, hjust = 0, lineheight = 0.9,
           label = sprintf("Ambition gap\n(%.0f \u00d7 10\u00b3 seeds)", gap2)) +
  annotate("text", x = 2013, y = 40, label = "Perennial", colour = "black") +
  annotate("text", x = 2009, y = 18, label = "Annual\nweeds", lineheight = 0.9, colour = "black") +
  annotate("text", x = 2099, y = 61.5, hjust = 1, label = "No control", colour = pal[["magenta"]]) +
  annotate("text", x = 2099, y = g("current_practice")$value[8] + 3.2, hjust = 1,
           label = "Current practice", colour = pal[["orange"]]) +
  annotate("text", x = 2099, y = tg$value[11] + 3.2, hjust = 1, label = "Target", colour = pal[["blue"]]) +
  annotate("text", x = 2099, y = 4.2, hjust = 1, label = "Ambitious", colour = "#8A6D00") +
  annotate("text", x = 2033, y = 49.8, hjust = 0, label = "Pledge", colour = pal[["blue"]]) +
  scale_x_continuous(breaks = seq(2000, 2100, 20)) +
  scale_y_continuous(breaks = seq(0, 60, 20)) +
  coord_cartesian(xlim = c(2000, 2100), ylim = c(0, 64), expand = FALSE, clip = "off") +
  labs(x = NULL, y = "Weed seed bank (10\u00b3 seeds per m\u00b2)",
       caption = "Simulated data for illustration; not biological results") +
  theme_house() +
  theme(plot.caption = element_text(hjust = 0, colour = grey[["mid"]]),
        plot.caption.position = "plot",
        plot.margin = margin(2, 4, 1, 1, "mm"))
pv_save_house(p, "figure", cells = "2x2")
