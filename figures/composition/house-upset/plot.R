# House-style UpSet: intersection bars + dot matrix + set-size bars, drawn with ggplot2 + patchwork.
# Single-set columns, dots and set bars in the set colour; multi-set intersections in black.
# Counts are written on the bars; matrix columns alternate a light grey band.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

set_cols <- c(leaf = "Leaf", root = "Root", berry_skin = "Berry skin", berry_flesh = "Berry flesh", seed = "Seed")
n_show <- 15               # largest intersections shown (exclusive counts)
band_fill <- pv_palette("house_grey")[["bg"]]
dot_size <- 2.3            # matrix dots (HOUSE_POINT size)
widths_mm <- c(28, 17)     # set-size bars, set labels (the matrix takes the rest)
matrix_share <- 0.42       # matrix height / intersection-bar height

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
sets <- names(set_cols)
k <- length(sets)
pal <- pv_palette("house")
cols <- stats::setNames(unname(pal[seq_len(k)]), sets)
grey <- pv_palette("house_grey")

# exclusive intersections: each gene counted once, in its exact combination
key <- apply(df[, sets] == 1, 1, function(r) paste(sets[r], collapse = "&"))
tab <- sort(table(key), decreasing = TRUE)[seq_len(n_show)]
inter <- data.frame(key = names(tab), n = as.integer(tab), stringsAsFactors = FALSE)
inter$col_i <- seq_len(nrow(inter))
inter$members <- strsplit(inter$key, "&", fixed = TRUE)
inter$degree <- lengths(inter$members)
inter$fill <- ifelse(inter$degree == 1, cols[vapply(inter$members, `[`, "", 1)], "#000000")
set_n <- data.frame(set = sets, row = rev(seq_len(k)), n = colSums(df[, sets]))

dots <- do.call(rbind, lapply(seq_len(nrow(inter)), function(i) {
  on <- sets %in% inter$members[[i]]
  data.frame(col_i = i, row = set_n$row, on = on,
             fill = ifelse(on, inter$fill[i], grey[["light"]]))
}))
links <- do.call(rbind, lapply(which(inter$degree > 1), function(i) {
  r <- set_n$row[sets %in% inter$members[[i]]]
  data.frame(col_i = i, lo = min(r), hi = max(r))
}))
bands <- data.frame(col_i = seq(2, nrow(inter), 2))
x_sc <- scale_x_continuous(limits = c(0.5, nrow(inter) + 0.5), expand = c(0, 0))
y_rows <- scale_y_continuous(limits = c(0.5, k + 0.5), expand = c(0, 0))
y_top <- ceiling(max(inter$n) * 1.12 / 100) * 100
no_x <- theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.title.x = element_blank())

# intersection bars ------------------------------------------------------------------------
p_bar <- ggplot(inter, aes(col_i, n)) +
  geom_rect(data = bands, aes(xmin = col_i - 0.5, xmax = col_i + 0.5, ymin = 0, ymax = Inf),
            inherit.aes = FALSE, fill = band_fill) +
  geom_col(aes(fill = fill), width = 0.62) +
  geom_text(aes(label = n, colour = fill), vjust = -0.35, size = pv_pt2size(7)) +
  scale_fill_identity() + scale_colour_identity() + x_sc +
  scale_y_continuous(limits = c(0, y_top), breaks = seq(0, y_top, 100), expand = c(0, 0)) +
  labs(y = "Intersection size (genes)") +
  theme_house() + no_x

# dot matrix -------------------------------------------------------------------------------
p_mat <- ggplot() +
  geom_rect(data = bands, aes(xmin = col_i - 0.5, xmax = col_i + 0.5, ymin = -Inf, ymax = Inf),
            fill = band_fill) +
  # inactive dots, then the connector, then the member dots on top (the line stays solid)
  geom_point(data = dots[!dots$on, ], aes(col_i, row), shape = 16, size = dot_size, colour = grey[["light"]]) +
  geom_segment(data = links, aes(x = col_i, xend = col_i, y = lo, yend = hi),
               linewidth = pv_house_lw("main"), colour = "#000000") +
  geom_point(data = dots[dots$on, ], aes(col_i, row, fill = fill), shape = HOUSE_POINT$shape, size = dot_size,
             stroke = HOUSE_POINT$stroke, colour = "#000000") +
  scale_fill_identity() + x_sc + y_rows +
  theme_house() + no_x +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.title.y = element_blank())

# set labels in the set colour -------------------------------------------------------------
p_lab <- ggplot(set_n, aes(1, row, label = set_cols[set], colour = set)) +
  geom_text(hjust = 0.5, size = pv_pt2size(8)) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(limits = c(0, 2), expand = c(0, 0)) + y_rows +
  theme_void()

# set sizes (bars run leftwards, counts on the bars) ---------------------------------------
x_set <- ceiling(max(set_n$n) * 1.35 / 250) * 250
p_set <- ggplot(set_n, aes(n, row, fill = set)) +
  geom_col(width = 0.62, orientation = "y") +
  geom_text(aes(label = n, colour = set), hjust = 1.15, size = pv_pt2size(7)) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_reverse(limits = c(x_set, 0), breaks = seq(0, x_set, 500), expand = c(0, 0)) + y_rows +
  labs(x = "Set size (genes)") +
  theme_house() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.title.y = element_blank())

# note in the empty top-left corner: what is counted and the colour key ---------------------
note <- data.frame(y = 4 - 0.5 * (0:3), face = c("bold", "plain", "plain", "plain"),
                   col = c("#000000", grey[["mid"]], grey[["mid"]], "#000000"),
                   lab = c("Drought-responsive genes",
                           sprintf("n = %s genes, %d tissues", format(nrow(df), big.mark = ","), k),
                           "Colour: one tissue only", "Black: shared by \u2265 2 tissues"))
p_note <- ggplot(note, aes(0, y, label = lab)) +
  geom_text(aes(fontface = face, colour = col), hjust = 0, vjust = 1, size = pv_pt2size(7)) +
  scale_colour_identity() +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-4, 4.2), expand = c(0, 0)) +
  theme_void()

p <- p_bar + p_mat + p_lab + p_set + p_note +
  plot_layout(design = "EEA\nDCB", widths = unit(c(widths_mm, 1), c("mm", "mm", "null")),
              heights = c(1, matrix_share))
pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
