# PCoA (cmdscale) and NMDS (MASS::isoMDS). vegan is not required.
# Run from recipes/r: Rscript pcoa-nmds.R
set.seed(6)
source("../../styles/r/theme_viz.R")

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

n_samp <- 36
n_taxa <- 12
group <- rep(c("G1", "G2", "G3"), each = 12)
base <- rbind(
  runif(n_taxa, 0, 1),
  runif(n_taxa, 1, 3),
  runif(n_taxa, 0.5, 2)
)
counts <- base[match(group, c("G1", "G2", "G3")), ] + matrix(rexp(n_samp * n_taxa, 2), n_samp)
d <- bray(counts)
cols <- palette_viz(3)
col <- cols[match(group, c("G1", "G2", "G3"))]

pc <- stats::cmdscale(d, k = 2, eig = TRUE)
df_pc <- data.frame(x = pc$points[, 1], y = pc$points[, 2], group = group)
p1 <- ggplot2::ggplot(df_pc, ggplot2::aes(x, y, colour = group)) +
  ggplot2::geom_point(size = 1.6) +
  ggplot2::scale_colour_manual(values = cols) +
  ggplot2::labs(x = "PCoA1", y = "PCoA2", colour = NULL, tag = "a") +
  theme_viz()
ggplot2::ggsave("../../gallery/pcoa.png", p1, width = 89 / 25.4, height = 70 / 25.4, dpi = 300)

nm <- MASS::isoMDS(d, k = 2, trace = FALSE)
df_nm <- data.frame(x = nm$points[, 1], y = nm$points[, 2], group = group)
p2 <- ggplot2::ggplot(df_nm, ggplot2::aes(x, y, colour = group)) +
  ggplot2::geom_point(size = 1.6) +
  ggplot2::scale_colour_manual(values = cols) +
  ggplot2::labs(x = "NMDS1", y = "NMDS2", colour = NULL, tag = "b") +
  theme_viz()
ggplot2::ggsave("../../gallery/nmds.png", p2, width = 89 / 25.4, height = 70 / 25.4, dpi = 300)
message("wrote ../../gallery/pcoa.png and ../../gallery/nmds.png")
