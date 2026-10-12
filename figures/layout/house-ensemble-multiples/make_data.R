# Simulated trait response to ten selection regimes (house example). Fixed seed; writes data.csv.
# Each regime has n replicate lines followed for 80 generations; the response is the mean trait shift
# in phenotypic SD units. Control and the two relaxed regimes plateau; the rest rise roughly linearly.
set.seed(26)
gen <- 0:80
reg <- data.frame(
  regime = c("Control", "Weak", "Mild", "Mild, small N", "Moderate, relaxed", "Strong, relaxed",
             "Strong", "Very strong", "Moderate", "Fluctuating"),
  n      = c(15, 44, 43, 9, 10, 13, 40, 45, 13, 13),
  slope  = c(0.004, 0.013, 0.024, 0.030, 0.020, 0.022, 0.038, 0.050, 0.030, 0.032),
  plateau = c(TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
  noise  = c(0.18, 0.20, 0.18, 0.20, 0.22, 0.24, 0.20, 0.30, 0.18, 0.28)
)
rows <- lapply(seq_len(nrow(reg)), function(i) {
  r <- reg[i, ]
  do.call(rbind, lapply(seq_len(r$n), function(k) {
    b <- r$slope * exp(rnorm(1, 0, 0.25))
    mu <- if (r$plateau) b * 40 * (1 - exp(-gen / 25)) * (1 - 0.15 * pmax(gen - 50, 0) / 30) else b * gen
    y <- mu + as.numeric(stats::filter(rnorm(length(gen), 0, r$noise * 0.5), 0.6, "recursive"))
    data.frame(regime = r$regime, replicate = k, generation = gen, shift_sd = round(y - y[1], 2))
  }))
})
long <- do.call(rbind, rows)
# wide on disk (one row per replicate, columns g0..g80) keeps data.csv well under 200 KB
wide <- reshape(long, idvar = c("regime", "replicate"), timevar = "generation", direction = "wide", sep = "")
names(wide) <- sub("^shift_sd", "g", names(wide))
write.csv(wide, "data.csv", row.names = FALSE)
