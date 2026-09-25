# OPLS-DA scores plus a permutation null. Group colour is applied in plot.R.
# Run from this directory.
set.seed(62)
n <- 40
group <- rep(c("Control", "Case"), each = n / 2)
# Predictive axis separates groups; orthogonal axis does not.
pred <- ifelse(group == "Case", 1.15, -1.05) + stats::rnorm(n, 0, 0.72)
ortho <- stats::rnorm(n, ifelse(group == "Case", 0.15, -0.1), 1.05)
# A few samples sit across the boundary.
pred[c(8, 19, 27)] <- pred[c(8, 19, 27)] * 0.15

utils::write.csv(
  data.frame(
    sample = sprintf("S%02d", seq_len(n)),
    group = group,
    pred = round(pred, 3),
    ortho = round(ortho, 3)
  ),
  "data.csv",
  row.names = FALSE,
  quote = FALSE
)

# perm == 1 is the unpermuted model; the rest are a null.
q2 <- c(0.71, stats::rnorm(99, -0.08, 0.16))
q2 <- pmin(q2, 0.85)
utils::write.csv(
  data.frame(perm = seq_along(q2), q2 = round(q2, 3)),
  "data_perm.csv",
  row.names = FALSE,
  quote = FALSE
)
message("wrote data.csv and data_perm.csv")
