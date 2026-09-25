# Ten-population drift tree, four migration edges, pairwise residuals.
set.seed(306)

pops <- c("P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10")
tr <- ape::ladderize(ape::rcoal(10, tip.label = pops))
# stretch a few branches so drift is uneven
tr$edge.length <- tr$edge.length * runif(nrow(tr$edge), 0.6, 1.8)
n_tip <- 10L
nm <- function(i) if (i <= n_tip) tr$tip.label[i] else sprintf("N%d", i)
tree_rows <- data.frame(
  pop = vapply(tr$edge[, 2], nm, character(1)),
  parent = vapply(tr$edge[, 1], nm, character(1)),
  drift = round(tr$edge.length, 4),
  mig_from = "",
  mig_to = "",
  weight = NA_real_,
  stringsAsFactors = FALSE
)
pairs <- list(c("P7", "P10"), c("P1", "P8"), c("P2", "P3"), c("P6", "P5"))
wts <- round(c(0.42, 0.28, 0.16, 0.09) + rnorm(4, 0, 0.015), 3)
wts <- pmin(0.55, pmax(0.05, wts))
mig_rows <- data.frame(
  pop = "",
  parent = "",
  drift = NA_real_,
  mig_from = vapply(pairs, `[[`, character(1), 1),
  mig_to = vapply(pairs, `[[`, character(1), 2),
  weight = wts,
  stringsAsFactors = FALSE
)
utils::write.csv(rbind(tree_rows, mig_rows), "data.csv", row.names = FALSE)

# residual-like matrix: small values, a few larger cells near migration pairs
res <- matrix(rnorm(100, 0, 0.35), 10, 10, dimnames = list(pops, pops))
diag(res) <- 0
res <- (res + t(res)) / 2
for (pr in pairs) res[pr[1], pr[2]] <- res[pr[2], pr[1]] <- res[pr[1], pr[2]] + 2.2
res_df <- as.data.frame(as.table(res), stringsAsFactors = FALSE)
names(res_df) <- c("pop_a", "pop_b", "residual")
res_df$residual <- round(res_df$residual, 3)
utils::write.csv(res_df, "data_residual.csv", row.names = FALSE)
