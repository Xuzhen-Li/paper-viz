# f-statistics / D point ranges (house style): one row per test, |Z| >= z_cut in colour (blue
# positive, red negative), others grey; the class key is written in the panel. Example numbers are
# on the D scale. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_ci <- TRUE
z_cut <- 3
statistic <- "D"
order_by_estimate <- TRUE
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  # below 3:1, use the darker step of the same hue where one exists in the house palettes
  # (orange -> chrom12 orange #E17927, 3.01:1); otherwise #1A1A1A
  darker <- c("#E17D52" = "#E17927", "#F77E12" = "#E17927")
  up <- toupper(hex)
  stats::setNames(ifelse(ratio >= 3, hex, ifelse(up %in% names(darker), darker[up], "#1A1A1A")),
                  names(hex))
}
caption_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                                   lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
                       plot.caption.position = "plot")
# push end-of-line label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  shift <- mean(z) - mean(y[o]); z <- z - shift
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}
# fixed house colour per population (same in every B2 figure)
pop_cols <- c("Wild N" = hp[["blue"]], "Wild S" = hp[["sky"]], "Landrace E" = hp[["green"]],
              "Landrace W" = hp[["gold"]], "Cultivar A" = hp[["red"]], "Cultivar B" = hp[["purple"]])

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$class <- ifelse(abs(df$z) < z_cut, "ns", ifelse(df$estimate >= 0, "positive", "negative"))
if (isTRUE(order_by_estimate)) {
  df$test <- factor(df$test, levels = df$test[order(df$estimate)])
}
cols <- c(positive = hp[["blue"]], negative = hp[["red"]], ns = grey[["ci"]])
key_txt <- c(positive = sprintf("Z >= %g", z_cut), negative = sprintf("Z <= -%g", z_cut),
             ns = sprintf("|Z| < %g", z_cut))
key_col <- c(text_col(cols[c("positive", "negative")]), ns = grey[["mid"]])
x_lab <- switch(statistic, f3 = "f3 statistic", f4 = "f4 statistic", "D statistic")
n_test <- nlevels(factor(df$test))

p <- ggplot(df, aes(estimate, test, colour = class)) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = pv_house_lw("ref"), colour = grey[["ref"]])
if (isTRUE(show_ci)) {
  p <- p + geom_errorbar(aes(xmin = low, xmax = high), width = 0.35, linewidth = pv_house_lw("minor"),
                         orientation = "y")
}
p <- p +
  geom_point(size = 1.3, shape = 16) +
  # class key, top-left of the panel (the largest estimates sit at the top right)
  annotate("text", x = -Inf, y = n_test + 0.2 - (0:2) * 1.4, label = paste0("  ", key_txt[c("positive", "negative", "ns")]),
           colour = key_col[c("positive", "negative", "ns")], hjust = 0, vjust = 1,
           size = pv_pt2size(7), family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(labels = function(x) format(x, trim = TRUE), expand = expansion(mult = c(0.32, 0.05))) +
  labs(x = x_lab, y = NULL, caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
