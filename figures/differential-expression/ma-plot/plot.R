# MA plot (house style). Up red, down blue, others light grey; counts in the panel, top genes named.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# --- adjustable ---
lfc_cut <- 1
p_cut <- 0.01
show_labels <- TRUE
n_label <- 5   # more than about 5 names do not fit a 1x1 panel at 7 pt
# ------------------
footnote <- "Simulated data;\nnot biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$A <- log2(df$base_mean)
df$direction <- ifelse(
  df$pvalue >= p_cut | abs(df$log2fc) < lfc_cut, "ns",
  ifelse(df$log2fc > 0, "up", "down")
)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- c(ns = grey[["light"]], up = hp[["red"]], down = hp[["blue"]])
df <- df[order(df$direction != "ns"), , drop = FALSE]
n_up <- sum(df$direction == "up"); n_down <- sum(df$direction == "down")

p <- ggplot(df, aes(A, log2fc, colour = direction)) +
  geom_hline(yintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_hline(yintercept = c(-lfc_cut, lfc_cut), linetype = "dashed",
             linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_point(size = 0.7, shape = 16) +
  annotate("text", x = Inf, y = Inf, hjust = 1.08, vjust = 1.3, label = paste("Up", n_up),
           colour = hp[["red"]], size = pv_pt2size(7), family = house_family()) +
  annotate("text", x = Inf, y = -Inf, hjust = 1.08, vjust = -0.5, label = paste("Down", n_down),
           colour = hp[["blue"]], size = pv_pt2size(7), family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.22, 0.24))) +
  labs(x = "log2 mean expression", y = "log2 fold change", caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(1, 1.5, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_labels) && n_label > 0) {
  lab <- df[df$direction != "ns", , drop = FALSE]
  lab <- lab[order(lab$pvalue, -abs(lab$log2fc)), , drop = FALSE]
  lab <- utils::head(lab, n_label)
  # Every point is a repel obstacle (blank label), so names avoid the whole cloud;
  # names are pushed away from zero, into the space beyond the point cloud.
  rep_df <- df
  rep_df$lab_txt <- ifelse(rep_df$gene %in% lab$gene, rep_df$gene, "")
  span <- diff(range(df$log2fc))
  rep_df$ny <- ifelse(rep_df$lab_txt == "", 0, sign(rep_df$log2fc) * 0.25 * span)
  # labelled genes get the house point outline
  p <- p + geom_point(data = lab, aes(fill = direction), shape = HOUSE_POINT$shape, size = 1.2,
                      stroke = HOUSE_POINT$stroke, colour = HOUSE_POINT$colour, show.legend = FALSE) +
    scale_fill_manual(values = cols, guide = "none") +
    ggrepel::geom_text_repel(
    data = rep_df, aes(label = lab_txt), size = pv_pt2size(7), colour = "#1A1A1A",
    family = house_family(), segment.size = 0.2, segment.colour = grey[["dark"]],
    nudge_y = rep_df$ny, direction = "both", point.size = 0.7,
    max.overlaps = Inf, min.segment.length = 0, box.padding = 0.25, point.padding = 0.15,
    force = 3, force_pull = 0.3, max.iter = 50000, max.time = 4, show.legend = FALSE, seed = 1
  )
}

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
