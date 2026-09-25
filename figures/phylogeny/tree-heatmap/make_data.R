# 30-tip tree and 12 continuous traits with phylogenetic signal.
set.seed(305)

tr <- ape::ladderize(ape::rcoal(30, tip.label = sprintf("S%02d", 1:30)))
n_tip <- length(tr$tip.label)
nm <- function(i) if (i <= n_tip) tr$tip.label[i] else sprintf("N%d", i)
tree_rows <- data.frame(
  tip = vapply(tr$edge[, 2], nm, character(1)),
  parent = vapply(tr$edge[, 1], nm, character(1)),
  length = round(tr$edge.length, 5),
  trait = "",
  value = NA_real_,
  stringsAsFactors = FALSE
)
trait_names <- sprintf("T%02d", 1:12)
trait_rows <- list()
for (tn in trait_names) {
  sigma <- runif(1, 0.35, 0.9)
  vals <- ape::rTraitCont(tr, sigma = sigma)
  vals <- as.numeric(scale(vals)) + rnorm(n_tip, 0, 0.15)
  trait_rows[[tn]] <- data.frame(
    tip = tr$tip.label,
    parent = "",
    length = NA_real_,
    trait = tn,
    value = round(vals, 3),
    stringsAsFactors = FALSE
  )
}
out <- rbind(tree_rows, do.call(rbind, trait_rows))
utils::write.csv(out, "data.csv", row.names = FALSE)
