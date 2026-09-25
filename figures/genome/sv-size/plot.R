# SV size densities on a log10 axis, coloured by type.
source("../../../styles/r/theme_viz.R")

log_x <- TRUE
sv_keep <- c("DEL", "INS", "DUP", "INV")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$sv_type %in% sv_keep, , drop = FALSE]
df$sv_type <- factor(df$sv_type, levels = sv_keep)
cols <- setNames(pv_palette("categorical", 4), sv_keep)

p <- ggplot2::ggplot(df, ggplot2::aes(size_bp, colour = sv_type, fill = sv_type)) +
  ggplot2::geom_density(alpha = 0.18, linewidth = 0.4) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::labs(x = "SV size", y = "Density") +
  theme_viz() +
  ggplot2::theme(legend.key.size = ggplot2::unit(3, "mm"))

if (isTRUE(log_x)) {
  p <- p + ggplot2::scale_x_log10(
    breaks = c(100, 1e3, 1e4, 1e5, 1e6, 1e7),
    labels = c("100 bp", "1 kb", "10 kb", "100 kb", "1 Mb", "10 Mb")
  )
}

pv_save(p, "figure", width_mm = 160, height_mm = 80)
message("wrote preview.png")
