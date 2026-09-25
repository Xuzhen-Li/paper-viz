# Thirty sampling sites. x = longitude, y = latitude.
set.seed(110)
pops <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
centers <- rbind(
  "Wild N" = c(114, 38.5),
  "Wild S" = c(110, 25.0),
  "Landrace E" = c(118.5, 32.5),
  "Landrace W" = c(106.5, 33.0),
  "Cultivar A" = c(114.5, 33.5),
  "Cultivar B" = c(117.0, 30.0)
)
spread <- c(1.3, 1.5, 1.6, 1.5, 1.8, 1.7)
n_site <- 5L
rows <- lapply(seq_along(pops), function(i) {
  p <- pops[i]
  data.frame(
    site = sprintf("%s%d", c("WN", "WS", "LE", "LW", "CA", "CB")[i], seq_len(n_site)),
    pop = p,
    x = centers[p, 1] + rnorm(n_site, 0, spread[i] * 0.7),
    y = centers[p, 2] + rnorm(n_site, 0, spread[i] * 0.45),
    n = sample(c(8, 12, 16, 20, 24, 32), n_site, replace = TRUE),
    stringsAsFactors = FALSE
  )
})
df <- do.call(rbind, rows)
# keep sites on land-ish box
df$x <- pmin(124, pmax(103, df$x))
df$y <- pmin(42, pmax(22, df$y))
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
