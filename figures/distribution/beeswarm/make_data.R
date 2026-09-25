# Four groups of individual responses. Run from this directory.
set.seed(46)
spec <- data.frame(
  group = c("Ctrl", "Dose1", "Dose2", "Dose3"),
  mu = c(1.15, 1.45, 2.55, 2.85),
  sd = c(0.32, 0.38, 0.36, 0.48),
  stringsAsFactors = FALSE
)
parts <- lapply(seq_len(nrow(spec)), function(i) {
  data.frame(
    sample = sprintf("S%03d", (i - 1) * 30 + seq_len(30)),
    group = spec$group[i],
    value = rnorm(30, spec$mu[i], spec$sd[i]),
    stringsAsFactors = FALSE
  )
})
utils::write.csv(do.call(rbind, parts), "data.csv", row.names = FALSE)
message("wrote data.csv")
