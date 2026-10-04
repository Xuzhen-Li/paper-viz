# Three cell-line clouds along a positive slope. The upper-left stays empty.
# Run from this directory.
set.seed(814)
n_per <- 48
group <- rep(c("MCF7", "A549", "HepG2"), each = n_per)
center_x <- c(MCF7 = 1.55, A549 = 3.85, HepG2 = 6.15)
center_y <- c(MCF7 = 2.05, A549 = 4.15, HepG2 = 5.85)
slope <- c(MCF7 = 0.72, A549 = 0.64, HepG2 = 0.58)
x <- stats::rnorm(length(group), mean = center_x[group], sd = 0.42)
y <- center_y[group] + slope[group] * (x - center_x[group]) +
  stats::rnorm(length(group), sd = 0.28)
utils::write.csv(
  data.frame(x = round(x, 4), y = round(y, 4), group = group),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
