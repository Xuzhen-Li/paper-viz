# Noisy composition shares for a donut chart. Run from this directory.
set.seed(7207)
parts <- c("Alpha", "Beta", "Gamma", "Delta", "Epsilon")
# Base rates + multiplicative noise so shares are unequal but realistic
raw <- stats::rexp(length(parts), rate = c(0.55, 0.9, 1.4, 2.1, 2.8))
raw <- raw * stats::runif(length(parts), 0.85, 1.15)
value <- round(100 * raw / sum(raw), 2)
# Tiny residual so sum is exactly 100 after rounding
value[length(value)] <- round(100 - sum(value[-length(value)]), 2)
utils::write.csv(
  data.frame(part = parts, value = value),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv parts=", length(parts))
