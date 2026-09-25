# Eight chromosomes, 200 density bins, 40 inter-chromosomal links.
set.seed(301)

chr_mb <- c(78, 66, 58, 51, 44, 37, 29, 22)
n_bin <- 25L
bins <- list()
for (i in seq_along(chr_mb)) {
  chr <- sprintf("Chr%d", i)
  len <- chr_mb[i] * 1e6
  br <- seq(0, len, length.out = n_bin + 1L)
  # two soft peaks (arm gene density), not a hard block
  peak1 <- 0.22 * len
  peak2 <- 0.72 * len
  for (w in seq_len(n_bin)) {
    mid <- (br[w] + br[w + 1L]) / 2
    z <- 18 * exp(-((mid - peak1) / (0.10 * len))^2) +
      12 * exp(-((mid - peak2) / (0.14 * len))^2) +
      4
    val <- z + rnorm(1, 0, 1.1)
    bins[[length(bins) + 1L]] <- data.frame(
      chr = chr,
      start = round(br[w]),
      end = round(br[w + 1L]),
      value = round(max(0.4, val), 3),
      link_to = "",
      stringsAsFactors = FALSE
    )
  }
}
bins <- do.call(rbind, bins)

# links stored in the same columns: value is unused, link_to is "chr:start-end"
links <- list()
for (k in seq_len(40L)) {
  a <- sample.int(8L, 1L)
  b <- sample.int(8L, 1L)
  if (b == a) b <- (a %% 8L) + 1L
  len_a <- chr_mb[a] * 1e6
  len_b <- chr_mb[b] * 1e6
  w_a <- round(runif(1, 0.4e6, 2.2e6))
  w_b <- round(runif(1, 0.4e6, 2.2e6))
  s_a <- round(runif(1, 0, len_a - w_a))
  s_b <- round(runif(1, 0, len_b - w_b))
  links[[k]] <- data.frame(
    chr = sprintf("Chr%d", a),
    start = s_a,
    end = s_a + w_a,
    value = NA_real_,
    link_to = sprintf("Chr%d:%d-%d", b, s_b, s_b + w_b),
    stringsAsFactors = FALSE
  )
}
links <- do.call(rbind, links)
out <- rbind(bins, links)
utils::write.csv(out, "data.csv", row.names = FALSE)
