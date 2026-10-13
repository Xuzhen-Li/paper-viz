# Sequence logo (house style): letter height is frequency times information, stacked small to large;
# total information content as the in-panel stat. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
method <- "bits"
base_levels <- c("A", "C", "G", "T")

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# orange marks/labels use the darker chrom12 step of the same hue (#E17927, 3.01:1 on white)
hp[["orange"]] <- pv_palette("chrom12")[[8]]
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
# usual nucleotide hues taken from the house palette: A green, C blue, G orange, T red
base_cols <- stats::setNames(c(hp[["green"]], hp[["blue"]], hp[["orange"]], hp[["red"]]), base_levels)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$base <- factor(df$base, levels = base_levels)
if (method == "prob") {
  logo_mat <- xtabs(prob ~ base + pos, df)
  logo_mat <- logo_mat[base_levels, , drop = FALSE]
  y_top <- 1.05
  y_lab <- "Probability"
} else {
  logo_mat <- xtabs(bits ~ base + pos, df)
  logo_mat <- logo_mat[base_levels, , drop = FALSE]
  logo_mat[logo_mat < 0.15] <- 0
  y_top <- max(colSums(logo_mat)) + 0.15
  y_lab <- "Information (bits)"
}
# Glyphs from the logo font, then refit into each letter's own height band
# so a tall curve cannot spill into the letter stacked under it.
raw <- ggseqlogo:::logo_data(
  logo_mat, method = "custom", seq_type = "dna",
  font = "helvetica_bold", stack_width = 0.85
)
raw <- raw[raw$letter %in% rownames(logo_mat)[rowSums(logo_mat) >= 0], , drop = FALSE]
pieces <- split(raw, paste(raw$position, raw$letter))
fit_letter <- function(g) {
  g <- g[order(g$order), , drop = FALSE]
  pos <- g$position[1]
  let <- as.character(g$letter[1])
  h <- logo_mat[let, as.character(pos)]
  if (!length(h) || is.na(h) || h <= 0) return(NULL)
  col_h <- logo_mat[, as.character(pos)]
  col_h <- sort(col_h[col_h > 0])
  below <- sum(col_h[seq_len(match(let, names(col_h)) - 1L)])
  if (match(let, names(col_h)) == 1L) below <- 0
  pad <- 0.14 * h
  yr <- range(g$y)
  xr <- range(g$x)
  gy <- if (diff(yr) < 1e-6) 0.5 else (g$y - yr[1]) / diff(yr)
  gx <- if (diff(xr) < 1e-6) 0.5 else (g$x - xr[1]) / diff(xr)
  g$y <- below + pad + gy * (h - 2 * pad)
  g$x <- (pos - 0.32) + gx * 0.64
  g
}
fitted <- lapply(pieces, fit_letter)
fitted <- fitted[!vapply(fitted, is.null, logical(1))]
letters_df <- do.call(rbind, fitted)
letters_df$gid <- paste(letters_df$position, letters_df$letter)

ic <- sum(logo_mat)
stat <- if (method == "prob") sprintf("%d positions", ncol(logo_mat)) else sprintf("Total information %.1f bits", ic)
p <- ggplot(letters_df) +
  geom_polygon(aes(x, y, group = gid, fill = letter), colour = NA) +
  annotate("text", x = Inf, y = Inf, hjust = 1.03, vjust = 1.4, label = stat, size = pv_pt2size(7),
           colour = "#1A1A1A", family = house_family()) +
  scale_fill_manual(values = base_cols, guide = "none") +
  scale_x_continuous(breaks = sort(unique(df$pos)), expand = expansion(add = 0.4)) +
  scale_y_continuous(limits = c(0, y_top * 1.15), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Position in motif", y = y_lab, caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
