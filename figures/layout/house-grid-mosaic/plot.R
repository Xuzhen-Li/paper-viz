# House grid mosaic: seven chart types tiled on the 43 mm grid inside one 183 mm double-column page.
# Each panel is a standalone ggplot placed on whole grid cells by pv_house_mosaic(); tiles sit
# 3 mm apart and the 4-cell-wide page gets the 1 mm side margins, so every tile edge lands on
# 1 + 46 k mm and the full-width track (g) lines up with the 1+1+2 rows above it.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

page_cells <- c(4, 3)      # 183 x 135 mm
tag_room_mm <- 3.8         # top margin of every tile, so the bold tag clears the panel
sig_line <- -log10(5e-8)   # genome-wide threshold in panel g

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
blk <- function(id) df[df$panel == id, ]
pal <- pv_palette("house")
grey <- pv_palette("house_grey")
tile_theme <- theme_house() + theme(plot.margin = margin(tag_room_mm, 0.8, 0.9, 0.4, "mm"))
minus <- function(x) gsub("-", "\u2212", format(x, trim = TRUE))

# a scatter + fit ------------------------------------------------------------------------
sc <- blk("scatter"); sc$x <- as.numeric(sc$x)
r2 <- summary(stats::lm(y ~ x, data = sc))$r.squared
pa <- ggplot(sc, aes(x, y)) +
  geom_smooth(method = "lm", formula = y ~ x, colour = pal[["blue"]], fill = grey[["ci"]],
              linewidth = pv_house_lw("emph"), alpha = 0.5) +
  geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             fill = pal[["blue"]], colour = "black") +
  annotate("text", x = 1.25, y = 27, hjust = 0, vjust = 1, size = pv_pt2size(7),
           label = sprintf("italic(R)*'\u00b2 = %.2f'", r2), parse = TRUE) +
  scale_x_continuous(limits = c(1.1, 3.7), breaks = 1:3, expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 28), breaks = seq(0, 25, 10), expand = c(0, 0)) +
  labs(x = "Leaf N (%)", y = "A (\u00b5mol/m\u00b2/s)", tag = "a") + tile_theme

# b histogram ----------------------------------------------------------------------------
hs <- blk("hist")
hist_lim <- c(floor(min(hs$y)) - 1, ceiling(max(hs$y)) + 1)
pb <- ggplot(hs, aes(y)) +
  geom_histogram(binwidth = 0.5, boundary = 0, fill = pal[["sky"]], colour = "white",
                 linewidth = pv_house_lw(0.3)) +
  geom_vline(xintercept = mean(hs$y), linetype = "22", linewidth = pv_house_lw("ref")) +
  scale_x_continuous(limits = hist_lim, breaks = seq(10, 20, 5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 70), breaks = seq(0, 60, 20), expand = c(0, 0)) +
  labs(x = "Berry diameter (mm)", y = "Count", tag = "b") + tile_theme

# c line: mean +/- s.e. ------------------------------------------------------------------
ln <- blk("line"); ln$x <- as.numeric(ln$x)
lm_ <- do.call(rbind, lapply(split(ln, list(ln$group, ln$x)), function(s)
  data.frame(group = s$group[1], x = s$x[1], m = mean(s$y), se = stats::sd(s$y) / sqrt(nrow(s)))))
line_cols <- c(Control = grey[["dark"]], Warmed = pal[["red"]])
ends <- lm_[lm_$x == max(lm_$x), ]
pc <- ggplot(lm_, aes(x, m, colour = group, fill = group)) +
  geom_ribbon(aes(ymin = m - se, ymax = m + se), colour = NA, alpha = 0.25) +
  geom_line(linewidth = pv_house_lw("main")) +
  geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke, colour = "black") +
  geom_text(data = ends, aes(x = x + 1.8, label = group), hjust = 0, size = pv_pt2size(7), fontface = "bold") +
  annotate("text", x = 1, y = 128, hjust = 0, vjust = 1, size = pv_pt2size(6), colour = grey[["mid"]],
           label = "Mean \u00b1 s.e., n = 6") +
  scale_colour_manual(values = line_cols) + scale_fill_manual(values = line_cols) +
  scale_x_continuous(limits = c(-1.5, 52), breaks = seq(0, 42, 7), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 130), breaks = seq(0, 120, 40), expand = c(0, 0)) +
  labs(x = "Days after budburst", y = "Shoot length (mm)", tag = "c") + tile_theme +
  theme(legend.position = "none")

# d bar: mean +/- s.d. + raw points --------------------------------------------------------
br <- blk("bar"); lv <- unique(br$group); br$xi <- match(br$group, lv)
bm <- do.call(rbind, lapply(lv, function(g) data.frame(group = g, xi = match(g, lv),
                                                       m = mean(br$y[br$group == g]), s = stats::sd(br$y[br$group == g]))))
