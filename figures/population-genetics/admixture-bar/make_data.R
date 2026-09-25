# ADMIXTURE-like Q matrices, K = 2..6, six populations.
set.seed(102)
pops <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
n_per <- 20L
prefix <- c(WN = "Wild N", WS = "Wild S", LE = "Landrace E", LW = "Landrace W", CA = "Cultivar A", CB = "Cultivar B")
codes <- names(prefix)
samples <- unlist(lapply(codes, function(cd) sprintf("%s_%02d", cd, seq_len(n_per))))
sample_pop <- rep(pops, each = n_per)

# Rows follow pops. Values are ancestry means (sum to 1).
means <- list(
  "2" = rbind(
    c(0.90, 0.10),
    c(0.74, 0.26),
    c(0.42, 0.58),
    c(0.33, 0.67),
    c(0.08, 0.92),
    c(0.14, 0.86)
  ),
  "3" = rbind(
    c(0.84, 0.10, 0.06),
    c(0.12, 0.74, 0.14),
    c(0.22, 0.18, 0.60),
    c(0.14, 0.28, 0.58),
    c(0.05, 0.06, 0.89),
    c(0.07, 0.09, 0.84)
  ),
  "4" = rbind(
    c(0.80, 0.09, 0.06, 0.05),
    c(0.08, 0.76, 0.09, 0.07),
    c(0.10, 0.08, 0.70, 0.12),
    c(0.12, 0.16, 0.24, 0.48),
    c(0.04, 0.04, 0.08, 0.84),
    c(0.05, 0.06, 0.12, 0.77)
  ),
  "5" = rbind(
    c(0.78, 0.08, 0.06, 0.05, 0.03),
    c(0.07, 0.74, 0.08, 0.06, 0.05),
    c(0.08, 0.07, 0.68, 0.09, 0.08),
    c(0.10, 0.14, 0.20, 0.30, 0.26),
    c(0.03, 0.03, 0.06, 0.78, 0.10),
    c(0.04, 0.05, 0.07, 0.12, 0.72)
  ),
  "6" = rbind(
    c(0.74, 0.08, 0.06, 0.04, 0.04, 0.04),
    c(0.07, 0.70, 0.08, 0.06, 0.05, 0.04),
    c(0.07, 0.07, 0.64, 0.08, 0.07, 0.07),
    c(0.08, 0.10, 0.14, 0.48, 0.10, 0.10),
    c(0.03, 0.03, 0.05, 0.06, 0.74, 0.09),
    c(0.04, 0.04, 0.06, 0.07, 0.11, 0.68)
  )
)
conc <- c("Wild N" = 28, "Wild S" = 26, "Landrace E" = 22, "Landrace W" = 12, "Cultivar A" = 36, "Cultivar B" = 32)

rdir <- function(mu, concentration) {
  alpha <- pmax(mu * concentration, 0.08)
  g <- rgamma(length(alpha), shape = alpha, rate = 1)
  g / sum(g)
}

rows <- list()
for (ks in names(means)) {
  k <- as.integer(ks)
  mu <- means[[ks]]
  for (i in seq_along(samples)) {
    q <- rdir(mu[ceiling(i / n_per), ], conc[[sample_pop[i]]])
    rows[[length(rows) + 1L]] <- data.frame(
      sample = samples[i], pop = sample_pop[i], k = k,
      ancestry = paste0("A", seq_len(k)), q = q,
      stringsAsFactors = FALSE
    )
  }
}
df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
