# D statistics with SE-consistent intervals. |Z| > 3 excludes 0.
set.seed(108)
tests <- c(
  "D(WN, CA; LE, OG)", "D(WN, CA; LW, OG)", "D(WS, CB; LE, OG)",
  "D(WS, CA; LW, OG)", "D(WN, LE; LW, OG)", "D(CA, CB; LE, OG)",
  "D(WN, WS; CA, OG)", "D(WN, WS; LE, OG)", "D(LE, LW; CA, OG)",
  "D(LE, LW; WN, OG)", "D(CA, WN; WS, OG)", "D(CB, WS; WN, OG)",
  "D(CA, LE; WN, OG)", "D(CB, LW; WS, OG)", "D(WN, LW; CA, OG)",
  "D(WS, LE; CB, OG)", "D(CA, CB; WN, OG)", "D(CA, CB; WS, OG)",
  "D(LE, CA; WS, OG)", "D(LW, CB; WN, OG)", "D(WN, CB; LW, OG)",
  "D(WS, CA; WN, OG)", "D(LE, WS; CA, OG)", "D(LW, WN; CB, OG)",
  "D(CA, WS; LW, OG)"
)
z <- c(
  6.4, 5.1, 4.6, 3.8, 3.2, -4.4,
  0.4, -0.8, 1.1, -1.4, 2.2, -2.4,
  5.6, 4.1, -3.5, 3.3, 0.6, -0.3,
  1.7, -4.8, 2.6, -1.1, 0.9, -3.6, 1.3
)
se <- 0.006 + runif(length(z), 0, 0.003)
estimate <- z * se
low <- estimate - 1.96 * se
high <- estimate + 1.96 * se
utils::write.csv(
  data.frame(
    test = tests, estimate = round(estimate, 5),
    low = round(low, 5), high = round(high, 5), z = round(z, 2)
  ),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
