# Pangenome (house style): core / shell / cloud shares as a pie with names on the slices, and pan / core
# accumulation curves with a Heaps-law fit (alpha as the in-panel stat), curve names at the line ends.
# Reads data_compartment.csv and data_growth.csv. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
show_pie <- TRUE
show_accumulation <- TRUE
show_heaps <- TRUE
compartment_order <- c("Core", "Shell", "Cloud")

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# orange marks/labels use the darker chrom12 step of the same hue (#E17927, 3.01:1 on white)
hp[["orange"]] <- pv_palette("chrom12")[[8]]
# label text: the group colour if it reaches 3:1 contrast on white, else #1A1A1A (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  stats::setNames(ifelse(ratio >= 3, hex, "#1A1A1A"), names(hex))
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
comp <- utils::read.csv("data_compartment.csv", stringsAsFactors = FALSE)
growth <- utils::read.csv("data_growth.csv", stringsAsFactors = FALSE)
comp$compartment <- factor(comp$compartment, levels = compartment_order)
comp <- comp[order(comp$compartment), , drop = FALSE]
comp_cols <- c(Core = hp[["blue"]], Shell = hp[["sky"]], Cloud = hp[["gold"]])

comp$frac <- comp$n_families / sum(comp$n_families)
end <- cumsum(comp$frac); start <- c(0, utils::head(end, -1))
# slices clockwise from 12 o'clock
slice_poly <- function(a0, a1, lab) {
  ang <- pi / 2 - seq(a0, a1, length.out = 80) * 2 * pi
  data.frame(x = c(0, cos(ang)), y = c(0, sin(ang)), compartment = lab)
}
poly <- do.call(rbind, Map(slice_poly, start, end, as.character(comp$compartment)))
mid <- pi / 2 - (start + end) / 2 * 2 * pi
comp$lx <- 0.6 * cos(mid); comp$ly <- 0.6 * sin(mid)
comp$slice_lab <- sprintf("%s\n%s\n%.0f%%", comp$compartment, format(comp$n_families, big.mark = ","), 100 * comp$frac)
# label colour on the slice: white on the dark blue, #1A1A1A on the light slices
comp$lab_col <- ifelse(comp$compartment == "Core", "white", "#1A1A1A")

p_pie <- ggplot(poly, aes(x, y, fill = compartment)) +
  geom_polygon(colour = "white", linewidth = pv_house_lw("ref")) +
  geom_text(data = comp, aes(lx, ly, label = slice_lab, colour = lab_col), inherit.aes = FALSE,
            size = pv_pt2size(7), lineheight = 0.9, family = house_family()) +
  scale_colour_identity() +
  coord_equal(xlim = c(-1.02, 1.02), ylim = c(-1.02, 1.02)) +
  scale_fill_manual(values = comp_cols, guide = "none") +
  theme_void(base_family = house_family()) + theme(plot.margin = margin(1, 1, 1, 1, "mm"))

fit <- stats::lm(log(pan) ~ log(n_genomes), data = growth)
alpha <- unname(stats::coef(fit)[2])
growth$heaps <- exp(unname(stats::coef(fit)[1])) * growth$n_genomes^alpha
long <- rbind(data.frame(n_genomes = growth$n_genomes, families = growth$pan, curve = "Pan"),
              data.frame(n_genomes = growth$n_genomes, families = growth$core, curve = "Core"))
curve_cols <- c(Pan = hp[["red"]], Core = hp[["blue"]])
ends <- long[long$n_genomes == max(long$n_genomes), ]
nmax <- max(long$n_genomes)

p_acc <- ggplot(long, aes(n_genomes, families / 1e3, colour = curve)) +
  geom_line(linewidth = pv_house_lw("main")) +
  geom_text(data = ends, aes(x = nmax * 1.06, label = curve), hjust = 0, size = pv_pt2size(7),
            family = house_family(), show.legend = FALSE) +
  scale_colour_manual(values = text_col(curve_cols), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.22))) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.1))) +
  labs(x = "Genomes added", y = "Gene families (k)") +
  theme_house()
if (isTRUE(show_heaps)) {
  p_acc <- p_acc +
    geom_line(data = growth, aes(n_genomes, heaps / 1e3), inherit.aes = FALSE, linetype = "22",
              linewidth = pv_house_lw("ref"), colour = grey[["dark"]]) +
    annotate("text", x = nmax * 0.98, y = mean(range(long$families)) / 1e3, hjust = 1,
             label = sprintf("Heaps fit (dashed)\nalpha = %.2f", alpha), lineheight = 0.95,
             size = pv_pt2size(7), colour = "#1A1A1A", family = house_family())
}

note <- plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                          theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))
if (isTRUE(show_pie) && isTRUE(show_accumulation)) {
  p <- (p_pie | p_acc) + plot_layout(widths = c(1, 1.5)) + note
  cells <- "2x1"
} else if (isTRUE(show_pie)) {
  p <- p_pie + note
  cells <- "1x1"
} else {
  p <- p_acc + note
  cells <- "1x1"
}

pv_save_house(p, "figure", cells = cells)
message("wrote preview.png")
