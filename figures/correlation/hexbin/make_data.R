# Dense bivariate cloud for hexbin. Run from this directory.
set.seed(71)
n <- 3200
# Two overlapping elliptical clouds + mild heteroscedastic noise
g <- sample(c(1L, 2L), n, replace = TRUE, prob = c(0.62, 0.38))
x <- ifelse(g == 1L, stats::rnorm(n, 0.2, 1.15), stats::rnorm(n, 1.6, 0.85))
y <- 0.35 + 0.72 * x + ifelse(g == 1L, stats::rnorm(n, 0, 0.95), stats::rnorm(n, 0.4, 0.7))
y <- y + 0.08 * x^2 * stats::rnorm(n, 1, 0.12)
utils::write.csv(
  data.frame(x = round(x, 4), y = round(y, 4)),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv rows=", n)
