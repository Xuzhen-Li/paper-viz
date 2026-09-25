# aDNA damage: 5' C>T and 3' G>A by library.
source("../../../styles/r/theme_viz.R")

show_ct <- TRUE
show_ga <- TRUE
libraries_keep <- c("no-UDG", "half-UDG")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$library %in% libraries_keep, , drop = FALSE]
if (!isTRUE(show_ct)) df <- df[df$substitution != "C>T", , drop = FALSE]
if (!isTRUE(show_ga)) df <- df[df$substitution != "G>A", , drop = FALSE]

df$end <- factor(df$end, levels = c("5'", "3'"))
df$library <- factor(df$library, levels = libraries_keep)
sub_cols <- c("C>T" = "#D55E00", "G>A" = "#0072B2")

p <- ggplot2::ggplot(df, ggplot2::aes(pos, rate, colour = substitution)) +
  ggplot2::geom_line(linewidth = 0.4) +
  ggplot2::geom_point(size = 0.7) +
  ggplot2::facet_grid(library ~ end) +
  ggplot2::scale_colour_manual(values = sub_cols, name = NULL) +
  ggplot2::scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 25)) +
  ggplot2::scale_y_continuous(limits = c(0, 0.38), expand = ggplot2::expansion(mult = c(0, 0.04))) +
  ggplot2::labs(x = "Position from read end (bp)", y = "Substitution frequency") +
  theme_viz() +
  ggplot2::theme(
    legend.position = "bottom",
    legend.key.size = ggplot2::unit(3, "mm"),
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 6.5)
  )

pv_save(p, "figure", width_mm = 160, height_mm = 100)
message("wrote preview.png")
