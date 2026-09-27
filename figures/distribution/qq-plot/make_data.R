# Simulated sample for a normal QQ diagnostic. Run from this directory.
set.seed(27)
n <- 400
# Mostly normal with light heavy-tail contamination for visible departure.
core <- rnorm(round(0.92 * n), mean = 0.15, sd = 1.05)
tail <- rt(n - length(core), df = 4) * 1.1 + 0.15
value <- sample(c(core, tail))
value <- value + rnorm(n, 0, 0.04)
utils::write.csv(
  data.frame(sample = sprintf("O%03d", seq_len(n)), value = round(value, 6)),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
