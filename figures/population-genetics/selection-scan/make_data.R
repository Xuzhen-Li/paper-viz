# XP-CLR and |iHS| window scores.
set.seed(105)
chr_len <- c(chr1 = 42e6, chr2 = 36e6, chr3 = 38e6, chr4 = 31e6, chr5 = 28e6)
n_win <- 500L
ar1 <- function(n, rho = 0.9) {
  e <- rnorm(n)
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
  base <- ar1(n_win)
  xp <- exp(0.35 * base + log(2.4))
  ih <- abs(0.28 * base + rnorm(n_win, 0, 0.32))
  centers <- c(0.38, 0.67) * chr_len[[ch]]
  widths <- c(0.8e6, 0.6e6)
  if (ch %in% c("chr1", "chr3", "chr4")) {
    xp <- xp + peak(pos, centers[1], widths[1], 42) + peak(pos, centers[2], widths[2], 18)
    ih <- ih + peak(pos, centers[1], widths[1], 2.4) + peak(pos, centers[2], widths[2], 1.1)
  }
  xp <- pmin(90, pmax(0.2, xp))
  ih <- pmin(6, pmax(0.02, ih))
  rows[[length(rows) + 1L]] <- rbind(
    data.frame(chr = ch, pos = round(pos), score = round(xp, 3), method = "xpclr"),
    data.frame(chr = ch, pos = round(pos), score = round(ih, 3), method = "ihs")
  )
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
