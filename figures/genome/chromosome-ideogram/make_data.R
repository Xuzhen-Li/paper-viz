# Simulated plant karyotype: 8 chromosomes, centromeres, NORs, gene-density windows.
set.seed(202)

chr_mb <- c(62, 54, 48, 41, 36, 29, 24, 19)
cen_frac <- c(0.38, 0.32, 0.42, 0.28, 0.45, 0.35, 0.40, 0.33)
cen_width_mb <- c(1.6, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8)
nor_chr <- c(2L, 6L)
nor_frac <- c(0.12, 0.10)

rows <- list()
n_win <- 25L
for (i in seq_along(chr_mb)) {
  chr <- sprintf("Chr%d", i)
  len <- chr_mb[i] * 1e6
  cen_mid <- cen_frac[i] * len
  cen_half <- cen_width_mb[i] * 1e6 / 2
  rows[[length(rows) + 1L]] <- data.frame(
    chr = chr, start = 0, end = len, feature = "chromosome", value = NA_real_
  )
  rows[[length(rows) + 1L]] <- data.frame(
    chr = chr,
    start = round(cen_mid - cen_half),
    end = round(cen_mid + cen_half),
    feature = "centromere",
    value = NA_real_
  )
  br <- seq(0, len, length.out = n_win + 1L)
  for (w in seq_len(n_win)) {
    mid <- (br[w] + br[w + 1L]) / 2
    d <- abs(mid - cen_mid) / len
    base <- 6 + 30 * pmin(1, d / 0.16)
    val <- base + rnorm(1, 0, 1.6)
    rows[[length(rows) + 1L]] <- data.frame(
      chr = chr,
      start = round(br[w]),
      end = round(br[w + 1L]),
      feature = "density",
      value = round(max(1, val), 2)
    )
  }
}
for (k in seq_along(nor_chr)) {
  i <- nor_chr[k]
  chr <- sprintf("Chr%d", i)
  len <- chr_mb[i] * 1e6
  mid <- nor_frac[k] * len
  half <- 0.35e6
  rows[[length(rows) + 1L]] <- data.frame(
    chr = chr,
    start = round(mid - half),
    end = round(mid + half),
    feature = "nor",
    value = NA_real_
  )
}
df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
