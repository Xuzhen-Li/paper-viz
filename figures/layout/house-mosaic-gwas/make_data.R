# Simulated GWAS of a drought tolerance index (DTI) in a grapevine diversity panel.
# data.csv: SNP positions and P values on 19 chromosomes, with r2 to the chr 4 lead SNP inside
# the zoom window (NA elsewhere); data_genotype.csv: DTI by lead-SNP genotype (256 accessions);
# data_allele.csv: tolerant-allele frequency per population. Run from this directory.
set.seed(20261012)
chr_len <- round(stats::runif(19, 18, 34) * 10) / 10
snp <- do.call(rbind, lapply(1:19, function(c) {
  n <- round(chr_len[c] * 22); data.frame(chr = c, pos = sort(stats::runif(n, 0, chr_len[c]))) }))
snp$p <- stats::runif(nrow(snp))^1.15
hit <- function(c, at, peak, w) {               # association peak: P falls off with distance to the causal site
  i <- snp$chr == c; d <- abs(snp$pos[i] - at)
  snp$p[i] <<- pmin(snp$p[i], 10^-(peak * exp(-(d / w)^2) + stats::runif(sum(i), -3, 0.5) * (d < 3 * w)))
}
hit(4, 12.3, 11.5, 0.6); hit(11, 20.1, 8.6, 0.5); hit(17, 6.8, 8.4, 0.4)
# denser SNPs inside the chr 4 zoom window (10.8-13.8 Mb), as from targeted resequencing
loc <- data.frame(chr = 4, pos = sort(stats::runif(150, 10.8, 13.8)))
d <- abs(loc$pos - 12.3)
loc$p <- pmin(stats::runif(nrow(loc))^1.15, 10^-(11.5 * exp(-(d / 0.6)^2) + stats::runif(nrow(loc), -3, 0.5) * (d < 1.8)))
snp <- rbind(snp[!(snp$chr == 4 & snp$pos > 10.8 & snp$pos < 13.8), ], loc)
snp <- snp[order(snp$chr, snp$pos), ]
snp$p <- pmax(snp$p, 1e-14)
w <- snp$chr == 4 & snp$pos > 10.8 & snp$pos < 13.8
lead_pos <- snp$pos[w][which.min(snp$p[w])]
snp$r2 <- NA
snp$r2[w] <- round(pmax(0, pmin(1, exp(-abs(snp$pos[w] - lead_pos) / 0.35) + stats::rnorm(sum(w), 0, 0.08))), 3)
snp$pos <- round(snp$pos, 4); snp$p <- signif(snp$p, 4)
utils::write.csv(snp, "data.csv", row.names = FALSE, na = "")
utils::write.csv(data.frame(chr = 1:19, length_mb = chr_len), "data_chr.csv", row.names = FALSE)

gt <- data.frame(genotype = rep(c("AA", "AG", "GG"), c(92, 118, 46)))
gt$dti <- round(0.42 + c(AA = 0, AG = 0.09, GG = 0.2)[gt$genotype] + stats::rnorm(nrow(gt), 0, 0.08), 3)
gt$jitter <- round(stats::runif(nrow(gt), -1, 1), 3)    # horizontal jitter of the raw points (-1 to 1)
utils::write.csv(gt, "data_genotype.csv", row.names = FALSE)

utils::write.csv(data.frame(population = c("W Eur", "Iberia", "Medit", "C Asia"), g_percent = c(18, 41, 57, 73)),
                 "data_allele.csv", row.names = FALSE)
