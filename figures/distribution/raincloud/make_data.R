# Four overlapping response groups. Run from this directory.
set.seed(42)
spec <- data.frame(
  group = c("Ctrl", "Low", "Mid", "High"),
  n = c(38, 38, 37, 37),
  mu = c(2.05, 2.55, 3.35, 4.7),
  sd = c(0.42, 0.55, 0.62, 0.7),
  stringsAsFactors = FALSE
)
parts <- lapply(seq_len(nrow(spec)), function(i) {
  n <- spec$n[i]
  base <- rnorm(n, spec$mu[i], spec$sd[i])
  if (spec$group[i] == "Mid") base <- base + rbinom(n, 1, 0.35) * rnorm(n, 0.8, 0.25)
  data.frame(
    sample = sprintf("%s%02d", substring(spec$group[i], 1, 1), seq_len(n)),
    group = spec$group[i],
    value = base,
    stringsAsFactors = FALSE
  )
})
utils::write.csv(do.call(rbind, parts), "data.csv", row.names = FALSE)
message("wrote data.csv")
