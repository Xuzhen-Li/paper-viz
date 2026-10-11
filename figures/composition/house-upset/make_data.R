# Simulated drought-responsive genes in five grapevine tissues: one row per gene, 1 = responsive
# in that tissue. Genes responsive in no tissue are dropped. Run from this directory.
set.seed(20261011)
sets <- c("Leaf", "Root", "Berry skin", "Berry flesh", "Seed")
p <- c(0.34, 0.27, 0.20, 0.14, 0.09)      # per-tissue response rate
n <- 2600
m <- sapply(p, function(pp) stats::rbinom(n, 1, pp))
# a planted core: genes that respond everywhere, and a skin + flesh berry module
m[1:28, ] <- 1L
m[29:110, ] <- 0L; m[29:110, 3:4] <- 1L
colnames(m) <- sets
keep <- rowSums(m) > 0
d <- data.frame(gene = sprintf("VIT_%05d", which(keep)), m[keep, ], check.names = FALSE)
names(d) <- c("gene", "leaf", "root", "berry_skin", "berry_flesh", "seed")
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
