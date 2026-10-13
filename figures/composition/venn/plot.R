# Venn diagram (house style) for two or three sets, counts or element labels.
# Set names take the set colour when it is >= 3:1 on white, else #1A1A1A. Text is 7 pt.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

n_sets <- 3
show_labels <- FALSE
set_levels <- c("RNA-seq", "Proteome", "ChIP")
footnote <- "Simulated data;\nnot biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
use <- set_levels[seq_len(min(n_sets, length(set_levels)))]
df <- df[df$set %in% use, , drop = FALSE]
lst <- lapply(use, function(s) unique(df$id[df$set == s]))
names(lst) <- use
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- unname(hp[seq_along(use)])
name_col <- ifelse(pal %in% hp[c("orange", "sky", "gold")], "#1A1A1A", pal)

p <- ggvenn::ggvenn(
  lst,
  show_stats = "c",
  show_elements = isTRUE(show_labels),
  digits = 0,
  fill_color = pal,
  fill_alpha = 0.35,
  stroke_color = grey[["dark"]],
  stroke_size = pv_house_lw("frame"),
  set_name_color = name_col,
  set_name_size = pv_pt2size(7),
  text_color = "#1A1A1A",
  text_size = pv_pt2size(7)
) +
  coord_fixed(clip = "off") +
  labs(title = NULL, caption = footnote) +
  theme_house() +
  theme(axis.line = element_blank(), panel.border = element_blank(),
        axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks = element_blank(), axis.title.x = element_blank(), axis.title.y = element_blank(),
        plot.margin = margin(1, 1, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

# ggvenn draws its labels without a font family; they inherit the house font from this wrapper
g <- grid::grobTree(ggplotGrob(p), gp = grid::gpar(fontfamily = house_family()))
pv_save_house(g, "figure", cells = "1x1")
message("wrote preview.png")
