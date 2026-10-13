# Cleveland dot plot (house style): categories sorted by one group, a grey guide from min to max in
# each row, group names as a coloured key and the count of rows where the first group is higher,
# both inside the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
sort_by_group <- "Urban"   # which group drives category order
show_segment <- TRUE       # light guide from min to max within row
point_size <- HOUSE_POINT$size
group_levels <- c("Urban", "Rural")

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue and red are both >= 3:1 on white, so the key keeps the point colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]])[seq_along(group_levels)],
                        group_levels)
footnote <- "Simulated data for\nillustration; not\nbiological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
ord_vals <- df$value[df$group == sort_by_group]
names(ord_vals) <- df$category[df$group == sort_by_group]
cat_order <- names(sort(ord_vals, decreasing = FALSE))
df$category <- factor(df$category, levels = cat_order)
df$y <- as.numeric(df$category)
seg <- do.call(rbind, lapply(split(df, df$category), function(d) {
  data.frame(y = d$y[1], xmin = min(d$value), xmax = max(d$value))
}))
w <- tapply(df$value, list(df$category, df$group), sum)
n_hi <- sum(w[, group_levels[1]] > w[, group_levels[2]])
n_cat <- nlevels(df$category)
x_lim <- range(df$value) + c(-0.05, 0.05) * diff(range(df$value))
key <- data.frame(group = factor(group_levels, levels = group_levels), i = seq_along(group_levels))

p <- ggplot()
if (isTRUE(show_segment)) {
  p <- p + geom_segment(data = seg, aes(x = xmin, xend = xmax, y = y, yend = y),
                        linewidth = pv_house_lw("minor"), colour = grey[["ci"]])
}
p <- p +
  geom_point(data = df, aes(value, y, fill = group), shape = HOUSE_POINT$shape, size = point_size,
             stroke = HOUSE_POINT$stroke, colour = "black") +
  geom_text(data = key, aes(x = x_lim[2] - 0.02 * diff(x_lim), y = 1.75 + 0.5 * (nrow(key) - i + 1), label = group,
                            colour = group), hjust = 1, vjust = 0) +
  annotate("text", x = x_lim[2] - 0.02 * diff(x_lim), y = 0.6, hjust = 1, vjust = 0, lineheight = 0.95,
           label = sprintf("%s higher\nin %d of %d", group_levels[1], n_hi, n_cat)) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(breaks = seq_len(n_cat), labels = levels(df$category)) +
  coord_cartesian(xlim = x_lim, ylim = c(0.4, n_cat + 0.6), expand = FALSE) +
  labs(x = "Score", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x2")
message("wrote preview.png")