set.seed(3); br$xj <- br$xi + stats::runif(nrow(br), -0.14, 0.14)
bar_top <- ceiling(max(br$y, bm$m + bm$s) * 2 + 0.5) / 2   # every raw point and error bar fits
bar_cols <- stats::setNames(c(grey[["ci"]], pv_palette("house_warm")[2:4]), lv)
pd <- ggplot(bm, aes(xi, m)) +
  geom_col(aes(fill = group), width = 0.66) +
  geom_errorbar(aes(ymin = m - s, ymax = m + s), width = 0.22, linewidth = pv_house_lw("errorbar")) +
  geom_point(data = br, aes(xj, y), shape = 21, fill = "white", colour = "black", size = 1.6,
             stroke = HOUSE_POINT$stroke, alpha = 0.8) +
  scale_fill_manual(values = bar_cols, guide = "none") +
  scale_x_continuous(breaks = seq_along(lv), labels = lv, limits = c(0.5, length(lv) + 0.5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, bar_top), breaks = 0:floor(bar_top), expand = c(0, 0)) +
  labs(x = NULL, y = "Relative expression", tag = "d") + tile_theme

# e box + jitter --------------------------------------------------------------------------
bx <- blk("box"); bx$group <- factor(bx$group, levels = unique(bx$group))
box_cols <- stats::setNames(unname(pal[c("green", "orange", "purple")]), levels(bx$group))
set.seed(5)
pe <- ggplot(bx, aes(group, y)) +
  geom_boxplot(aes(fill = group), width = 0.5, alpha = 0.6, outlier.shape = NA, linewidth = pv_house_lw("ref")) +
  geom_jitter(aes(fill = group), width = 0.12, height = 0, shape = 21, size = 1.2,
              stroke = HOUSE_POINT$stroke, colour = "black", alpha = 0.7) +
  scale_fill_manual(values = box_cols, guide = "none") +
  scale_y_continuous(limits = c(4.6, 7.8), breaks = 5:7, expand = c(0, 0)) +
  labs(x = NULL, y = "Soil pH", tag = "e") + tile_theme

# f stacked composition -----------------------------------------------------------------
cp <- blk("comp"); cover <- c("Crop", "Forest", "Grass", "Other")
cp$group <- factor(cp$group, levels = rev(cover))
comp_cols <- c(Crop = pal[["gold"]], Forest = pal[["green"]], Grass = pal[["sky"]], Other = grey[["ci"]])
pf <- ggplot(cp, aes(x, y, fill = group)) +
  geom_col(width = 0.7, colour = "white", linewidth = pv_house_lw(0.3)) +
  scale_fill_manual(values = comp_cols, breaks = cover, name = NULL) +
  # shares are rounded, so a stack can top 100 by 0.01: zoom (coord) instead of dropping bars (limits)
  scale_y_continuous(breaks = seq(0, 100, 25), expand = c(0, 0)) +
  scale_x_discrete(expand = c(0, 0.5)) +
  coord_cartesian(ylim = c(0, 100)) +
  labs(x = "Site", y = "Land cover (%)", tag = "f") + tile_theme +
  theme(legend.position = "right", legend.key.size = unit(2.6, "mm"), legend.box.spacing = unit(1, "mm"))

# g genome-wide track (4 x 1) --------------------------------------------------------------
tk <- blk("track"); tk$x <- as.numeric(tk$x)
chr <- unique(tk$group)
len <- vapply(chr, function(k) max(tk$x[tk$group == k]), numeric(1))
offset <- c(0, cumsum(len + 2)[-length(len)]); names(offset) <- chr
tk$pos <- tk$x + offset[tk$group]
tk$col <- ifelse(tk$y >= sig_line, pal[["red"]], ifelse(match(tk$group, chr) %% 2 == 1, grey[["dark"]], grey[["ci"]]))
pg <- ggplot(tk, aes(pos, y)) +
  geom_hline(yintercept = sig_line, linetype = "22", linewidth = pv_house_lw("ref"), colour = pal[["red"]]) +
  geom_point(aes(colour = col), size = 0.6, stroke = 0) +
  scale_colour_identity() +
  scale_x_continuous(breaks = offset + len / 2, labels = seq_along(chr),
                     limits = c(-2, max(tk$pos) + 2), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 12), breaks = seq(0, 12, 4), expand = c(0, 0)) +
  labs(x = "Chromosome", y = "\u2212log10 P", tag = "g") + tile_theme

mosaic <- pv_house_mosaic(list(
  list(plot = pa, at = c(1, 1), cells = c(1, 1)),
  list(plot = pb, at = c(2, 1), cells = c(1, 1)),
  list(plot = pc, at = c(3, 1), cells = c(2, 1)),
  list(plot = pd, at = c(1, 2), cells = c(1, 1)),
  list(plot = pe, at = c(2, 2), cells = c(1, 1)),
  list(plot = pf, at = c(3, 2), cells = c(2, 1)),
  list(plot = pg, at = c(1, 3), cells = c(4, 1))
), cells = page_cells)
pv_save_house(mosaic, "figure", cells = c(4, 3))
message("wrote preview.png")
