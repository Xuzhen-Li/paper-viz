# House-style donut: shares on the ring, names in the sector colour, total in the centre.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

inner_r <- 0.56
min_share <- 0.03
centre_title <- "Catchment"
unit_label <- "km\u00b2"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$share <- df$area_km2 / sum(df$area_km2)
small <- df$share < min_share
if (any(small)) {
  df <- rbind(df[!small, c("cover", "area_km2")],
              data.frame(cover = "Other", area_km2 = sum(df$area_km2[small])))
}
df <- df[order(df$cover == "Other", -df$area_km2), ]
df$share <- df$area_km2 / sum(df$area_km2)
df$end <- cumsum(df$share)
df$start <- df$end - df$share
df$mid <- (df$start + df$end) / 2
n_col <- sum(df$cover != "Other")
cols <- stats::setNames(c(unname(pv_palette("house", n_col)), pv_palette("house_grey")[["ci"]])[seq_len(nrow(df))],
                        df$cover)
light <- c("#E6C32A", "#62B4E7", "#BFBFBF")
df$txt <- ifelse(cols[df$cover] %in% light, "black", "white")
name_col <- ifelse(df$cover == "Other", pv_palette("house_grey")[["mid"]], cols[df$cover])
ang <- 2 * pi * df$mid
df$hj <- ifelse(abs(sin(ang)) < 0.15, 0.5, ifelse(sin(ang) > 0, 0, 1))

p <- ggplot(df) +
  geom_rect(aes(xmin = inner_r, xmax = 1, ymin = start, ymax = end, fill = cover), colour = "white",
            linewidth = pv_house_lw(0.5)) +
  geom_text(aes(x = (inner_r + 1) / 2, y = mid, label = sprintf("%.0f%%", 100 * share), colour = txt),
            size = pv_pt2size(7)) +
  geom_text(aes(x = 1.1, y = mid, label = cover, hjust = hj), colour = name_col, size = pv_pt2size(7),
            fontface = "bold") +
  annotate("text", x = 0, y = 0, label = sprintf("%s\n%s %s", centre_title,
           format(round(sum(df$area_km2)), big.mark = ","), unit_label), size = pv_pt2size(8), lineheight = 0.95) +
  scale_fill_manual(values = cols) +
  scale_colour_identity() +
  scale_x_continuous(limits = c(0, 1.12)) +
  coord_polar(theta = "y", clip = "off") +
  theme_house() +
  theme(panel.border = element_blank(), axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks = element_blank(), axis.title.x = element_blank(), axis.title.y = element_blank(),
        plot.margin = margin(1, 12, 1, 12, "mm"))

pv_save_house(p, "figure", width = "single", height_mm = 70)
message("wrote preview.png")
