# RDA biplot of sites and environmental arrows. Reads the two CSVs only.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
scaling <- 2
arrow_frac <- 0.70
# ------------------

comm_df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
env_df <- utils::read.csv("data_env.csv", stringsAsFactors = FALSE)
samples <- unique(comm_df$sample)
taxa <- unique(comm_df$taxon)
comm <- matrix(0, length(samples), length(taxa), dimnames = list(samples, taxa))
comm[cbind(match(comm_df$sample, samples), match(comm_df$taxon, taxa))] <- comm_df$abundance
env_df <- env_df[match(samples, env_df$sample), , drop = FALSE]
group <- comm_df$group[match(samples, comm_df$sample)]
env <- env_df[, vapply(env_df, is.numeric, logical(1)), drop = FALSE]

comm_h <- vegan::decostand(comm, method = "hellinger")
ord <- vegan::rda(comm_h ~ ., data = env)
eig <- vegan::eigenvals(ord)
pct <- 100 * eig[seq_len(2)] / sum(eig)
stopifnot(all(is.finite(pct)))

site_sc <- as.data.frame(vegan::scores(ord, display = "sites", choices = 1:2, scaling = scaling))
bp_sc <- as.data.frame(vegan::scores(ord, display = "bp", choices = 1:2, scaling = scaling))
names(site_sc) <- c("RDA1", "RDA2")
names(bp_sc) <- c("RDA1", "RDA2")
site_sc$group <- factor(stats::setNames(group, samples)[rownames(site_sc)],
                        levels = c("Forest", "Meadow", "Marsh"))
site_r <- max(sqrt(site_sc$RDA1^2 + site_sc$RDA2^2))
bp_r <- max(sqrt(bp_sc$RDA1^2 + bp_sc$RDA2^2))
arrow_mul <- arrow_frac * site_r / bp_r
pretty <- c(pH = "pH", Moisture = "Moisture", Nitrogen = "Nitrogen", Temp = "Temp", OrganicC = "Organic C")
arrows <- data.frame(
  lab = unname(pretty[rownames(bp_sc)]),
  x = bp_sc$RDA1 * arrow_mul,
  y = bp_sc$RDA2 * arrow_mul,
  stringsAsFactors = FALSE
)
# Label anchor sits just past the tip; hjust/vjust push the glyphs further outward.
lab_size <- 2.3
stretch <- 1.10
arrows$lx <- arrows$x * stretch
arrows$ly <- arrows$y * stretch
arrows$hjust <- ifelse(arrows$x >= 0, 0, 1)
arrows$vjust <- ifelse(arrows$y >= 0, 0, 1)
panel_mm <- 54
lim <- max(abs(c(site_sc$RDA1, site_sc$RDA2, arrows$lx, arrows$ly))) * 1.25
for (step in seq_len(5)) {
  mm_per <- panel_mm / (2 * lim)
  tw <- 0.52 * nchar(arrows$lab) * lab_size / mm_per
  th <- lab_size / mm_per
  xmin <- ifelse(arrows$hjust == 0, arrows$lx, arrows$lx - tw)
  xmax <- ifelse(arrows$hjust == 0, arrows$lx + tw, arrows$lx)
  ymin <- ifelse(arrows$vjust == 0, arrows$ly, arrows$ly - th)
  ymax <- ifelse(arrows$vjust == 0, arrows$ly + th, arrows$ly)
  lim <- max(abs(c(
    site_sc$RDA1, site_sc$RDA2, arrows$x, arrows$y, xmin, xmax, ymin, ymax
  ))) * 1.08
}
pad <- 1 / (panel_mm / (2 * lim))
collide <- FALSE
n_lab <- nrow(arrows)
if (n_lab > 1) {
  for (i in seq_len(n_lab - 1)) {
    for (j in (i + 1):n_lab) {
      hit <- xmax[i] + pad > xmin[j] - pad && xmax[j] + pad > xmin[i] - pad &&
        ymax[i] + pad > ymin[j] - pad && ymax[j] + pad > ymin[i] - pad
      if (hit) collide <- TRUE
    }
  }
}
if (collide) lim <- lim * 1.06
if (collide) {
  label_layer <- ggrepel::geom_text_repel(
    data = arrows,
    ggplot2::aes(x = x, y = y, label = lab, hjust = hjust, vjust = vjust),
    nudge_x = arrows$x * (stretch - 1),
    nudge_y = arrows$y * (stretch - 1),
    size = lab_size,
    colour = "black",
    min.segment.length = 0,
    segment.size = 0.25,
    segment.colour = "black",
    force = 0.4,
    force_pull = 0.2,
    box.padding = 0.2,
    point.padding = 0.05,
    max.overlaps = Inf,
    max.iter = 5000,
    seed = 4,
    xlim = c(-lim, lim),
    ylim = c(-lim, lim),
    show.legend = FALSE
  )
} else {
  label_layer <- ggplot2::geom_text(
    data = arrows,
    ggplot2::aes(x = lx, y = ly, label = lab, hjust = hjust, vjust = vjust),
    size = lab_size,
    colour = "black"
  )
}
pal <- stats::setNames(pv_palette("categorical", nlevels(site_sc$group)), levels(site_sc$group))

p <- ggplot2::ggplot() +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "#E0E0E0") +
  ggplot2::geom_vline(xintercept = 0, linewidth = 0.25, colour = "#E0E0E0") +
  ggplot2::geom_segment(
    data = arrows,
    ggplot2::aes(x = 0, y = 0, xend = x, yend = y),
    arrow = grid::arrow(angle = 22, length = grid::unit(1.5, "mm"), type = "closed"),
    linewidth = 0.35,
    colour = "black"
  ) +
  ggplot2::geom_point(
    data = site_sc,
    ggplot2::aes(RDA1, RDA2, colour = group),
    size = 1.7, alpha = 0.9
  ) +
  label_layer +
  ggplot2::scale_colour_manual(values = pal, name = NULL) +
  ggplot2::coord_equal(xlim = c(-lim, lim), ylim = c(-lim, lim), expand = FALSE) +
  ggplot2::labs(
    x = sprintf("RDA1 (%.1f%%)", pct[[1]]),
    y = sprintf("RDA2 (%.1f%%)", pct[[2]])
  ) +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.02, 0.98),
    legend.justification.inside = c(0, 1),
    legend.key.height = ggplot2::unit(2.8, "mm"),
    legend.key.width = ggplot2::unit(3.6, "mm")
  )

pv_save(p, "figure", width_mm = 85, height_mm = 85)
message(sprintf("RDA1 %.1f%%  RDA2 %.1f%%", pct[[1]], pct[[2]]))
message("wrote preview.png")
