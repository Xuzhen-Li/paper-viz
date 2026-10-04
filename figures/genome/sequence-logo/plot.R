# Sequence logo. Letter height is frequency times information, stacked small to large.
source("../../../styles/r/theme_viz.R")

method <- "bits"
base_levels <- c("A", "C", "G", "T")
# A/C/G/T in chip order. n=4 stops before yellow.
base_cols <- stats::setNames(pv_palette("categorical", 4), base_levels)

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

p <- ggplot2::ggplot(letters_df) +
  ggplot2::geom_polygon(
    ggplot2::aes(x, y, group = gid, fill = letter),
    colour = NA
  ) +
  ggplot2::scale_fill_manual(values = base_cols, guide = "none") +
  ggplot2::scale_x_continuous(breaks = sort(unique(df$pos)), expand = ggplot2::expansion(add = 0.4)) +
  ggplot2::scale_y_continuous(limits = c(0, y_top), expand = ggplot2::expansion(mult = c(0, 0.02))) +
  ggplot2::labs(x = "Position in motif", y = y_lab) +
  theme_viz() +
  ggplot2::theme(
    legend.position = "none",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

pv_save(p, "figure", width_mm = 183, height_mm = 96)
message("wrote preview.png")
