# Plant GWAS: 12 chromosomes, null SNPs plus three QTL peaks.
set.seed(204)

chr_mb <- c(43, 36, 36, 35, 30, 31, 29, 28, 23, 23, 29, 27)
n_per <- 520L
peaks <- data.frame(
  chr = c(3L, 7L, 11L),
  pos_mb = c(8.2, 15.4, 4.6),
  width_mb = c(1.4, 1.1, 0.8),
  height = c(9.5, 6.2, 4.4),
  qtl = c("QTL3", "QTL7", "QTL11")
)

rows <- vector("list", length(chr_mb))
for (chr in seq_along(chr_mb)) {
  n <- n_per
  pos <- sort(sample(seq_len(chr_mb[chr] * 1e6L), n))
  p <- stats::runif(n)
  snp <- sprintf("s%d-%d", chr, seq_len(n))
  highlight <- rep(0L, n)
  pk <- peaks[peaks$chr == chr, , drop = FALSE]
  if (nrow(pk)) {
    for (r in seq_len(nrow(pk))) {
      d <- abs(pos - pk$pos_mb[r] * 1e6) / (pk$width_mb[r] * 1e6)
      hit <- d < 1
      boost <- (1 - d[hit])^2
      p[hit] <- 10^(-(1.4 + boost * pk$height[r] + stats::rnorm(sum(hit), 0, 0.28)))
      lp <- -log10(p)
      top <- which(hit & lp > 6)
      if (length(top)) {
        keep <- top[order(lp[top], decreasing = TRUE)][1]
        highlight[keep] <- 1L
        snp[keep] <- pk$qtl[r]
      }
    }
  }
  rows[[chr]] <- data.frame(
    chr = chr, pos = pos, p = signif(p, 3), snp = snp, highlight = highlight,
    stringsAsFactors = FALSE
  )
}
df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE, quote = FALSE)
message("bytes ", file.info("data.csv")$size)
