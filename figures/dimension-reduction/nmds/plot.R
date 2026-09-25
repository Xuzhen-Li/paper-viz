# NMDS from a Bray-Curtis matrix. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

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
nm <- MASS::isoMDS(bray(mat), k = 2, trace = FALSE)
plot_df <- data.frame(x = nm$points[, 1], y = nm$points[, 2], group = group)
cols <- pv_palette("categorical", length(unique(group)))

p <- ggplot2::ggplot(plot_df, ggplot2::aes(x, y, colour = group)) +
  ggplot2::geom_point(size = 1.6) +
  ggplot2::scale_colour_manual(values = cols) +
  ggplot2::labs(x = "NMDS1", y = "NMDS2", colour = NULL) +
  theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 70)
message("wrote preview.png")
