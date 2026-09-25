# Venn diagram for two or three sets, counts or element labels.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

n_sets <- 3
show_labels <- FALSE
set_levels <- c("RNA-seq", "Proteome", "ChIP")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
use <- set_levels[seq_len(min(n_sets, length(set_levels)))]
df <- df[df$set %in% use, , drop = FALSE]
lst <- lapply(use, function(s) unique(df$id[df$set == s]))
names(lst) <- use
pal <- pv_palette("categorical", length(use))

p <- ggvenn::ggvenn(
  lst,
  show_stats = "c",
  show_elements = isTRUE(show_labels),
  digits = 0,
  fill_color = pal,
  fill_alpha = 0.45,
  stroke_color = "grey25",
  stroke_size = 0.35,
  set_name_size = 3.4,
  text_size = 2.8
) +
  ggplot2::labs(title = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.line = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank()
  )

pv_save(p, "figure", width_mm = 120, height_mm = 110)
message("wrote preview.png")
