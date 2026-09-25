# Twelve metrics at two stages, with a few large moves. Run from this directory.
set.seed(51)
item <- sprintf("P%02d", 1:12)
before <- seq(18, 82, length.out = 12) + rnorm(12, 0, 1.2)
shift <- rnorm(12, 1, 6)
shift[c(4, 7, 11)] <- c(18, -16, 14)
after <- pmin(96, pmax(8, before + shift))
utils::write.csv(
  data.frame(
    item = rep(item, times = 2),
    stage = rep(c("Before", "After"), each = 12),
    value = c(before, after)
  ),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
