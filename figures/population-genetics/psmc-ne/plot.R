# Effective population size through time on log-log axes (house style), with bootstrap ribbons;
# population names written next to their curves. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
# psmc: classic range (unreliable below ~10 ka). smcpp: includes more recent time.
model <- "psmc"
show_ribbon <- TRUE
pops_show <- c("Wild N", "Cultivar A")
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
df <- df[df$pop %in% pops_show, ]
df$pop <- factor(df$pop, levels = pops_show)
cols <- pop_cols[pops_show]
xlim <- if (model == "smcpp") c(2e3, 5e5) else c(1e4, 1e6)
short <- function(x, unit) paste0(c("1", "10", "100", "1")[match(x, c(1e3, 1e4, 1e5, 1e6))],
                                   ifelse(x < 1e6, unit[1], unit[2]))

# each name sits at the recent (left) end of the window, above or below its curve: the higher
# curve gets its name above, the others below
vis <- df[df$years_ago >= xlim[1] & df$years_ago <= xlim[2], ]
left <- do.call(rbind, lapply(split(vis, vis$pop, drop = TRUE), function(d) d[which.min(d$years_ago), ]))
left$above <- left$ne == max(left$ne)
left$y <- ifelse(left$above, left$ne_high * 1.25, left$ne_low / 1.25)

p <- ggplot(df, aes(years_ago, ne, colour = pop, fill = pop))
if (isTRUE(show_ribbon)) {
  p <- p + geom_ribbon(aes(ymin = ne_low, ymax = ne_high), alpha = 0.18, colour = NA)
}
p <- p +
  geom_line(linewidth = pv_house_lw("main")) +
  annotate("text", x = xlim[1] * 1.15, y = left$y, label = as.character(left$pop), hjust = 0,
           vjust = ifelse(left$above, 0, 1), colour = text_col(cols)[as.character(left$pop)],
           size = pv_pt2size(7), family = house_family()) +
  scale_x_log10(breaks = c(1e3, 1e4, 1e5, 1e6), labels = function(x) short(x, c(" ka", " Ma"))) +
  scale_y_log10(breaks = c(1e3, 1e4, 1e5, 1e6), labels = function(x) short(x, c("k", "M"))) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  coord_cartesian(xlim = xlim) +
  labs(x = "Time before present", y = "Effective size (Ne)", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
