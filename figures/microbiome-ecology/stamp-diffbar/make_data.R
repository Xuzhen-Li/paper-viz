# 25 taxa, mean proportion difference with a CI that sometimes crosses zero.
set.seed(312)

taxa <- c(
  "Bacteroides", "Prevotella", "Faecalibacterium", "Lachnospira", "Roseburia",
  "Blautia", "Ruminococcus", "Alistipes", "Bifidobacterium", "Akkermansia",
  "Escherichia", "Clostridium", "Dialister", "Parabacteroides", "Coprococcus",
  "Subdoligranulum", "Phascolarctobacterium", "Sutterella", "Oscillospira", "Dorea",
  "Streptococcus", "Veillonella", "Megamonas", "Collinsella", "Holdemanella"
)
# soft differences, not a sorted staircase without noise
diff <- rnorm(25, 0, 0.045)
se <- runif(25, 0.008, 0.028)
# a few clearer shifts
diff[c(3, 7, 11, 18)] <- diff[c(3, 7, 11, 18)] + c(0.07, -0.06, 0.05, -0.055)
low <- diff - 1.96 * se
high <- diff + 1.96 * se
# two-sided p from the CI width, then jitter so it is not a perfect function of |diff|
z <- diff / se
p <- 2 * stats::pnorm(-abs(z))
p <- pmin(0.98, pmax(1e-4, p * exp(rnorm(25, 0, 0.15))))

out <- data.frame(
  taxon = taxa,
  diff = round(diff, 4),
  low = round(low, 4),
  high = round(high, 4),
  p = signif(p, 3),
  stringsAsFactors = FALSE
)
utils::write.csv(out, "data.csv", row.names = FALSE)
