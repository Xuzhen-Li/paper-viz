# NMDS from a Bray-Curtis matrix (house style). Group names written next to each group; the
# stress value sits in the panel corner. Reads data.csv only. Run from this directory.
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
nm <- MASS::isoMDS(bray(mat), k = 2, trace = FALSE)
plot_df <- data.frame(x = nm$points[, 1], y = nm$points[, 2], group = group)
stress <- nm$stress / 100   # isoMDS reports stress in percent

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
lv <- unique(as.character(plot_df$group))
plot_df$group <- factor(plot_df$group, levels = lv)
cols <- stats::setNames(unname(hp[seq_along(lv)]), lv)
# group names written on white: the group colour when it is >= 3:1 on white, else #1A1A1A
name_cols <- stats::setNames(ifelse(cols %in% hp[c("orange", "sky", "gold")], "#1A1A1A", cols), names(cols))
# direct labels: each name sits centred just above its group's highest point
# Each name starts above or below its group, whichever side has fewer points of the
# other groups nearby; ggrepel then clears it from every point.
yr <- diff(range(plot_df$y)); xr <- diff(range(plot_df$x))
labs_df <- do.call(rbind, lapply(lv, function(g) {
  s <- plot_df[plot_df$group == g, , drop = FALSE]
  o <- plot_df[plot_df$group != g, , drop = FALSE]
  top <- s[which.max(s$y), ]; bot <- s[which.min(s$y), ]
  crowd <- function(px, py) sum(abs(o$x - px) < 0.15 * xr & abs(o$y - py) < 0.15 * yr)
  up <- crowd(top$x, top$y + 0.1 * yr) <= crowd(bot$x, bot$y - 0.1 * yr)
  a <- if (up) top else bot
  data.frame(group = g, x = a$x, y = a$y, dir = if (up) 1 else -1)
}))
rep_df <- rbind(
  data.frame(x = labs_df$x, y = labs_df$y, lab = labs_df$group, col = unname(name_cols[labs_df$group]),
             ny = 0.07 * yr * labs_df$dir),
  data.frame(x = plot_df$x, y = plot_df$y, lab = "", col = "#1A1A1A", ny = 0)
)

p <- ggplot(plot_df, aes(x, y, fill = group)) +
  geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             colour = HOUSE_POINT$colour) +
  # Names repel from every point (blank labels are obstacles), starting just above the group.
  # Fixed seed and iteration cap, no time cap (ggrepel defaults max.time to 0.5 s),
  # so the layout does not depend on machine speed.
  ggrepel::geom_text_repel(
    data = rep_df, aes(x, y, label = lab), inherit.aes = FALSE, colour = rep_df$col,
    size = pv_pt2size(7), family = house_family(), point.size = HOUSE_POINT$size,
    nudge_y = rep_df$ny, min.segment.length = Inf, box.padding = 0.2, point.padding = 0.15,
    force = 2, max.overlaps = Inf, max.iter = 20000, max.time = Inf, seed = 1, show.legend = FALSE
  ) +
  annotate("text", x = Inf, y = Inf, hjust = 1.06, vjust = 1.3, label = sprintf("Stress %.3f", stress),
           colour = "#1A1A1A", size = pv_pt2size(7), family = house_family()) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.16, 0.16))) +
  scale_x_continuous(expand = expansion(mult = 0.08)) +
  labs(x = "NMDS1", y = "NMDS2", caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(1, 1.5, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
