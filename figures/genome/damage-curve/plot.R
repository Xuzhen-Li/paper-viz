# aDNA damage (house style): 5' C>T and 3' G>A by library, one panel per library and read end,
# substitution names written next to their curves. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_ct <- TRUE
show_ga <- TRUE
libraries_keep <- c("no-UDG", "half-UDG")

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white, else #1A1A1A (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  stats::setNames(ifelse(ratio >= 3, hex, "#1A1A1A"), names(hex))
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
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$library %in% libraries_keep, , drop = FALSE]
if (!isTRUE(show_ct)) df <- df[df$substitution != "C>T", , drop = FALSE]
if (!isTRUE(show_ga)) df <- df[df$substitution != "G>A", , drop = FALSE]

df$end <- factor(df$end, levels = c("5'", "3'"), labels = c("5' end", "3' end"))
df$library <- factor(df$library, levels = libraries_keep)
sub_cols <- c("C>T" = hp[["red"]], "G>A" = hp[["blue"]])

# in-panel stat: terminal-base C>T rate (5' end) and G>A rate (3' end) per library
term <- df[df$pos == 1, , drop = FALSE]
term <- term[(term$substitution == "C>T" & term$end == "5' end") |
             (term$substitution == "G>A" & term$end == "3' end"), , drop = FALSE]
term$lab <- sprintf("%s at base 1: %.2f", term$substitution, term$rate)
# curve names: where each curve sits at position 6, placed above (leading) or below (trailing)
# (top library only; the panels below use the same colours)
nm <- df[df$pos == 6 & df$library == levels(df$library)[1], , drop = FALSE]
nm <- do.call(rbind, lapply(split(nm, interaction(nm$library, nm$end, drop = TRUE)), function(s) {
  s <- s[order(-s$rate), , drop = FALSE]
  s[1, , drop = FALSE]
}))

p <- ggplot(df, aes(pos, rate, colour = substitution)) +
  geom_line(linewidth = pv_house_lw("main")) +
  geom_point(shape = 21, size = 1.2, stroke = 0.3, colour = "black", aes(fill = substitution)) +
  geom_text(data = nm, aes(label = substitution), hjust = 0, vjust = -0.6, nudge_x = 0.6,
            size = pv_pt2size(7), family = house_family(), show.legend = FALSE) +
  geom_text(data = term, aes(label = lab), x = Inf, y = Inf, hjust = 1.05, vjust = 1.5,
            colour = grey[["dark"]], size = pv_pt2size(7), family = house_family(), inherit.aes = FALSE) +
  facet_grid(library ~ end) +
  scale_colour_manual(values = text_col(sub_cols), guide = "none") +
  scale_fill_manual(values = sub_cols, guide = "none") +
  scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 25)) +
  scale_y_continuous(limits = c(0, 0.4), expand = expansion(mult = c(0, 0.04))) +
  labs(x = "Position from read end (bp)", y = "Substitution frequency", caption = footnote) +
  theme_house() +
  theme(strip.background = element_blank(), strip.text = element_text(size = 7),
        plot.margin = margin(1, 1.5, 1, 1, "mm")) +
  caption_theme

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
