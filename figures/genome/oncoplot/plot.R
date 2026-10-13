# Oncoplot (house style) with a Ti/Tv bar and a cohort lane: genes by mutation frequency (share written
# at the right), samples by burden, key rows under the matrix. Drawn with ggplot2 + patchwork.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
show_titv <- TRUE
show_sample_lane <- TRUE
cohort_order <- c("A", "B")

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
genes <- unique(df$gene)
samples <- unique(df$sample)
classes <- c("Missense_Ti", "Missense_Tv", "Nonsense", "Frameshift", "Splice")
col <- c(Missense_Ti = hp[["blue"]], Missense_Tv = hp[["sky"]], Nonsense = hp[["red"]],
         Frameshift = hp[["orange"]], Splice = hp[["purple"]])
cohort_cols <- stats::setNames(c(hp[["green"]], hp[["gold"]]), cohort_order)

mat <- matrix("", nrow = length(genes), ncol = length(samples), dimnames = list(genes, samples))
for (i in seq_len(nrow(df))) mat[df$gene[i], df$sample[i]] <- df$variant_class[i]
cohort <- tapply(df$cohort, df$sample, function(z) z[[1]])[samples]
ti <- colSums(mat == "Missense_Ti"); tv <- colSums(mat == "Missense_Tv")

gene_n <- rowSums(mat != "")
gene_ord <- names(sort(gene_n, decreasing = TRUE))
sample_ord <- names(sort(colSums(mat != ""), decreasing = TRUE))
gene_f <- factor(gene_ord, levels = rev(gene_ord))
sample_f <- factor(sample_ord, levels = sample_ord)
ns <- length(sample_ord); ng <- length(gene_ord)

bg <- expand.grid(gene = gene_f, sample = sample_f, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
long <- as.data.frame(as.table(mat), stringsAsFactors = FALSE)
names(long) <- c("gene", "sample", "variant_class")
long <- long[long$variant_class != "", , drop = FALSE]
long$gene <- factor(long$gene, levels = levels(gene_f))
long$sample <- factor(long$sample, levels = levels(sample_f))
long$variant_class <- factor(long$variant_class, levels = classes)
pct <- data.frame(gene = gene_f, label = sprintf("%d%%", round(100 * gene_n[gene_ord] / ns)))

x_sc <- scale_x_discrete(expand = c(0, 0.5))
blank_x <- theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.title.x = element_blank())
p_mat <- ggplot() +
  geom_tile(data = bg, aes(sample, gene), fill = grey[["bg"]], width = 0.9, height = 0.78) +
  geom_tile(data = long, aes(sample, gene, fill = variant_class), width = 0.9, height = 0.78) +
  geom_text(data = pct, aes(x = ns + 0.9, y = gene, label = label), hjust = 0, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family()) +
  scale_fill_manual(values = col, guide = "none", drop = FALSE) +
  x_sc + coord_cartesian(clip = "off") +
  labs(x = sprintf("%d samples, sorted by burden", ns), y = NULL) +
  theme_house() +
  theme(panel.border = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank(),
        axis.text.y = element_text(face = "italic"), plot.margin = margin(0.5, 7, 0.5, 1, "mm"))

panels <- list(); heights <- numeric()
if (isTRUE(show_titv)) {
  tv_long <- rbind(data.frame(sample = sample_f, class = "Missense_Ti", n = as.numeric(ti[sample_ord])),
                   data.frame(sample = sample_f, class = "Missense_Tv", n = as.numeric(tv[sample_ord])))
  p_tv <- ggplot(tv_long, aes(sample, n, fill = class)) +
    geom_col(width = 0.9, colour = NA) +
    annotate("text", x = ns, y = Inf, hjust = 1, vjust = 1.2, size = pv_pt2size(7), colour = "#1A1A1A",
             family = house_family(), label = sprintf("Ti/Tv = %.2f", sum(ti) / max(1, sum(tv)))) +
    scale_fill_manual(values = col, guide = "none") + x_sc +
    scale_y_continuous(breaks = function(l) unique(floor(pretty(l, 2))), expand = expansion(mult = c(0, 0.25))) +
    labs(y = "Missense") + theme_house() + blank_x + theme(plot.margin = margin(1, 7, 0.5, 1, "mm"))
  panels <- c(panels, list(p_tv)); heights <- c(heights, 0.25)
}
if (isTRUE(show_sample_lane)) {
  coh <- data.frame(sample = sample_f, cohort = factor(cohort[sample_ord], levels = cohort_order))
  p_coh <- ggplot(coh, aes(sample, "Cohort", fill = cohort)) +
    geom_tile(height = 0.8, width = 0.9) +
    scale_fill_manual(values = cohort_cols, guide = "none") + x_sc + labs(y = NULL) +
    theme_house() + blank_x + theme(panel.border = element_blank(), axis.ticks.y = element_blank(),
                                    plot.margin = margin(0.5, 7, 0.5, 1, "mm"))
  panels <- c(panels, list(p_coh)); heights <- c(heights, 0.06)
}

# key rows: variant classes, then cohorts (only when the lane is shown)
key <- data.frame(lab = c("Missense Ti", "Missense Tv", "Nonsense", "Frameshift", "Splice"),
                  fill = unname(col[classes]), x = c(0, 1.6, 3.2, 0, 1.6), y = c(3, 3, 3, 2, 2))
if (isTRUE(show_sample_lane)) {
  key <- rbind(key, data.frame(lab = sprintf("Cohort %s", cohort_order), fill = unname(cohort_cols),
                               x = c(3.2, 4.4), y = 2))
}
p_key <- ggplot(key) +
  geom_tile(aes(x = x, y = y, fill = fill), width = 0.12, height = 0.6) +
  geom_text(aes(x = x + 0.1, y = y, label = lab), hjust = 0, size = pv_pt2size(7), colour = "#1A1A1A",
            family = house_family()) +
  scale_fill_identity() +
  coord_cartesian(xlim = c(-0.1, 5.2), ylim = c(1.5, 3.5), expand = FALSE, clip = "off") +
  theme_void() + theme(plot.margin = margin(0.5, 1, 0, 1, "mm"))

panels <- c(panels, list(p_mat), list(p_key))
heights <- c(heights, 1, 0.1)
p <- wrap_plots(panels, ncol = 1, heights = heights) +
  plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                    theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
