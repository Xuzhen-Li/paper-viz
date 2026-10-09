# Simulated sugar accumulation (°Brix) in three grape groups, 6 vines each. Run from this directory.
set.seed(20261009)
daf <- seq(21, 119, by = 7)
pars <- list(Wild = c(17.5, 66, 8.5), Wine = c(25.0, 76, 8.0), Table = c(19.5, 70, 7.5))
d <- do.call(rbind, lapply(names(pars), function(g) {
  p <- pars[[g]]
  do.call(rbind, lapply(1:6, function(v) data.frame(
    group = g, vine = v, days_after_flowering = daf,
    brix = round(4 + (p[1] - 4) / (1 + exp(-(daf - p[2]) / p[3])) +
                   stats::rnorm(length(daf), 0, 0.55 + 0.012 * daf), 2))))
}))
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
