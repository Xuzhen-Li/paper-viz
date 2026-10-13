# PAV heatmap (house style): genomes x gene families, present blue / absent grey, families grouped by
# compartment (core / shell / cloud named with their counts on the band above), mean families per
# genome as the stat. Drawn with ggplot2 + patchwork. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
cluster_genomes <- TRUE
show_compartment <- TRUE

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
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
genomes <- unique(df$genome)
families <- unique(df$family)
mat <- matrix(0L, nrow = length(genomes), ncol = length(families), dimnames = list(genomes, families))
for (i in seq_len(nrow(df))) mat[df$genome[i], df$family[i]] <- df$present[i]
comp <- tapply(df$compartment, df$family, function(z) z[[1]])[families]
comp <- factor(comp, levels = c("core", "shell", "cloud"))
# order families by compartment, then by how often they are present
ord <- order(comp, -colMeans(mat))
mat <- mat[, ord, drop = FALSE]
comp <- comp[ord]
if (isTRUE(cluster_genomes)) {
  hc <- stats::hclust(stats::dist(mat, method = "binary"))
  mat <- mat[hc$order, , drop = FALSE]
}
comp_cols <- c(core = hp[["blue"]], shell = hp[["sky"]], cloud = hp[["gold"]])
cell_cols <- c("0" = grey[["light"]], "1" = hp[["blue"]])
nf <- ncol(mat)

long <- data.frame(genome = rownames(mat)[row(mat)], family = colnames(mat)[col(mat)],
                   present = factor(as.vector(mat), levels = c("0", "1")), stringsAsFactors = FALSE)
long$genome <- factor(long$genome, levels = rev(rownames(mat)))
long$family <- factor(long$family, levels = colnames(mat))

p_heat <- ggplot(long, aes(family, genome, fill = present)) +
  geom_tile(colour = "white", linewidth = pv_house_lw(0.25)) +
  scale_fill_manual(values = cell_cols, guide = "none") +
  scale_x_discrete(expand = c(0, 0)) +
  labs(x = sprintf("%d gene families (blue present, grey absent); mean %.0f per genome", nf, mean(rowSums(mat))),
       y = "Genome") +
  theme_house() + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
                        axis.title.x = element_text(size = 7), panel.border = element_blank())

note <- plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                          theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))
if (isTRUE(show_compartment)) {
  ann <- data.frame(family = factor(names(comp), levels = colnames(mat)), compartment = comp)
  rng <- do.call(rbind, lapply(split(seq_len(nf), comp), function(ix)
    data.frame(mid = mean(range(ix)), n = length(ix))))
  rng$compartment <- rownames(rng)
  rng$lab <- sprintf("%s (%d)", rng$compartment, rng$n)
  rng$col <- ifelse(rng$compartment == "core", "white", "#1A1A1A")
  p_ann <- ggplot(ann, aes(as.integer(family), y = 1, fill = compartment)) +
    geom_tile(height = 1, width = 1) +
    geom_text(data = rng, aes(x = mid, y = 1, label = lab, colour = col), inherit.aes = FALSE,
              size = pv_pt2size(7), family = house_family()) +
    scale_colour_identity() +
    scale_fill_manual(values = comp_cols, guide = "none") +
    scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0)) +
    theme_void() + theme(plot.margin = margin(1, 0, 0.6, 0, "mm"))
  p <- (p_ann / p_heat) + plot_layout(heights = c(0.07, 1)) + note
} else {
  p <- p_heat + note
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
