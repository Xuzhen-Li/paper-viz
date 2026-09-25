# ADMIXTURE stacked bars. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
k_values <- 2:6
sort_k <- 4
pop_gap <- 3
pop_order <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
sub <- df[df$k == sort_k, ]
means <- aggregate(q ~ pop + ancestry, sub, mean)
dom <- do.call(rbind, lapply(split(means, means$pop), function(m) m[which.max(m$q), ]))
key <- merge(sub, dom[, c("pop", "ancestry")], by = c("pop", "ancestry"))
key <- key[order(match(key$pop, pop_order), -key$q), ]
pos <- data.frame(sample = key$sample, pop = key$pop, stringsAsFactors = FALSE)
pos$pop <- factor(pos$pop, levels = pop_order)
pos$within <- ave(seq_len(nrow(pos)), pos$pop, FUN = seq_along)
n_max <- max(pos$within)
pos$x <- pos$within + (as.integer(pos$pop) - 1) * (n_max + pop_gap)
mids <- aggregate(x ~ pop, pos, mean)

plot_df <- merge(df[df$k %in% k_values, ], pos[, c("sample", "x")], by = "sample")
plot_df$k_lab <- factor(paste0("K = ", plot_df$k), levels = paste0("K = ", k_values))
anc_levels <- paste0("A", seq_len(max(k_values)))
plot_df$ancestry <- factor(plot_df$ancestry, levels = anc_levels)
pal <- pv_palette("categorical", 6)
names(pal) <- anc_levels

p <- ggplot2::ggplot(plot_df, ggplot2::aes(x, q, fill = ancestry)) +
  ggplot2::geom_col(width = 1, colour = NA, linewidth = 0) +
  ggplot2::facet_grid(k_lab ~ .) +
  ggplot2::scale_fill_manual(values = pal, name = "Ancestry", drop = TRUE) +
  ggplot2::scale_x_continuous(
    breaks = mids$x, labels = as.character(mids$pop),
    expand = ggplot2::expansion(add = 0.8)
  ) +
  ggplot2::scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.5, 1)) +
  ggplot2::labs(x = NULL, y = "Ancestry proportion") +
  theme_viz() +
  ggplot2::theme(
    legend.key = ggplot2::element_blank(),
    legend.key.size = ggplot2::unit(3.2, "mm"),
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 6.5, hjust = 0),
    panel.spacing.y = ggplot2::unit(1.2, "mm"),
    axis.ticks.x = ggplot2::element_blank()
  )

pv_save(p, "figure", width_mm = 183, height_mm = 130)
message("wrote preview.png")
