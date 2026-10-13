# OPLS-DA scores and permutation diagnostic (house style). Group names written next to each
# group; the permutation panel marks the observed Q2 and its permutation p. Panels joined with
# patchwork. Reads data.csv and data_perm.csv. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# --- adjustable ---
show_scores <- TRUE
show_permutation <- TRUE
show_ellipse <- TRUE
# ------------------
footnote <- "Simulated data for illustration; not biological results"

scores <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
perm <- utils::read.csv("data_perm.csv", stringsAsFactors = FALSE)
scores$group <- factor(scores$group, levels = unique(scores$group))
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- stats::setNames(unname(hp[seq_len(nlevels(scores$group))]), levels(scores$group))
name_cols <- stats::setNames(ifelse(cols %in% hp[c("orange", "sky", "gold")], "#1A1A1A", cols), names(cols))

panels <- list()

if (isTRUE(show_scores)) {
  labs_df <- do.call(rbind, lapply(levels(scores$group), function(g) {
    s <- scores[scores$group == g, , drop = FALSE]
    data.frame(group = g, pred = mean(range(s$pred)), ortho = max(s$ortho))
  }))
  p_scores <- ggplot(scores, aes(pred, ortho)) +
    geom_hline(yintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
    geom_vline(xintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
    geom_point(aes(fill = group), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
               stroke = HOUSE_POINT$stroke, colour = HOUSE_POINT$colour) +
    geom_text(data = labs_df, aes(label = group), vjust = -0.9, size = pv_pt2size(7),
              colour = name_cols[labs_df$group], family = house_family()) +
    scale_fill_manual(values = cols, guide = "none") +
    scale_colour_manual(values = cols, guide = "none") +
    scale_y_continuous(expand = expansion(mult = c(0.06, 0.16))) +
    labs(x = "Predictive component", y = "Orthogonal component") +
    theme_house()
  if (isTRUE(show_ellipse)) {
    p_scores <- p_scores + stat_ellipse(aes(colour = group), linewidth = pv_house_lw("main"),
                                        level = 0.8, show.legend = FALSE)
  }
  panels <- c(panels, list(p_scores))
}

if (isTRUE(show_permutation)) {
  obs <- perm$q2[perm$perm == 1]
  null <- perm[perm$perm != 1, , drop = FALSE]
  p_val <- (sum(null$q2 >= obs) + 1) / (nrow(null) + 1)
  p_perm <- ggplot(null, aes(q2)) +
    geom_histogram(bins = 18, fill = grey[["ci"]], colour = "white", linewidth = 0.15) +
    geom_vline(xintercept = obs, linetype = "dashed", linewidth = pv_house_lw("main"),
               colour = hp[["red"]]) +
    annotate("text", x = obs, y = Inf, vjust = 1.3, hjust = 1.08, size = pv_pt2size(7),
             colour = hp[["red"]], family = house_family(),
             label = sprintf("Observed Q2 %.2f\np = %s", obs, format(signif(p_val, 2)))) +
    scale_x_continuous(expand = expansion(mult = c(0.08, 0.12))) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.25))) +
    labs(x = "Q2 (permuted labels)", y = "Permutations") +
    theme_house()
  panels <- c(panels, list(p_perm))
}

if (length(panels) == 0) stop("enable show_scores or show_permutation")
p <- wrap_plots(panels, nrow = 1) +
  plot_annotation(
    caption = footnote,
    theme = theme(text = element_text(family = house_family()),
                  plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                              margin = margin(t = 0.8, unit = "mm")),
                  plot.caption.position = "plot")
  )

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
