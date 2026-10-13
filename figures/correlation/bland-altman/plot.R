# Bland-Altman (house style): mean vs difference, bias and limits of agreement as labelled lines.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
point_size <- 1.6         # 160 points: smaller shape-21 points, alpha 0.7 (STYLE §5)
loa_mult <- 1.96          # limits of agreement multiplier (SD)
show_loa_labels <- TRUE   # value labels on the bias and LoA lines

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
ba <- data.frame(mean = (df$method_a + df$method_b) / 2, diff = df$method_a - df$method_b)
bias <- mean(ba$diff)
sd_d <- stats::sd(ba$diff)
loa_hi <- bias + loa_mult * sd_d
loa_lo <- bias - loa_mult * sd_d
inside <- mean(ba$diff >= loa_lo & ba$diff <= loa_hi)

pal <- pv_palette("house"); grey <- pv_palette("house_grey")
pt_fill <- pal[["blue"]]       # points
bias_col <- pal[["red"]]       # bias line + label (5.2:1 on white)
loa_col <- grey[["ref"]]       # LoA lines + labels (4.6:1 on white)
footnote <- "Simulated data for illustration; not biological results"

x_lim <- c(floor(min(ba$mean) / 5) * 5, ceiling(max(ba$mean) / 5) * 5)
y_lim <- c(min(ba$diff, loa_lo) - 2.5, max(ba$diff, loa_hi) + 2.5)

p <- ggplot(ba, aes(mean, diff)) +
  geom_hline(yintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["ci"]]) +
  geom_hline(yintercept = c(loa_lo, loa_hi), linewidth = pv_house_lw("ref"), linetype = "22",
             colour = loa_col) +
  geom_hline(yintercept = bias, linewidth = pv_house_lw("main"), colour = bias_col) +
  geom_point(shape = HOUSE_POINT$shape, size = point_size, stroke = HOUSE_POINT$stroke,
             colour = "black", fill = pt_fill, alpha = 0.7) +
  annotate("text", x = x_lim[1] + 1, y = y_lim[1] + 0.6, hjust = 0, vjust = 0,
           label = sprintf("n = %d; %.0f%% within limits", nrow(ba), 100 * inside)) +
  coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE, clip = "off") +
  labs(x = "Mean of methods ((A + B) / 2)", y = "Difference (A - B)", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot",
        plot.margin = margin(1.6, if (isTRUE(show_loa_labels)) 12 else 0.8, 0.9, 0.4, "mm"))

if (isTRUE(show_loa_labels)) {
  lab <- data.frame(y = c(bias, loa_hi, loa_lo), col = c(bias_col, loa_col, loa_col),
                    label = c(sprintf("Bias\n%.2f", bias),
                              sprintf("+%.2f SD\n%.2f", loa_mult, loa_hi),
                              sprintf("-%.2f SD\n%.2f", loa_mult, loa_lo)))
  # line-end labels just right of the frame, same colour as their line
  p <- p + geom_text(data = lab, aes(x = x_lim[2] + 0.02 * diff(x_lim), y = y, label = label, colour = col),
                     hjust = 0, lineheight = 0.9) +
    scale_colour_identity()
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
