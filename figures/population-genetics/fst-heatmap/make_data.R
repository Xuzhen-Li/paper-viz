# Pairwise Fst among 12 populations in geographic order.
set.seed(111)
pops <- c("WN1", "WN2", "WS1", "WS2", "LE1", "LE2", "LW1", "LW2", "CA1", "CA2", "CB1", "CB2")
g <- rep(0:5, each = 2)
n <- length(pops)
fst <- matrix(0, n, n, dimnames = list(pops, pops))
for (i in seq_len(n)) {
  for (j in seq_len(n)) {
    if (i == j) next
    wild_vs_cul <- (g[i] <= 1 && g[j] >= 4) || (g[j] <= 1 && g[i] >= 4)
    base <- 0.015 + 0.038 * abs(g[i] - g[j]) + if (wild_vs_cul) 0.06 else 0
    if (g[i] == g[j]) base <- 0.018
    fst[i, j] <- base + rnorm(1, 0, 0.008)
  }
}
fst <- (fst + t(fst)) / 2
diag(fst) <- 0
fst[fst < 0] <- 0
idx <- which(upper.tri(fst, diag = TRUE), arr.ind = TRUE)
utils::write.csv(
  data.frame(
    pop_a = pops[idx[, 1]], pop_b = pops[idx[, 2]],
    fst = round(fst[idx], 3), stringsAsFactors = FALSE
  ),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
