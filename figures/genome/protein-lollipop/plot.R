# Protein lollipop. Domains sit under the stems. Reads data.csv and data_domains.csv.
source("../../../styles/r/theme_viz.R")

show_domains <- TRUE
class_levels <- c("Missense", "Nonsense", "Frameshift", "Inframe")
class_cols <- c(
  Missense = "#0072B2",
  Nonsense = "#D55E00",
  Frameshift = "#009E73",
  Inframe = "#CC79A7"
)
domain_cols <- c(
  SP = "#6B6B6B", LBD = "#0072B2", Fn3 = "#56B4E9", TM = "#1e3a5f",
  JM = "#E69F00", Kinase = "#D55E00", "C-lobe" = "#009E73", PEST = "#CC79A7"
)

mut <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
dom <- utils::read.csv("data_domains.csv", stringsAsFactors = FALSE)
mut$class <- factor(mut$class, levels = class_levels)
dom$domain <- factor(dom$domain, levels = names(domain_cols))
prot_end <- max(c(dom$end, mut$pos))
ymax <- max(mut$n)
dom$label <- ifelse(dom$end - dom$start >= 36, as.character(dom$domain), "")

p <- ggplot2::ggplot() +
  ggplot2::geom_segment(
    data = mut,
    ggplot2::aes(x = pos, xend = pos, y = 0, yend = n, colour = class),
    linewidth = 0.3
  ) +
  ggplot2::geom_point(
    data = mut,
    ggplot2::aes(pos, n, colour = class),
    size = 1.7
  ) +
  ggplot2::scale_colour_manual(values = class_cols, name = "Mutation") +
  ggplot2::scale_x_continuous(
    limits = c(0, prot_end),
    expand = c(0, 0),
    breaks = seq(0, prot_end, by = 100)
  ) +
  ggplot2::scale_y_continuous(
    breaks = seq(0, ymax + 2, by = 4),
    expand = ggplot2::expansion(mult = c(0.02, 0.08))
  ) +
  ggplot2::labs(x = "Amino acid position", y = "Mutated samples") +
  theme_viz() +
  ggplot2::theme(
    legend.position = "bottom",
    legend.box = "vertical",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

if (isTRUE(show_domains)) {
  p <- p +
    ggplot2::geom_rect(
      data = dom,
      ggplot2::aes(xmin = start, xmax = end, ymin = -0.22 * ymax, ymax = -0.05 * ymax, fill = domain),
      colour = "white", linewidth = 0.2
    ) +
    ggplot2::geom_text(
      data = dom,
      ggplot2::aes(x = (start + end) / 2, y = -0.135 * ymax, label = label),
      size = 1.7, colour = "white"
    ) +
    ggplot2::scale_fill_manual(values = domain_cols, name = "Domain") +
    ggplot2::coord_cartesian(ylim = c(-0.28 * ymax, ymax * 1.08), clip = "off")
}

pv_save(p, "figure", width_mm = 183, height_mm = 78)
message("wrote preview.png")
