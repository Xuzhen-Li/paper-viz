# STAMP-style mean-difference bars with 95% CI (house style). Taxa higher in B in red, higher in A
# in blue (named in the panel corners); filled points have p below p_cut, open points do not;
# the p value is written at the right. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
p_cut <- 0.05
show_ci <- TRUE
label_p <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$taxon <- factor(df$taxon, levels = df$taxon[order(df$diff)])
df$direction <- ifelse(df$diff >= 0, "higher in B", "higher in A")
df$sig <- df$p < p_cut
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- c("higher in A" = hp[["blue"]], "higher in B" = hp[["red"]])
df$fill <- ifelse(df$sig, cols[df$direction], "white")
footnote <- sprintf("Filled points: p < %s. Simulated data for illustration; not biological results", p_cut)

p <- ggplot(df, aes(diff, taxon, colour = direction)) +
  geom_vline(xintercept = 0, linewidth = pv_house_lw("ref"), colour = grey[["ref"]])
if (isTRUE(show_ci)) {
  p <- p + geom_errorbar(aes(xmin = low, xmax = high), orientation = "y", width = 0.3,
                         linewidth = pv_house_lw("main"))
}
p <- p +
  geom_point(aes(fill = I(fill)), shape = 21, size = 1.8, stroke = 0.5) +
  annotate("text", x = -Inf, y = Inf, hjust = -0.05, vjust = -0.6, label = "Higher in A",
           colour = hp[["blue"]], size = pv_pt2size(7), family = house_family()) +
  annotate("text", x = Inf, y = Inf, hjust = 1.05, vjust = -0.6, label = "Higher in B",
           colour = hp[["red"]], size = pv_pt2size(7), family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  coord_cartesian(xlim = range(c(df$low, df$high)), clip = "off") +
  labs(x = "Mean proportion difference (B - A)", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(4, 1.5, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")
if (isTRUE(label_p)) {
  x_p <- max(df$high) + 0.1 * diff(range(c(df$low, df$high)))   # just right of the panel
  p <- p +
    geom_text(aes(x = x_p, label = ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))), colour = "#1A1A1A",
              size = pv_pt2size(7), hjust = 0, family = house_family()) +
    annotate("text", x = x_p, y = Inf, hjust = 0, vjust = -0.6, label = "p",
             colour = "#1A1A1A", size = pv_pt2size(7), family = house_family()) +
    theme(plot.margin = margin(4, 10, 1, 1, "mm"))
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
