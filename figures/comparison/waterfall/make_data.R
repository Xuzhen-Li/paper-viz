# Waterfall increments for a contribution bridge. Run from this directory.
set.seed(47)
opening <- round(runif(1, 88, 112), 1)
step_labels <- c(
  "New sales", "Upsell", "Price mix", "Returns", "Discounts", "OpEx"
)
deltas <- c(
  round(rnorm(1, 28, 4.5), 1),
  round(rnorm(1, 14, 3.2), 1),
  round(rnorm(1, 6.5, 2.1), 1),
  -round(abs(rnorm(1, 9, 2.4)), 1),
  -round(abs(rnorm(1, 7.5, 2.0)), 1),
  -round(abs(rnorm(1, 11, 2.8)), 1)
)
deltas <- round(deltas + rnorm(length(deltas), 0, 0.6), 1)
labels <- c("Opening", step_labels, "Closing")
kinds <- c("total", rep("step", length(deltas)), "total")
values <- c(opening, deltas, opening + sum(deltas))
df <- data.frame(
  label = labels,
  kind = kinds,
  value = round(values, 1),
  stringsAsFactors = FALSE
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
