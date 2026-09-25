# Continuous effect, significance, and cohort size. Colour groups overlap.
# Run from this directory.
set.seed(513)
n <- 40
group <- sample(c("Liver", "Lung", "Kidney", "Brain"), n, replace = TRUE)
shift <- c(Liver = 0.15, Lung = -0.2, Kidney = 0.35, Brain = -0.05)
x <- stats::rnorm(n, 0, 1.05) + shift[group]
y <- abs(0.55 * x + stats::rnorm(n, 1.35, 0.7))
size <- stats::rlnorm(n, meanlog = 3.3, sdlog = 0.38)
utils::write.csv(
  data.frame(x = x, y = y, size = round(size), group = group),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
