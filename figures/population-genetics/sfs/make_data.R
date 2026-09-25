# Folded and unfolded site-frequency spectra (downsampled to 40 chromosomes).
set.seed(109)
pops <- c("Wild N", "Landrace E", "Cultivar A")
# Folded MAC 1..20. Wild is L-shaped; cultivar is flatter after a bottleneck.
folded_w <- function(mac, rare, mid) {
  base <- (1 / mac + 1 / (40 - mac))
  base * (1 + rare * exp(-mac / 3) + mid * exp(-((mac - 8)^2) / 18))
}
shape <- list(
  "Wild N" = c(rare = 1.4, mid = 0.05),
  "Landrace E" = c(rare = 0.6, mid = 0.35),
  "Cultivar A" = c(rare = 0.05, mid = 0.9)
)
# Unfolded derived counts 1..20 on the same grid: excess of rare derived alleles,
# plus a small high-frequency bump from ancestral mispolarization (cultivar stronger).
unfolded_w <- function(bin, rare, high) {
  (1 / bin) * (1 + rare) + high * exp(-((bin - 18)^2) / 8)
}
rows <- lapply(pops, function(p) {
  mac <- 1:20
  fw <- folded_w(mac, shape[[p]]["rare"], shape[[p]]["mid"])
  uw <- unfolded_w(mac, shape[[p]]["rare"], 0.15 + 0.35 * shape[[p]]["mid"])
  fc <- as.numeric(rmultinom(1, 40000, fw / sum(fw)))
  uc <- as.numeric(rmultinom(1, 40000, uw / sum(uw)))
  rbind(
    data.frame(pop = p, bin = mac, count = fc, folded = 1),
    data.frame(pop = p, bin = mac, count = uc, folded = 0)
  )
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
