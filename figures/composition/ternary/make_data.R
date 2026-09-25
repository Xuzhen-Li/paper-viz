# Eighty points on a simplex, three overlapping Dirichlet clusters.
# Group is the generating cluster, not a threshold cut. Run from this directory.
set.seed(7075)
rdir <- function(n, alpha) {
  g <- sapply(alpha, function(a) stats::rgamma(n, shape = a, rate = 1))
  g / rowSums(g)
}
blocks <- list(
  data.frame(rdir(28, c(7.5, 2.1, 1.8)), group = "Cluster 1"),
  data.frame(rdir(27, c(1.9, 6.8, 2.2)), group = "Cluster 2"),
  data.frame(rdir(25, c(1.7, 2.0, 6.4)), group = "Cluster 3")
)
df <- do.call(rbind, blocks)
names(df)[1:3] <- c("a", "b", "c")
df$a <- round(df$a, 4)
df$b <- round(df$b, 4)
df$c <- round(df$c, 4)
s <- df$a + df$b + df$c
df$a <- df$a / s
df$b <- df$b / s
df$c <- df$c / s
utils::write.csv(df[, c("a", "b", "c", "group")], "data.csv", row.names = FALSE)
message("wrote data.csv")
