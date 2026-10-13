# RDA biplot of sites and environmental arrows. Reads the two CSVs only.
# House style: sites filled by group, group names written above each group, black arrows.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"

# --- adjustable ---
scaling <- 2
arrow_frac <- 1.10
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
lab_size <- pv_pt2size(7)
stretch <- 1.10
arrows$lx <- arrows$x * stretch
arrows$ly <- arrows$y * stretch
arrows$hjust <- ifelse(arrows$x >= 0, 0, 1)
arrows$vjust <- ifelse(arrows$y >= 0, 0, 1)
# Temp's label sits on the arrowhead. Shift it down-left, off the tip.
# Nitrogen is left where it is.
temp_pull <- arrows$lab == "Temp"
arrows$lx[temp_pull] <- arrows$lx[temp_pull] - 0.11
arrows$ly[temp_pull] <- arrows$ly[temp_pull] - 0.08
panel_mm <- 47
lim <- max(abs(c(site_sc$RDA1, site_sc$RDA2, arrows$lx, arrows$ly))) * 1.15
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
# Fixed square window: arrows reach past the site clouds, labels sit beyond the tips.
lim <- max(abs(c(site_sc$RDA1, site_sc$RDA2, arrows$x, arrows$y))) * 1.6
if (collide) {
  label_layer <- ggrepel::geom_text_repel(
    data = arrows,
    ggplot2::aes(x = x, y = y, label = lab, hjust = hjust, vjust = vjust),
    nudge_x = arrows$lx - arrows$x,
    nudge_y = arrows$ly - arrows$y,
    size = lab_size, family = house_family(),
    colour = "#1A1A1A",
    min.segment.length = 0,
    segment.size = 0.25,
    segment.colour = "#1A1A1A",
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
    size = lab_size, family = house_family(),
    colour = "#1A1A1A"
  )
}
pal <- stats::setNames(pv_palette("house")[seq_len(nlevels(site_sc$group))], levels(site_sc$group))
# Group text keeps its colour only at >= 3:1 contrast on white.
lab_col <- stats::setNames(ifelse(vapply(pal, function(h) {
                                      v <- grDevices::col2rgb(h)[, 1] / 255
                                      v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
                                      1.05 / (sum(c(0.2126, 0.7152, 0.0722) * v) + 0.05) < 3
                                    }, logical(1)), "#1A1A1A", pal), names(pal))
grp_lab <- do.call(rbind, lapply(split(site_sc, site_sc$group), function(d) {
  # Groups centred below the origin are named under their lowest point.
  up <- mean(d$RDA2) >= 0
  i <- if (up) which.max(d$RDA2) else which.min(d$RDA2)
  data.frame(group = d$group[i], x = d$RDA1[i], y = d$RDA2[i], vj = if (up) -0.9 else 0.5)
}))
grp_lab$col <- lab_col[as.character(grp_lab$group)]
# Fixed text, no repel: arrow names sit just past their tips, pushed outward.
# Two tips on the same side closer than 0.3 in y split above and below.
arrows$tx <- arrows$x * 1.06
arrows$ty <- arrows$y * 1.06
arrows$hj <- ifelse(arrows$x >= 0, -0.05, 1.05)
arrows$vj <- 0.5
# Near-vertical arrows put their name to the right of the tip, clear of the arrow and
# beyond the vertical zero line (group names below the origin run left instead).
steep <- abs(arrows$x) < 0.25 * abs(arrows$y)
arrows$hj[steep] <- -0.15
arrows$vj[steep] <- 0.5
for (i in seq_len(nrow(arrows))) {
  for (j in seq_len(nrow(arrows))) {
    if (i != j && !steep[i] && !steep[j] && sign(arrows$x[i]) == sign(arrows$x[j]) && abs(arrows$y[i] - arrows$y[j]) < 0.3 * lim) {
      arrows$vj[i] <- if (arrows$y[i] > arrows$y[j]) 0 else 1
    }
  }
}
# Names above a group run away from the vertical zero line, ending at the top point.
grp_lab$hj <- ifelse(grp_lab$x <= 0, 1, 0)
low <- grp_lab$vj >= 0
grp_lab$hj[low] <- ifelse(grp_lab$x[low] <= 0, 1.15, -0.15)
# Equal axes in a 2x1 cell: y spans the data, x widens on each side until the
# arrow names (fixed size in mm, ~36 mm panel height) fit inside the panel.
ylim_v <- c(-1, 1) * max(abs(c(site_sc$RDA2, arrows$ty))) * 1.35
u <- diff(ylim_v) / 36
w_u <- 0.62 * nchar(arrows$lab) * 2.47 * u
left_ext <- ifelse(arrows$hj == 0.5, arrows$tx - w_u / 2, ifelse(arrows$hj > 0.5, arrows$tx - w_u, arrows$tx))
right_ext <- ifelse(arrows$hj == 0.5, arrows$tx + w_u / 2, ifelse(arrows$hj > 0.5, arrows$tx, arrows$tx + w_u))
xlim_v <- c(min(c(site_sc$RDA1, left_ext)) - 0.04 * diff(ylim_v), max(c(site_sc$RDA1, right_ext)) + 0.04 * diff(ylim_v))
# Pad x evenly so the equal-axis panel fills the 2x1 cell instead of leaving side margins.
x_target <- 2.1 * diff(ylim_v)
if (diff(xlim_v) < x_target) xlim_v <- xlim_v + c(-1, 1) * (x_target - diff(xlim_v)) / 2
all_lab_layer <- list(
  ggplot2::geom_text(data = arrows, ggplot2::aes(tx, ty, label = lab, hjust = hj, vjust = vj),
                     size = lab_size, colour = "#1A1A1A", family = house_family()),
  ggplot2::geom_text(data = grp_lab, ggplot2::aes(x, y, label = group, hjust = hj, vjust = vj),
                     size = lab_size, colour = grp_lab$col, family = house_family())
)

p <- ggplot2::ggplot() +
  ggplot2::geom_hline(yintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["light"]]) +
  ggplot2::geom_vline(xintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["light"]]) +
  ggplot2::geom_segment(
    data = arrows,
    ggplot2::aes(x = 0, y = 0, xend = x, yend = y),
    arrow = grid::arrow(angle = 22, length = grid::unit(1.5, "mm"), type = "closed"),
    linewidth = pv_house_lw("main"),
    colour = "#1A1A1A"
  ) +
  ggplot2::geom_point(
    data = site_sc,
    ggplot2::aes(RDA1, RDA2, fill = group),
    shape = HOUSE_POINT$shape, size = 1.6,
    stroke = HOUSE_POINT$stroke, colour = HOUSE_POINT$colour
  ) +
  all_lab_layer +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::coord_equal(xlim = xlim_v, ylim = ylim_v, expand = FALSE) +
  ggplot2::scale_x_continuous(breaks = scales::breaks_pretty(n = 5)) +
  ggplot2::scale_y_continuous(breaks = scales::breaks_pretty(n = 3)) +
  ggplot2::labs(
    x = sprintf("RDA1 (%.1f%%)", pct[[1]]),
    y = sprintf("RDA2 (%.1f%%)", pct[[2]]),
    caption = footnote
  ) +
  theme_house() +
  ggplot2::theme(
    plot.caption = ggplot2::element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                         margin = ggplot2::margin(t = 0.8, unit = "mm")),
    plot.caption.position = "plot"
  )

pv_save_house(p, "figure", cells = "2x1")
message(sprintf("RDA1 %.1f%%  RDA2 %.1f%%", pct[[1]], pct[[2]]))
message("wrote preview.png")
