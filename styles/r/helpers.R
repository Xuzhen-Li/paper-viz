# Small ggplot helpers — pair with theme_viz.R
# See coding/r/visualization/ for full recipes.

despine_gg <- function() {
  ggplot2::theme(
    axis.line.x = ggplot2::element_line(),
    axis.line.y = ggplot2::element_line(),
    panel.border = ggplot2::element_blank()
  )
}

panel_tag <- function(tag) {
  list(ggplot2::labs(tag = tag))
}
