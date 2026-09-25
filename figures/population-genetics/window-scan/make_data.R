# Windowed Fst, pi and Tajima's D on five chromosomes.
set.seed(104)
chr_len <- c(chr1 = 42e6, chr2 = 36e6, chr3 = 38e6, chr4 = 31e6, chr5 = 28e6)
n_win <- 400L
ar1 <- function(n, rho = 0.88, sd = 1) {
  e <- rnorm(n, 0, sd)
  x <- e
  for (i in 2:n) x[i] <- rho * x[i - 1] + e[i]
  x
}
peak <- function(pos, center, width, height) {
  height * exp(-0.5 * ((pos - center) / width)^2)
}
rows <- list()
for (ch in names(chr_len)) {
  pos <- seq(chr_len[[ch]] / (n_win + 1), chr_len[[ch]], length.out = n_win)
  noise <- ar1(n_win)
  # shared valleys / peaks: chr3 mid, chr1 distal
  c3 <- if (ch == "chr3") 0.42 * chr_len[[ch]] else NA_real_
  c1 <- if (ch == "chr1") 0.72 * chr_len[[ch]] else NA_real_
  fst <- 0.09 + 0.035 * noise
  pi <- 4.2 + 0.55 * noise
  taj <- 0.15 + 0.65 * noise
  if (!is.na(c3)) {
    fst <- fst + peak(pos, c3, 1.1e6, 0.28)
    pi <- pi - peak(pos, c3, 1.1e6, 2.4)
    taj <- taj - peak(pos, c3, 1.1e6, 2.6)
  }
  if (!is.na(c1)) {
    fst <- fst + peak(pos, c1, 0.9e6, 0.16)
    pi <- pi - peak(pos, c1, 0.9e6, 1.3)
    taj <- taj - peak(pos, c1, 0.9e6, 1.5)
  }
  fst <- pmin(0.55, pmax(0, fst))
  pi <- pmin(8, pmax(0.4, pi))
  taj <- pmax(-3.2, pmin(3, taj))
  rows[[length(rows) + 1L]] <- rbind(
    data.frame(chr = ch, pos = round(pos), stat = "fst", value = round(fst, 4)),
    data.frame(chr = ch, pos = round(pos), stat = "pi", value = round(pi, 4)),
    data.frame(chr = ch, pos = round(pos), stat = "tajima", value = round(taj, 4))
  )
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
