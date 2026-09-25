# 80 x 80 Hi-C: power-law decay, soft A/B plaid, soft TADs, soft Rabl spots.
set.seed(213)

chr_bins <- c(Chr1 = 24L, Chr2 = 20L, Chr3 = 20L, Chr4 = 16L)
n <- sum(chr_bins)
bin_chr <- rep(names(chr_bins), chr_bins)
bin_pos <- unlist(lapply(chr_bins, seq_len), use.names = FALSE)
chr_start <- c(0L, cumsum(chr_bins)[-length(chr_bins)])
names(chr_start) <- names(chr_bins)

comp <- numeric(n)
cen <- integer(length(chr_bins))
names(cen) <- names(chr_bins)
for (k in seq_along(chr_bins)) {
  ix <- which(bin_chr == names(chr_bins)[k])
  block <- 8L
  sgn <- if (k %% 2L == 1L) 1 else -1
  for (b in seq_len(length(ix))) {
    comp[ix[b]] <- sgn
    if (b %% block == 0L) sgn <- -sgn
  }
  cen[k] <- ix[round(length(ix) / 2)]
}

# TAD intervals in global bin index, kept off the centromere.
tad_local <- list(
  Chr1 = list(c(2, 7), c(10, 15), c(18, 23)),
  Chr2 = list(c(2, 7), c(12, 17)),
  Chr3 = list(c(2, 7), c(13, 18)),
  Chr4 = list(c(2, 6), c(10, 15))
)
tads <- list()
for (nm in names(tad_local)) {
  for (seg in tad_local[[nm]]) {
    tads[[length(tads) + 1L]] <- chr_start[nm] + seg
  }
}

soft_box <- function(i, a, b, width) {
  stats::plogis((i - a) / width) * stats::plogis((b - i) / width)
}

lam <- matrix(0, n, n)
for (i in seq_len(n)) {
  for (j in i:n) {
    same <- bin_chr[i] == bin_chr[j]
    if (same) {
      d <- abs(bin_pos[i] - bin_pos[j])
      base <- 900 * (d + 1)^(-1)
      comp_mod <- 1 + 0.6 * comp[i] * comp[j] * exp(-d / 12)
      tad_w <- 0
      for (seg in tads) {
        ei <- soft_box(i, seg[1], seg[2], 0.9)
        ej <- soft_box(j, seg[1], seg[2], 0.9)
        tad_w <- tad_w + ei * ej
      }
      val <- base * comp_mod * (1 + 4.5 * pmin(tad_w, 1))
    } else {
      val <- 3.5
    }
    lam[i, j] <- val
    lam[j, i] <- val
  }
}

# Weaker inter-centromere Rabl signal: round Gaussian, not a hard block.
sigma <- 3.2
amp <- 26
for (a in cen) {
  for (b in cen) {
    if (a == b) next
    gi <- exp(-((seq_len(n) - a)^2) / (2 * sigma^2))
    gj <- exp(-((seq_len(n) - b)^2) / (2 * sigma^2))
    add <- amp * outer(gi, gj)
    add[outer(bin_chr, bin_chr, "==")] <- 0
    lam <- lam + add
  }
}
lam <- (lam + t(lam)) / 2

mat <- matrix(0L, n, n)
for (i in seq_len(n)) {
  for (j in i:n) {
    v <- stats::rpois(1L, lam[i, j])
    mat[i, j] <- v
    mat[j, i] <- v
  }
}

df <- data.frame(
  bin_i = rep(seq_len(n), each = n),
  bin_j = rep(seq_len(n), times = n),
  count = as.integer(mat)
)
df$chr <- bin_chr[df$bin_i]
utils::write.csv(df[, c("bin_i", "bin_j", "chr", "count")], "data.csv", row.names = FALSE)
message("wrote data.csv bytes ", file.info("data.csv")$size)
