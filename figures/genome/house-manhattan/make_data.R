# Simulated GWAS: 6,000 SNPs on 12 chromosomes, two true association peaks (chr3, chr8).
# Writes data.csv: chr, pos_mb, neg_log10_p (rounded to keep the file small). Run from this directory.
set.seed(20261012)
chr_len <- c(43, 36, 37, 36, 30, 31, 30, 28, 23, 23, 29, 28)    # Mb
n_snp <- 6000
chr <- sort(sample(seq_along(chr_len), n_snp, replace = TRUE, prob = chr_len))
pos <- stats::runif(n_snp, 0, chr_len[chr])
p <- stats::runif(n_snp)                                         # null
peak <- function(ch, centre, height, width) {
  i <- chr == ch; d <- abs(pos[i] - centre)
  boost <- height * exp(-(d / width)^2) * stats::runif(sum(i), 0.35, 1)
  p[i] <<- pmin(p[i], 10^-boost)
}
peak(3, 21.4, 11.5, 2.4)
peak(8, 12.7, 7.0, 1.8)
o <- order(chr, pos)
d <- data.frame(chr = chr[o], pos_mb = round(pos[o], 3), neg_log10_p = round(-log10(p[o]), 3))
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d), " bytes=", file.size("data.csv"))
