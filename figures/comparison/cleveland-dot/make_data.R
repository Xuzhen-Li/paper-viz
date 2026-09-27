# Multi-category indicator scores with two series. Run from this directory.
set.seed(63)
categories <- c(
  "Literacy", "Math score", "Science", "Attendance",
  "Graduation", "College ready", "STEM uptake", "Arts access",
  "Teacher ratio", "Digital access", "Parent engage", "Health screen"
)
n <- length(categories)
# Baseline ranks with correlated treatment lift and realistic noise
base <- round(runif(n, 42, 88), 1)
lift <- rnorm(n, mean = 6.5, sd = 4.2)
lift[c(3, 8, 11)] <- -abs(rnorm(3, 3.5, 1.5))
treat <- round(pmin(98, pmax(18, base + lift + rnorm(n, 0, 1.2))), 1)
df <- data.frame(
  category = rep(categories, each = 2),
  group = rep(c("Urban", "Rural"), times = n),
  value = as.vector(rbind(base, treat)),
  stringsAsFactors = FALSE
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
