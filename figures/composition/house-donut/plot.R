# House-style donut: shares on the ring, names in the sector colour, total in the centre.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

inner_r <- 0.56
min_share <- 0.03
label_r <- 1.05     # radius of the outer names (ring outer radius = 1)
cells <- c(2, 1)    # composition figure: 2 x 1 grid cells (89 x 43 mm)
plot_margin_mm <- c(1, 1, 1, 0.8)   # t, r, b, l
# visible window in ring units: view_y leaves room for the names above and below the ring;
# view_x is centred and follows the panel aspect (coord_fixed), so the ring fills the height
view_y <- c(-1.13, 1.2)
panel_mm <- c(pv_grid_span(cells[1]) - sum(plot_margin_mm[c(2, 4)]),
              pv_grid_span(cells[2]) - sum(plot_margin_mm[c(1, 3)]))
view_x <- c(-1, 1) * diff(view_y) * panel_mm[1] / panel_mm[2] / 2
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
# Ring drawn as polygons in Cartesian space (coord_polar always pads the radius to 80% of the
# panel, which leaves the white bands this layout avoids). Angles run clockwise from 12 o'clock.
to_xy <- function(frac, r) data.frame(x = r * sin(2 * pi * frac), y = r * cos(2 * pi * frac))
ring <- do.call(rbind, lapply(seq_len(nrow(df)), function(i) {
  f <- seq(df$start[i], df$end[i], length.out = max(2, ceiling(df$share[i] * 360)))
  cbind(rbind(to_xy(f, 1), to_xy(rev(f), inner_r)), cover = df$cover[i])
}))
pct <- cbind(df, to_xy(df$mid, (inner_r + 1) / 2))
nm <- cbind(df, to_xy(df$mid, label_r))
s_mid <- sin(2 * pi * df$mid)
nm$hj <- ifelse(abs(s_mid) < 0.15, 0.5, ifelse(s_mid > 0, 0, 1))
nm$vj <- ifelse(abs(s_mid) < 0.15, ifelse(cos(2 * pi * df$mid) > 0, 0, 1), 0.5)
nm$col <- name_col

p <- ggplot() +
  geom_polygon(data = ring, aes(x, y, group = cover, fill = cover), colour = "white",
               linewidth = pv_house_lw(0.5)) +
  geom_text(data = pct, aes(x, y, label = sprintf("%.0f%%", 100 * share), colour = txt),
            size = pv_pt2size(7)) +
  geom_text(data = nm, aes(x, y, label = cover, hjust = hj, vjust = vj, colour = col),
            size = pv_pt2size(7)) +
  annotate("text", x = 0, y = 0, label = sprintf("%s\n%s %s", centre_title,
           format(round(sum(df$area_km2)), big.mark = ","), unit_label), size = pv_pt2size(8), lineheight = 0.95) +
  scale_fill_manual(values = cols) +
  scale_colour_identity() +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_fixed(xlim = view_x, ylim = view_y, clip = "off") +
  theme_house() +
  theme(panel.border = element_blank(), axis.line = element_blank(), axis.text.x = element_blank(),
        axis.text.y = element_blank(), axis.ticks = element_blank(), axis.title.x = element_blank(),
        axis.title.y = element_blank(), legend.position = "none",
        plot.margin = margin(plot_margin_mm[1], plot_margin_mm[2], plot_margin_mm[3], plot_margin_mm[4], "mm"))

pv_save_house(p, "figure", cells = cells)
message("wrote preview.png")
