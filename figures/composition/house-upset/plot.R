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
widths_mm <- c(22, 16)     # set-size bars, set labels: kept tight so the bars and matrix get the width
matrix_share <- 0.42       # matrix height / intersection-bar height

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
sets <- names(set_cols)
k <- length(sets)
pal <- pv_palette("house")
cols <- stats::setNames(unname(pal[seq_len(k)]), sets)
grey <- pv_palette("house_grey")

# exclusive intersections: each gene counted once, in its exact combination
key <- apply(df[, sets] == 1, 1, function(r) paste(sets[r], collapse = "&"))
tab_all <- sort(table(key), decreasing = TRUE)
n_inter <- length(tab_all)                         # non-empty intersections in the data
tab <- tab_all[seq_len(min(n_show, n_inter))]
n_in_shown <- sum(tab)                            # genes covered by the columns shown
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
# one-sentence conclusion from the data: the largest intersection of two or more sets
top_shared <- inter[inter$degree > 1, ][1, ]
conclusion <- sprintf("Largest shared set: %s (%d genes)",
                      paste(set_cols[top_shared$members[[1]]], collapse = " + "), top_shared$n)
x_sc <- scale_x_continuous(limits = c(0.5, nrow(inter) + 0.5), expand = c(0, 0))
y_rows <- scale_y_continuous(limits = c(0.5, k + 0.5), expand = c(0, 0))
y_top <- ceiling(max(inter$n) * 1.08 / 25) * 25   # max x 1.08, rounded up to 25 (375 -> 425)
no_x <- theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.title.x = element_blank())

# intersection bars ------------------------------------------------------------------------
p_bar <- ggplot(inter, aes(col_i, n)) +
  geom_rect(data = bands, aes(xmin = col_i - 0.5, xmax = col_i + 0.5, ymin = 0, ymax = Inf),
            inherit.aes = FALSE, fill = band_fill) +
  geom_col(aes(fill = fill), width = 0.62) +
  geom_text(aes(label = n, colour = fill), vjust = -0.35, size = pv_pt2size(8)) +
  annotate("text", x = nrow(inter) + 0.35, y = y_top * 0.97, hjust = 1, vjust = 1, size = pv_pt2size(8),
           label = conclusion) +
  scale_fill_identity() + scale_colour_identity() + x_sc +
  scale_y_continuous(limits = c(0, y_top), breaks = seq(0, floor(y_top / 100) * 100, 100), expand = c(0, 0)) +
  labs(y = "Intersection size (genes)") +
  theme_house() + no_x

# dot matrix -------------------------------------------------------------------------------
p_mat <- ggplot() +
  geom_rect(data = bands, aes(xmin = col_i - 0.5, xmax = col_i + 0.5, ymin = -Inf, ymax = Inf),
            fill = band_fill) +
  # inactive dots, then the connector, then the member dots on top (the line stays solid)
  # every dot is HOUSE_POINT shape 21 / size / stroke; only fill (and outline for inactive) differs
  geom_point(data = dots[!dots$on, ], aes(col_i, row), shape = HOUSE_POINT$shape, size = dot_size,
             stroke = HOUSE_POINT$stroke, fill = grey[["light"]], colour = grey[["light"]]) +
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
x_set <- ceiling(max(set_n$n) * 1.08 / 250) * 250   # same rule as the top axis; 891 -> 1000
# Text colour for a label drawn on a filled bar (WCAG 2.x contrast).
# Relative luminance L = 0.2126 R + 0.7152 G + 0.0722 B on linearised sRGB;
# contrast = (L_light + 0.05) / (L_dark + 0.05). White is used when it reaches
# 4.5:1 (normal-size text), otherwise near-black #1A1A1A.
wcag_lum <- function(hex) {
  c <- grDevices::col2rgb(hex)[, 1] / 255
  c <- ifelse(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4)
  sum(c(0.2126, 0.7152, 0.0722) * c)
}
wcag_contrast <- function(a, b) {
  l <- sort(c(wcag_lum(a), wcag_lum(b)), decreasing = TRUE)
  (l[1] + 0.05) / (l[2] + 0.05)
}
on_fill_text <- function(fill, min_ratio = 4.5) {
  vapply(fill, function(f) {
    if (wcag_contrast("#FFFFFF", f) >= min_ratio) "#FFFFFF" else "#1A1A1A"
  }, character(1), USE.NAMES = FALSE)
}

# Set-size labels go inside the bar end when they fit with >= 1 mm either
# side; otherwise just outside it in the set colour (axis stays at x_set).
lab_pt  <- 8
pad_mm  <- 1
digit_mm <- 0.556 * lab_pt * 25.4 / 72           # Arial digit advance
set_n$bar_mm  <- set_n$n / x_set * widths_mm[1]
set_n$text_mm <- nchar(format(set_n$n)) * digit_mm
set_n$inside  <- set_n$bar_mm >= set_n$text_mm + 2 * pad_mm
set_n$fill_hex <- unname(cols[as.character(set_n$set)])
set_n$lab_col <- ifelse(set_n$inside, on_fill_text(set_n$fill_hex), set_n$fill_hex)
set_n$lab_x   <- set_n$n + ifelse(set_n$inside, -1, 1.2) * pad_mm / widths_mm[1] * x_set  # 1.2: digit side bearing
set_n$lab_h   <- ifelse(set_n$inside, 0, 1)      # reversed axis: 0 = text runs toward 0

p_set <- ggplot(set_n, aes(n, row, fill = set)) +
  geom_col(width = 0.76, orientation = "y") +     # 3.2 mm bars: >= 0.3 mm above 8 pt digits
  geom_text(aes(x = lab_x, label = n, hjust = lab_h), colour = set_n$lab_col,
            size = pv_pt2size(lab_pt)) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_x_reverse(limits = c(x_set, 0), breaks = seq(0, x_set, 500), expand = c(0, 0)) + y_rows +
  labs(x = "Set size (genes)") +
  theme_house() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.title.y = element_blank())

# note, bottom-anchored in the top-left cell so it sits just above the set-size bars ---------
fmt_n <- function(x) format(x, big.mark = ",")
note <- data.frame(y = 5.2 - (0:5), face = c("bold", rep("plain", 5)),
                   col = c("#000000", rep(grey[["mid"]], 4), "#000000"),
                   lab = c("Drought-responsive genes",
                           sprintf("n = %s genes in %d tissues", fmt_n(nrow(df)), k),
                           sprintf("Top %d of %d intersections shown", nrow(inter), n_inter),
                           sprintf("(%s genes); set bars count all", fmt_n(n_in_shown)),
                           "Colour: one tissue only", "Black: shared by 2+ tissues"))
p_note <- ggplot(note, aes(0, y, label = lab)) +
  geom_text(aes(fontface = face, colour = col), hjust = 0, vjust = 0, size = pv_pt2size(7)) +
  scale_colour_identity() +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 16), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  theme_void()

p <- p_bar + p_mat + p_lab + p_set + p_note +
  plot_layout(design = "EEA\nDCB", widths = unit(c(widths_mm, 1), c("mm", "mm", "null")),
              heights = c(1, matrix_share))
pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
