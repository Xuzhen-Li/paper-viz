# Sequence logo. Letter height is frequency times information, stacked small to large.
source("../../../styles/r/theme_viz.R")

method <- "bits"
base_levels <- c("A", "C", "G", "T")
# Closest house colours: green, blue, orange, red.
base_cols <- c(A = "#518B60", C = "#2A629A", G = "#D98324", T = "#C75050")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$base <- factor(df$base, levels = base_levels)
mat <- xtabs(count ~ base + pos, df)
mat <- mat[base_levels, , drop = FALSE]
cs <- ggseqlogo::make_col_scheme(chars = base_levels, cols = unname(base_cols))
y_top <- if (method == "prob") 1 else 2
y_lab <- if (method == "prob") "Probability" else "Information (bits)"

p <- ggplot2::ggplot() +
  ggseqlogo::geom_logo(
    mat,
    method = method,
    seq_type = "dna",
    col_scheme = cs,
    stack_width = 0.78
  ) +
  ggplot2::scale_x_continuous(breaks = sort(unique(df$pos)), expand = ggplot2::expansion(add = 0.4)) +
  ggplot2::scale_y_continuous(limits = c(0, y_top), expand = ggplot2::expansion(mult = c(0, 0.02))) +
  ggplot2::labs(x = "Position in motif", y = y_lab) +
  theme_viz() +
  ggplot2::theme(
    legend.position = "none",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

pv_save(p, "figure", width_mm = 183, height_mm = 72)
message("wrote preview.png")
