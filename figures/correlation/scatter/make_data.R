# Overlapping expression clouds. Group colour is assigned in plot.R.
# Run from this directory.
set.seed(511)
n <- 120
group <- rep(c("MCF7", "A549", "HepG2"), each = 40)
center <- c(MCF7 = 6.1, A549 = 7.3, HepG2 = 5.7)
shift <- c(MCF7 = 0, A549 = 0.45, HepG2 = -0.3)
x <- stats::rnorm(n, mean = center[group], sd = 0.9)
y <- 1.4 + 0.7 * x + shift[group] + stats::rnorm(n, 0, 0.72)
utils::write.csv(
  data.frame(x = x, y = y, group = group),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
