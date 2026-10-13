# GSEA running-score curves with an optional ranked-list bar (house style). Each set is named in
# its colour at its peak score, with the peak ES written beside it. Panels joined with patchwork.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

sets_keep <- c("Interferon response", "Oxidative phosphorylation")
show_ranked_bar <- TRUE
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$set %in% sets_keep, , drop = FALSE]
df$set <- factor(df$set, levels = sets_keep)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- stats::setNames(unname(hp[c("blue", "red", "green", "purple", "magenta", "brown")][seq_along(sets_keep)]),
                       sets_keep)

# peak (largest |ES|) per set, labelled in the set colour
peaks <- do.call(rbind, lapply(split(df, df$set), function(d) d[which.max(abs(d$es)), , drop = FALSE]))
peaks$lab <- sprintf("%s\nES %.2f", peaks$set, peaks$es)
peaks$vj <- ifelse(peaks$es >= 0, -0.25, 1.25)
peaks$hj <- ifelse(peaks$rank > max(df$rank) / 2, 1, 0)

curve <- ggplot(df, aes(rank, es, colour = set)) +
  geom_hline(yintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_line(linewidth = pv_house_lw("main")) +
  geom_text(data = peaks, aes(label = lab, vjust = vj, hjust = hj), size = pv_pt2size(7),
            lineheight = 0.9, family = house_family(), show.legend = FALSE) +
  scale_colour_manual(values = pal, guide = "none") +
  scale_y_continuous(expand = expansion(mult = 0.3)) +
  labs(x = NULL, y = "Enrichment score") +
  theme_house() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

hits <- df[df$hit == 1, , drop = FALSE]
hits$y <- as.numeric(hits$set)
rug <- ggplot(hits, aes(colour = set)) +
  geom_segment(aes(x = rank, xend = rank, y = y - 0.32, yend = y + 0.32), linewidth = 0.25) +
  scale_colour_manual(values = pal, guide = "none") +
  scale_y_continuous(breaks = NULL, limits = c(0.4, length(sets_keep) + 0.6)) +
  labs(x = NULL, y = "Hits") +
  theme_house() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

met <- df[df$set == sets_keep[[1]], , drop = FALSE]
lim <- max(abs(met$metric))
bar <- ggplot(met, aes(rank, metric, fill = metric)) +
  geom_col(width = 1, colour = NA) +
  scale_fill_gradientn(colours = pv_palette("house_div"), limits = c(-lim, lim), guide = "none") +
  labs(x = "Rank in ordered gene list", y = "Rank metric") +
  theme_house()

if (isTRUE(show_ranked_bar) && length(sets_keep) > 1) {
  p <- curve / rug / bar + plot_layout(heights = c(1.4, 0.35, 0.55))
} else if (isTRUE(show_ranked_bar)) {
  p <- curve / bar + plot_layout(heights = c(1.4, 0.5))
} else {
  p <- curve
}
p <- p + plot_annotation(
  caption = footnote,
  theme = theme(text = element_text(family = house_family()),
                plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                            margin = margin(t = 0.8, unit = "mm")),
                plot.caption.position = "plot"))

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
