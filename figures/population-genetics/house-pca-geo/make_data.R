# Simulated genotypes (0/1/2) for 120 accessions (20 per region) from six regions; allele frequencies follow
# map position. SNPs are drawn independently (unlinked), the situation an LD-pruned panel approximates.
# Writes data.csv: sample, region, then 300 SNP columns. Run from this directory.
set.seed(20261012)
regions <- c("Iberia", "W Europe", "Balkans", "Caucasus", "Central Asia", "East Asia")   # west -> east
n_per <- 20; n_snp <- 300
# approximate map position of each region (longitude, latitude in degrees); allele frequencies follow both
lon <- c(-5, 3, 21, 44, 66, 112); lat <- c(40, 48, 43, 42, 42, 36)
x <- (lon - mean(lon)) / stats::sd(lon); y <- (lat - mean(lat)) / stats::sd(lat)
base_f <- stats::runif(n_snp, 0.15, 0.85)
b_lon <- stats::rnorm(n_snp, 0, 0.16); b_lat <- stats::rnorm(n_snp, 0, 0.13)
rows <- lapply(seq_along(regions), function(k) {
  f <- pmin(pmax(base_f + b_lon * x[k] + b_lat * y[k] + stats::rnorm(n_snp, 0, 0.02), 0.02), 0.98)
  g <- matrix(stats::rbinom(n_per * n_snp, 2, rep(f, each = n_per)), n_per, n_snp)
  data.frame(sample = sprintf("%s_%02d", gsub(" ", "", regions[k]), seq_len(n_per)), region = regions[k], g)
})
d <- do.call(rbind, rows)
names(d)[-(1:2)] <- sprintf("snp%03d", seq_len(n_snp))
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d), " snps=", n_snp)
