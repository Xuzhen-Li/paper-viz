# Four lines scored on six traits. Run from this directory.
set.seed(52)
axes <- c("Growth", "Stress", "Yield", "Size", "Color", "Firm")
groups <- c("Line A", "Line B", "Line C", "Line D")
profile <- rbind(
  c(78, 42, 70, 66, 55, 48),
  c(46, 74, 40, 52, 63, 71),
  c(62, 58, 81, 44, 37, 59),
  c(35, 49, 55, 77, 72, 33)
)
value <- as.vector(t(profile)) + rnorm(length(profile), 0, 2.5)
value <- pmin(96, pmax(12, value))
utils::write.csv(
  data.frame(
    group = rep(groups, each = length(axes)),
    axis = rep(axes, times = length(groups)),
    value = round(value, 1)
  ),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
