# Cumulative publication count over time with event markers (house style): one step line per
# topic (running total of the yearly counts), the topic name and final total at the line end, and
# dated events as dashed vertical lines labelled at the top of the panel.
# Reads data.csv and data_events.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
cumulative <- TRUE            # FALSE: plot the yearly counts instead of the running total
as_step <- TRUE               # step line (counts change once a year); FALSE: straight segments
show_events <- TRUE           # dashed lines and labels from data_events.csv
event_rows <- 3               # at most this many label rows at the top (used only when labels would collide)
show_event_year <- FALSE      # TRUE: write "2006 Method X released"; the x axis already gives the year
show_end_labels <- TRUE       # topic name and final value at the right end of each line
x_break_step <- 5             # years between x ticks
fig_cells <- "3x1"            # house grid cells (135 x 43 mm)
y_label <- "Cumulative publications"
footnote <- "Simulated data; not a real literature search"

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green: all >= 3:1 on white, so end labels keep the line colour
line_cols <- c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["brown"]], hp[["magenta"]])
# push label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
ev <- utils::read.csv("data_events.csv", stringsAsFactors = FALSE)
df <- df[order(df$topic, df$year), ]
df$topic <- factor(df$topic, levels = unique(df$topic))
# drop each topic's leading zero years, so a line starts at its first paper instead of running
# along the bottom frame
first_year <- tapply(ifelse(df$n > 0, df$year, Inf), df$topic, min)
df <- df[df$year >= first_year[as.character(df$topic)], ]
df$y <- if (isTRUE(cumulative)) stats::ave(df$n, df$topic, FUN = cumsum) else df$n
cols <- stats::setNames(line_cols[seq_len(nlevels(df$topic))], levels(df$topic))

x_min <- min(df$year); x_max <- max(df$year)
y_max <- max(df$y)
y_top <- y_max / 0.70                         # top 30 % of the panel holds the event labels
x_right <- x_max + 0.30 * (x_max - x_min)     # room for the end labels

ends <- do.call(rbind, lapply(split(df, df$topic), function(d) d[which.max(d$year), ]))
ends$lab <- sprintf("%s (%s)", ends$topic, formatC(ends$y, format = "d", big.mark = ","))
ends$ly <- spread(ends$y, gap = 0.075 * y_top)
# a step line ends with a flat segment over the last year; start the label just past it
end_x <- x_max + if (isTRUE(as_step)) 1 else 0

p <- ggplot(df, aes(year, y, colour = topic))
if (isTRUE(show_events) && nrow(ev)) {
  ev <- ev[order(ev$year), ]
  ev$lab <- if (isTRUE(show_event_year)) sprintf("%d %s", ev$year, ev$event) else ev$event
  # label width in years: text width (mm, Arial 7 pt) over the panel width (mm per year), with
  # the panel taken as the canvas minus about 15 mm of axis and margin
  w_mm <- systemfonts::string_width(ev$lab, family = house_family(), size = 7, res = 72) / 72 * 25.4
  mm_per_year <- (pv_house_canvas(fig_cells)$width_mm - 15) / (x_right - x_min)
  ev$x0 <- ev$year + 0.25; ev$x1 <- ev$x0 + w_mm / mm_per_year + 0.15
  # greedy rows: a later event's dashed line runs up to its own row, so it must sit on a lower
  # row than any earlier label it would cross; labels on one row must not overlap
  ev$row <- 0
  for (j in seq_len(nrow(ev))[-1]) {
    r <- 0
    repeat {
      prev <- seq_len(j - 1)
      clash <- any(ev$x1[prev] > ev$x0[j] - 0.25 & ev$row[prev] >= r)
      if (!clash) break
      if (r >= event_rows - 1) {
        warning("event labels collide: shorten the names in data_events.csv or raise event_rows")
        break
      }
      r <- r + 1
    }
    ev$row[j] <- r
  }
  ev$ly <- y_top * (0.975 - 0.095 * ev$row)
  p <- p +
    geom_segment(data = ev, aes(x = year, xend = year, y = 0, yend = ly), inherit.aes = FALSE,
                 linetype = "22", colour = grey[["ref"]], linewidth = pv_house_lw("ref")) +
    geom_text(data = ev, aes(x = year + 0.25, y = ly, label = lab), inherit.aes = FALSE,
              hjust = 0, vjust = 1, colour = "#1A1A1A", size = pv_pt2size(7))
}
if (isTRUE(as_step)) {
  # extend each topic by one year so the last count gets its own flat step
  last <- ends; last$year <- last$year + 1
  p <- p + geom_step(data = rbind(df, last[, names(df)]), direction = "hv",
                     linewidth = pv_house_lw("main"))
} else {
  p <- p + geom_line(linewidth = pv_house_lw("main"))
}
if (isTRUE(show_end_labels)) {
  p <- p + geom_text(data = ends, aes(x = end_x + 0.5, y = ly, label = lab), hjust = 0,
                     size = pv_pt2size(7))
}
p <- p +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(limits = c(x_min, x_right), expand = c(0, 0),
                     breaks = seq(ceiling(x_min / x_break_step) * x_break_step, x_max + 1, by = x_break_step)) +
  scale_y_continuous(limits = c(0, y_top), expand = c(0, 0), breaks = pretty(c(0, y_max), n = 4),
                     labels = function(b) formatC(b, format = "d", big.mark = ",")) +
  labs(x = "Year", y = y_label, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = fig_cells)
message("wrote preview.png")
