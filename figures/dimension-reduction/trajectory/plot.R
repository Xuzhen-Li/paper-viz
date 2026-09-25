# Pseudotime trajectory. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
color_by <- "pseudotime"  # "pseudotime" or "branch"
show_path <- TRUE
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$branch <- factor(df$branch, levels = c("trunk", "fate-a", "fate-b"))

path_df <- do.call(rbind, lapply(split(df, df$branch), function(d) {
  d <- d[order(d$pseudotime), , drop = FALSE]
  if (nrow(d) < 12) return(NULL)
  bins <- cut(d$pseudotime, breaks = 8, include.lowest = TRUE)
  agg <- stats::aggregate(cbind(dim1, dim2, pseudotime) ~ bins, d, stats::median)
  agg$branch <- d$branch[1]
  agg
}))

p <- ggplot2::ggplot(df, ggplot2::aes(dim1, dim2))

if (color_by == "branch") {
  cols <- c("trunk" = "#6B6B6B", "fate-a" = pv_palette("categorical", 2)[1], "fate-b" = pv_palette("categorical", 4)[4])
  p <- p +
    ggplot2::geom_point(ggplot2::aes(colour = branch), size = 1.15, alpha = 0.85) +
    ggplot2::scale_colour_manual(values = cols, name = "Branch")
} else {
  p <- p +
    ggplot2::geom_point(ggplot2::aes(colour = pseudotime), size = 1.15, alpha = 0.85) +
    ggplot2::scale_colour_gradientn(colours = pv_palette("sequential"), name = "Pseudotime")
}

if (isTRUE(show_path) && !is.null(path_df)) {
  p <- p + ggplot2::geom_path(
    data = path_df,
    ggplot2::aes(dim1, dim2, group = branch),
    colour = "black",
    linewidth = 0.4,
    inherit.aes = FALSE
  )
}

p <- p + ggplot2::labs(x = "Component 1", y = "Component 2") + theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 78)
message("wrote preview.png")
