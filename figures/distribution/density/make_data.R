# Four overlapping measurement densities. Run from this directory.
set.seed(45)
spec <- data.frame(
  group = c("Line A", "Line B", "Line C", "Line D"),
  mu = c(0.2, 1.35, 2.7, 4.15),
  sd = c(0.48, 0.62, 0.5, 0.7),
  stringsAsFactors = FALSE
)
parts <- lapply(seq_len(nrow(spec)), function(i) {
  value <- rnorm(300, spec$mu[i], spec$sd[i])
  if (i == 2) value <- ifelse(runif(300) < 0.22, rnorm(300, spec$mu[i] + 1.1, 0.28), value)
  data.frame(group = spec$group[i], value = value, stringsAsFactors = FALSE)
})
utils::write.csv(do.call(rbind, parts), "data.csv", row.names = FALSE)
message("wrote data.csv")
