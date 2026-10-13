# PCoA from a Bray-Curtis matrix (house style). Axis titles carry the share of variation;
# group names written next to each group. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
footnote <- "Simulated data;\nnot biological results"

bray <- function(x) {
  n <- nrow(x)
  d <- matrix(0, n, n)
  for (i in seq_len(n - 1)) {
    for (j in (i + 1):n) {
      num <- sum(abs(x[i, ] - x[j, ]))
      den <- sum(x[i, ] + x[j, ])
      d[i, j] <- d[j, i] <- num / den
    }
  }
  stats::as.dist(d)
}

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
samples <- unique(df$sample)
taxa <- unique(df$taxon)
mat <- matrix(0, length(samples), length(taxa), dimnames = list(samples, taxa))
mat[cbind(match(df$sample, samples), match(df$taxon, taxa))] <- df$abundance
group <- df$group[match(samples, df$sample)]
pc <- stats::cmdscale(bray(mat), k = 2, eig = TRUE)
plot_df <- data.frame(x = pc$points[, 1], y = pc$points[, 2], group = group)
eig_pos <- pc$eig[pc$eig > 0]
pct <- round(100 * pc$eig[1:2] / sum(eig_pos), 1)

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
lv <- unique(as.character(plot_df$group))
plot_df$group <- factor(plot_df$group, levels = lv)
cols <- stats::setNames(unname(hp[seq_along(lv)]), lv)
# group names written on white: the group colour when it is >= 3:1 on white, else #1A1A1A
name_cols <- stats::setNames(ifelse(cols %in% hp[c("orange", "sky", "gold")], "#1A1A1A", cols), names(cols))
# direct labels: each name sits centred just above its group's highest point
labs_df <- do.call(rbind, lapply(lv, function(g) {
  s <- plot_df[plot_df$group == g, , drop = FALSE]
  data.frame(group = g, x = mean(range(s$x)), y = max(s$y), hjust = 0.5, vjust = -0.9)
}))

p <- ggplot(plot_df, aes(x, y, fill = group)) +
  geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             colour = HOUSE_POINT$colour) +
  geom_text(data = labs_df, aes(x, y, label = group, hjust = hjust, vjust = vjust), inherit.aes = FALSE,
            colour = name_cols[labs_df$group], size = pv_pt2size(7), family = house_family()) +
    scale_fill_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.06, 0.16))) +
  scale_x_continuous(expand = expansion(mult = 0.08)) +
  labs(x = sprintf("PCoA1 (%.1f%%)", pct[1]), y = sprintf("PCoA2 (%.1f%%)", pct[2]), caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(1, 1.5, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
