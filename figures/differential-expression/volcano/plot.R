# Volcano (house style). Up red, down blue, others light grey; counts written in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

lfc_cut <- 1
p_cut <- 0.01
footnote <- "Simulated data;\nnot biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$nlp <- -log10(df$pvalue)
df$direction <- ifelse(
  df$pvalue >= p_cut | abs(df$log2_fold_change) < lfc_cut, "ns",
  ifelse(df$log2_fold_change > 0, "up", "down")
)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- c(ns = grey[["light"]], up = hp[["red"]], down = hp[["blue"]])
df <- df[order(df$direction != "ns"), , drop = FALSE]   # significant points on top
n_up <- sum(df$direction == "up"); n_down <- sum(df$direction == "down")

p <- ggplot(df, aes(log2_fold_change, nlp, colour = direction)) +
  geom_vline(xintercept = c(-lfc_cut, lfc_cut), linetype = "dashed",
             linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_hline(yintercept = -log10(p_cut), linetype = "dashed",
             linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_point(size = 0.7, shape = 16) +
  annotate("text", x = -Inf, y = Inf, hjust = -0.08, vjust = 1.3, label = paste("Down", n_down),
           colour = hp[["blue"]], size = pv_pt2size(7), family = house_family()) +
  annotate("text", x = Inf, y = Inf, hjust = 1.08, vjust = 1.3, label = paste("Up", n_up),
           colour = hp[["red"]], size = pv_pt2size(7), family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.12))) +
  labs(x = "log2 fold change", y = "-log10(p)", caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(1, 1.5, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
