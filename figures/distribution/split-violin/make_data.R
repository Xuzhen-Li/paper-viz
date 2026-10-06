# Two conditions across four tissues. Simulated expression. Run from this directory.
set.seed(615)

group_levels <- c("Liver", "Lung", "Kidney", "Spleen")
condition_levels <- c("Control", "Treated")
mu <- rbind(
  Liver = c(Control = 4.15, Treated = 5.45),
  Lung = c(Control = 3.55, Treated = 4.05),
  Kidney = c(Control = 4.85, Treated = 6.35),
  Spleen = c(Control = 4.40, Treated = 4.85)
)
sdev <- rbind(
  Liver = c(Control = 0.48, Treated = 0.62),
  Lung = c(Control = 0.42, Treated = 0.55),
  Kidney = c(Control = 0.50, Treated = 0.58),
  Spleen = c(Control = 0.45, Treated = 0.40)
)
n <- 36L
rows <- lapply(seq_along(group_levels), function(i) {
  g <- group_levels[[i]]
  do.call(rbind, lapply(seq_along(condition_levels), function(j) {
    cond <- condition_levels[[j]]
    k <- (i - 1L) * length(condition_levels) + j
    data.frame(
      sample = sprintf("S%03d", (k - 1L) * n + seq_len(n)),
      group = g,
      condition = cond,
      value = round(stats::rnorm(n, mu[g, cond], sdev[g, cond]), 3),
      stringsAsFactors = FALSE
    )
  }))
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
