# Pseudotime trajectory (house style). Cells coloured by pseudotime (house_warm) or by branch;
# the median path per branch is drawn on top and each branch is named at its end.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# --- adjustable ---
color_by <- "pseudotime"  # "pseudotime" or "branch"
show_path <- TRUE
# ------------------
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$branch <- factor(df$branch, levels = c("trunk", "fate-a", "fate-b"))
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
bcols <- c("trunk" = grey[["dark"]], "fate-a" = hp[["blue"]], "fate-b" = hp[["red"]])

path_df <- do.call(rbind, lapply(split(df, df$branch), function(d) {
  d <- d[order(d$pseudotime), , drop = FALSE]
  if (nrow(d) < 12) return(NULL)
  bins <- cut(d$pseudotime, breaks = 8, include.lowest = TRUE)
  agg <- stats::aggregate(cbind(dim1, dim2, pseudotime) ~ bins, d, stats::median)
  agg$branch <- d$branch[1]
  agg
}))

p <- ggplot(df, aes(dim1, dim2))

if (color_by == "branch") {
  p <- p +
    geom_point(aes(fill = branch), shape = HOUSE_POINT$shape, size = 1.6,
               stroke = 0.2, colour = "white") +
    scale_fill_manual(values = bcols, guide = "none")
} else {
  p <- p +
    geom_point(aes(fill = pseudotime), shape = HOUSE_POINT$shape, size = 1.6,
               stroke = 0.2, colour = "white") +
    scale_fill_gradientn(colours = pv_palette("house_warm"), name = "Pseudotime",
                         limits = c(0, 1), breaks = c(0, 0.5, 1)) +
    guides(fill = guide_colourbar(title.position = "top", title.hjust = 0,
                                  barwidth = unit(14, "mm"), barheight = unit(2, "mm")))
}

if (isTRUE(show_path) && !is.null(path_df)) {
  ends <- do.call(rbind, lapply(split(path_df, path_df$branch), function(d) d[which.max(d$pseudotime), , drop = FALSE]))
  ends <- ends[ends$branch != "trunk", , drop = FALSE]
  # each branch name goes just outside its own cloud: above it when the branch ends high, else below
  start_y <- path_df$dim2[which.min(path_df$pseudotime)]
  cells_y <- split(df$dim2, df$branch)
  ends$up <- ends$dim2 >= start_y
  ends$dim2 <- ifelse(ends$up, vapply(as.character(ends$branch), function(b) max(cells_y[[b]]), 0),
                      vapply(as.character(ends$branch), function(b) min(cells_y[[b]]), 0))
  ends$vj <- ifelse(ends$up, -0.8, 1.8)
  p <- p + geom_path(data = path_df, aes(dim1, dim2, group = branch), colour = "#1A1A1A",
                     linewidth = pv_house_lw("main"), inherit.aes = FALSE) +
    geom_text(data = ends, aes(dim1, dim2, label = branch, vjust = vj), inherit.aes = FALSE,
              size = pv_pt2size(7), family = house_family(), colour = "#1A1A1A")
}

p <- p +
  scale_y_continuous(expand = expansion(mult = c(0.1, 0.1))) +
  labs(x = "Component 1", y = "Component 2", caption = footnote) +
  theme_house() +
  theme(legend.position = "inside", legend.position.inside = c(0.02, 0.02),
        legend.justification.inside = c(0, 0), legend.direction = "horizontal",
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
