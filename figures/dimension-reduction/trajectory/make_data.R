# Branched pseudotime embedding. Colour choice is made in plot.R.
# Run from this directory.
set.seed(63)
n <- 300
pseudotime <- stats::rbeta(n, 1.35, 1.15)
pseudotime <- round(pseudotime, 4)
branch_at <- 0.46
fate <- sample(c("fate-a", "fate-b"), n, replace = TRUE, prob = c(0.56, 0.44))
# Membership is noisy around the branch point rather than a hard cut in the plane.
trunk_p <- stats::plogis((branch_at - pseudotime) / 0.035)
branch <- ifelse(stats::runif(n) < trunk_p, "trunk", fate)

dim1 <- 8.5 * pseudotime + stats::rnorm(n, 0, 0.28 + 0.22 * pseudotime)
progress <- pmax(pseudotime - branch_at, 0)
dim2 <- 1.6 * sin(pseudotime * pi * 0.85)
dim2 <- dim2 + ifelse(branch == "fate-a", 4.2 * progress, ifelse(branch == "fate-b", -3.6 * progress, 0.15 * progress))
dim2 <- dim2 + stats::rnorm(n, 0, 0.26)

utils::write.csv(
  data.frame(
    cell = sprintf("cell%03d", seq_len(n)),
    dim1 = round(dim1, 3),
    dim2 = round(dim2, 3),
    pseudotime = pseudotime,
    branch = branch
  ),
  "data.csv",
  row.names = FALSE,
  quote = FALSE
)
message("wrote data.csv")
