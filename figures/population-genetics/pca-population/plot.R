# Population PCA (house style): accessions coloured by population on the geo palette (north -> south),
# normal-theory ellipses, population names written beside each cluster. Reads data.csv and
# data_variance.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_ellipse <- TRUE
show_labels <- TRUE
ellipse_level <- 0.95
pc_x <- "PC1"
pc_y <- "PC2"
# side of its ellipse each population name sits on: above, below, left, right, below_left
# (below, ending at the ellipse centre) or above_left (above, ending at the ellipse's right edge)
label_side <- c("Wild N" = "below", "Wild S" = "below", "Landrace E" = "above",
                "Landrace W" = "below_left", "Cultivar A" = "above_left", "Cultivar B" = "below_left")
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  # below 3:1, use the darker step of the same hue where one exists in the house palettes
  # (orange -> chrom12 orange #E17927, 3.01:1); otherwise #1A1A1A
  darker <- c("#E17D52" = "#E17927", "#F77E12" = "#E17927")
  up <- toupper(hex)
  stats::setNames(ifelse(ratio >= 3, hex, ifelse(up %in% names(darker), darker[up], "#1A1A1A")),
                  names(hex))
}
caption_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                                   lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
                       plot.caption.position = "plot")
# push end-of-line label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  shift <- mean(z) - mean(y[o]); z <- z - shift
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}
# fixed house colour per population (same in every B2 figure)
pop_cols <- c("Wild N" = hp[["blue"]], "Wild S" = hp[["sky"]], "Landrace E" = hp[["green"]],
              "Landrace W" = hp[["gold"]], "Cultivar A" = hp[["red"]], "Cultivar B" = hp[["purple"]])
# populations ordered by geography (mean sampling latitude, north -> south) on the geo palette
pop_geo <- stats::setNames(pv_palette("geo"),
                           c("Wild N", "Cultivar A", "Landrace W", "Landrace E", "Cultivar B", "Wild S"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
ve <- utils::read.csv("data_variance.csv", stringsAsFactors = FALSE)
ve_map <- stats::setNames(ve$var_explained, ve$pc)
pop_order <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
df$pop <- factor(df$pop, levels = pop_order)
cols <- pop_geo[pop_order]
axis_lab <- function(pc) sprintf("%s (%.1f%%)", pc, ve_map[[pc]])

# Name position: fixed coordinates (no repel), just outside the population's ellipse (or its points
# when ellipses are off) on the side given by label_side.
xr <- diff(range(df[[pc_x]])); yr <- diff(range(df[[pc_y]]))
ell <- ggplot2::layer_data(ggplot(df, aes(.data[[pc_x]], .data[[pc_y]], group = pop)) +
                             stat_ellipse(type = "norm", level = ellipse_level))
ell$pop <- levels(df$pop)[ell$group]
ext <- if (isTRUE(show_ellipse)) ell[, c("pop", "x", "y")] else
  data.frame(pop = as.character(df$pop), x = df[[pc_x]], y = df[[pc_y]])
cen <- do.call(rbind, lapply(pop_order, function(g) {
  e <- ext[ext$pop == g, ]
  side <- if (g %in% names(label_side)) label_side[[g]] else "above"
  mx <- mean(range(e$x)); my <- mean(range(e$y))
  switch(side,
    above = data.frame(pop = g, lx = mx, ly = max(e$y) + 0.03 * yr, hjust = 0.5, vjust = 0),
    above_left = data.frame(pop = g, lx = max(e$x), ly = max(e$y) + 0.05 * yr, hjust = 1, vjust = 0),
    below = data.frame(pop = g, lx = mx, ly = min(e$y) - 0.03 * yr, hjust = 0.5, vjust = 1),
    below_left = data.frame(pop = g, lx = mx, ly = min(e$y) - 0.03 * yr, hjust = 1, vjust = 1),
    left  = data.frame(pop = g, lx = min(e$x) - 0.03 * xr, ly = my, hjust = 1, vjust = 0.5),
    right = data.frame(pop = g, lx = max(e$x) + 0.03 * xr, ly = my, hjust = 0, vjust = 0.5))
}))

p <- ggplot(df, aes(.data[[pc_x]], .data[[pc_y]]))
if (isTRUE(show_ellipse)) {
  p <- p + stat_ellipse(aes(fill = pop, colour = pop), geom = "polygon", type = "norm",
                        level = ellipse_level, alpha = 0.12, linewidth = pv_house_lw("minor"))
}
p <- p + geom_point(aes(fill = pop), shape = HOUSE_POINT$shape, size = 1.1, stroke = HOUSE_POINT$stroke,
                    colour = HOUSE_POINT$colour)
if (isTRUE(show_labels)) {
  p <- p + geom_text(data = cen, aes(lx, ly, label = pop, hjust = hjust, vjust = vjust),
                     colour = text_col(cols)[as.character(cen$pop)], size = pv_pt2size(7),
                     family = house_family())
}
p <- p +
  scale_x_continuous(expand = expansion(mult = c(0.42, 0.1)), labels = function(x) format(x, trim = TRUE)) +
  scale_y_continuous(expand = expansion(mult = 0.12), labels = function(x) format(x, trim = TRUE)) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = if (isTRUE(show_labels)) "none" else "legend", name = NULL) +
  labs(x = axis_lab(pc_x), y = axis_lab(pc_y), caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
