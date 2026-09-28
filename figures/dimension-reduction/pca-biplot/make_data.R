# Simulated PC scores for three populations. Run from this directory.
set.seed(2)
mk <- function(name, n, mean, sd) {
  pts <- matrix(rnorm(n * 2, mean = 0, sd = 1), ncol = 2)
  pts[, 1] <- pts[, 1] * sd[1] + mean[1]
  pts[, 2] <- pts[, 2] * sd[2] + mean[2]
  data.frame(
    sample = NA_character_,
    group = name,
    pc1 = pts[, 1],
    pc2 = pts[, 2],
    stringsAsFactors = FALSE
  )
}
parts <- list(
  mk("Pop1", 40, c(-1, 0), c(0.35, 0.35)),
  mk("Pop2", 40, c(1, 0.2), c(0.4, 0.4)),
  mk("Pop3", 30, c(0, 1.2), c(0.3, 0.3))
)
df <- do.call(rbind, parts)
df$sample <- sprintf("S%03d", seq_len(nrow(df)))
df$pc1 <- round(df$pc1, 6)
df$pc2 <- round(df$pc2, 6)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
