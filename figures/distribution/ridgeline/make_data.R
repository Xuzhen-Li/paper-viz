# Eight cohorts with shifted, overlapping scores. Run from this directory.
set.seed(43)
spec <- data.frame(
  group = paste0("C", 1:8),
  mu = c(0.15, 0.55, 0.7, 1.35, 1.5, 2.15, 2.45, 3.2),
  sd = c(0.38, 0.42, 0.7, 0.36, 0.48, 0.4, 0.33, 0.58),
  stringsAsFactors = FALSE
)
parts <- lapply(seq_len(nrow(spec)), function(i) {
  n <- 200
  value <- rnorm(n, spec$mu[i], spec$sd[i])
  if (i == 3) value <- value + ifelse(runif(n) < 0.3, rnorm(n, 0.9, 0.2), 0)
  data.frame(group = spec$group[i], value = value, stringsAsFactors = FALSE)
})
utils::write.csv(do.call(rbind, parts), "data.csv", row.names = FALSE)
message("wrote data.csv")
