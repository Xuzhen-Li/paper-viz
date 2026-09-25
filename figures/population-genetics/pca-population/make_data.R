# Simulated individual PCA scores for six plant populations.
set.seed(101)
pop_n <- c(
  "Wild N" = 14, "Wild S" = 14, "Landrace E" = 14,
  "Landrace W" = 13, "Cultivar A" = 13, "Cultivar B" = 12
)
centers <- rbind(
  "Wild N" = c(5.2, 2.3, 0.4),
  "Wild S" = c(3.9, -2.6, 0.8),
  "Landrace E" = c(0.6, 1.8, -1.1),
  "Landrace W" = c(-0.6, -1.6, 1.4),
  "Cultivar A" = c(-4.4, 0.5, -0.3),
  "Cultivar B" = c(-3.4, -0.9, 0.9)
)
sds <- c(
  "Wild N" = 0.72, "Wild S" = 0.80, "Landrace E" = 0.56,
  "Landrace W" = 0.62, "Cultivar A" = 0.32, "Cultivar B" = 0.30
)
prefix <- c(
  "Wild N" = "WN", "Wild S" = "WS", "Landrace E" = "LE",
  "Landrace W" = "LW", "Cultivar A" = "CA", "Cultivar B" = "CB"
)
rows <- lapply(names(pop_n), function(p) {
  n <- pop_n[[p]]
  z <- matrix(rnorm(n * 3, sd = sds[[p]]), ncol = 3)
  z[, 2] <- 0.30 * z[, 1] + z[, 2]
  sc <- sweep(z, 2, centers[p, ], "+")
  data.frame(
    sample = sprintf("%s_%02d", prefix[[p]], seq_len(n)),
    pop = p, PC1 = sc[, 1], PC2 = sc[, 2], PC3 = sc[, 3],
    stringsAsFactors = FALSE
  )
})
df <- do.call(rbind, rows)
v <- apply(df[, c("PC1", "PC2", "PC3")], 2, stats::var)
ve <- round(v / sum(v) * 36.4, 1)
df$var_explained <- ve[["PC1"]]
utils::write.csv(df, "data.csv", row.names = FALSE)
utils::write.csv(
  data.frame(pc = names(ve), var_explained = as.numeric(ve), stringsAsFactors = FALSE),
  "data_variance.csv", row.names = FALSE
)
message("wrote data.csv")
