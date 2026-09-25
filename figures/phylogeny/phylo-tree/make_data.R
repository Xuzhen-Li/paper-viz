# 40-tip coalescent tree, four population groups, bootstrap on internal nodes.
set.seed(304)

# four monophyletic populations on a short balanced backbone
pop_names <- c("North", "South", "East", "West")
subs <- lapply(seq_len(4), function(i) {
  labs <- sprintf("T%02d", (i - 1L) * 10L + seq_len(10))
  t <- ape::rcoal(10, tip.label = labs)
  t$edge.length <- t$edge.length * 0.42
  t
})
tr <- ape::stree(4, type = "balanced")
tr$edge.length <- c(0.10, 0.10, 0.16, 0.16, 0.07, 0.07)
tr$tip.label <- paste0("g", 1:4)
for (i in 4:1) {
  wh <- which(tr$tip.label == paste0("g", i))
  tr <- ape::bind.tree(tr, subs[[i]], where = wh)
}
tr <- ape::ladderize(tr)
grp <- setNames(rep(pop_names, each = 10), sprintf("T%02d", 1:40))

n_tip <- length(tr$tip.label)
nm <- function(i) {
  if (i <= n_tip) tr$tip.label[i] else sprintf("N%d", i)
}
bs <- rep(NA_real_, nrow(tr$edge))
is_int <- tr$edge[, 2] > n_tip
bs[is_int] <- round(stats::rbeta(sum(is_int), 7, 1.6) * 40 + 60)

out <- data.frame(
  tip = vapply(tr$edge[, 2], nm, character(1)),
  parent = vapply(tr$edge[, 1], nm, character(1)),
  length = round(tr$edge.length, 5),
  group = ifelse(tr$edge[, 2] <= n_tip, grp[tr$tip.label[tr$edge[, 2]]], NA_character_),
  bootstrap = bs,
  stringsAsFactors = FALSE
)
utils::write.csv(out, "data.csv", row.names = FALSE)
