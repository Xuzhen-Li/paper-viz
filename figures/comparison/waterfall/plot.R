# Waterfall (house style): opening, signed steps, closing; value on every bar, bar classes as a
# coloured key and the net change written inside the panel (no legend). Reads data.csv only.
# Run from this directory. Pure ggplot2 (no waterfalls package).
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
bar_width <- 0.62
show_connectors <- TRUE
show_value_labels <- TRUE
label_size <- pv_pt2size(7)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$label <- factor(df$label, levels = unique(df$label))
n <- nrow(df)

ymin <- numeric(n)
ymax <- numeric(n)
fill_key <- character(n)
leave <- numeric(n)
running <- 0
for (i in seq_len(n)) {
  if (df$kind[i] == "total") {
    ymin[i] <- 0
    ymax[i] <- df$value[i]
    running <- df$value[i]
    fill_key[i] <- "Total"
  } else {
    start <- running
    end <- running + df$value[i]
    ymin[i] <- min(start, end)
    ymax[i] <- max(start, end)
    running <- end
    fill_key[i] <- if (df$value[i] >= 0) "Increase" else "Decrease"
  }
  leave[i] <- running
}

plot_df <- data.frame(
  label = df$label,
  xmin = as.numeric(df$label) - bar_width / 2,
  xmax = as.numeric(df$label) + bar_width / 2,
  ymin = ymin,
  ymax = ymax,
  fill_key = factor(fill_key, levels = c("Increase", "Decrease", "Total")),
  stringsAsFactors = FALSE
)

conn <- NULL
if (isTRUE(show_connectors) && n > 1) {
  conn <- data.frame(
    x = as.numeric(df$label[-n]) + bar_width / 2,
    xend = as.numeric(df$label[-1]) - bar_width / 2,
    y = leave[-n],
    yend = leave[-n]
  )
}

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# key and net change sit in the empty band under the steps
# green, red, blue: all >= 3:1 on white, so the key text keeps the bar colour
cols <- c(Increase = hp[["green"]], Decrease = hp[["red"]], Total = hp[["blue"]])
footnote <- "Simulated data for illustration; not biological results"
y_top <- max(plot_df$ymax) * 1.16
tot <- which(df$kind == "total")
net <- if (length(tot) >= 2) df$value[tot[length(tot)]] - df$value[tot[1]] else sum(df$value[df$kind != "total"])
key <- data.frame(k = factor(c("Increase", "Decrease", "Total"), levels = c("Increase", "Decrease", "Total")),
                  i = 1:3)

p <- ggplot() +
  geom_rect(data = plot_df, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill_key),
            colour = NA)
if (!is.null(conn)) {
  p <- p + geom_segment(data = conn, aes(x = x, xend = xend, y = y, yend = y),
                        linewidth = pv_house_lw("ref"), colour = grey[["mid"]], linetype = "22")
}
if (isTRUE(show_value_labels)) {
  lab_df <- plot_df
  lab_df$txt <- ifelse(df$kind == "total", sprintf("%.1f", df$value), sprintf("%+.1f", df$value))
  p <- p + geom_text(data = lab_df, aes(x = (xmin + xmax) / 2, y = ymax, label = txt), vjust = -0.4,
                     size = label_size, colour = "black")
}
p <- p +
  geom_text(data = key, aes(x = 1.55, y = y_top * (0.5 - 0.085 * (i - 1)), label = k, colour = k),
            hjust = 0, vjust = 1) +
  annotate("text", x = n - 0.55, y = y_top * 0.5, hjust = 1, vjust = 1,
           label = sprintf("Net change %+.1f", net)) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = as.numeric(df$label), labels = as.character(levels(df$label))) +
  scale_y_continuous(limits = c(0, y_top), expand = c(0, 0)) +
  coord_cartesian(xlim = c(0.45, n + 0.55), expand = FALSE) +
  labs(x = NULL, y = "Value", caption = footnote) +
  theme_house() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
