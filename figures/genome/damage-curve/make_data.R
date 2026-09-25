# Ancient-DNA misincorporation: 5' C>T and 3' G>A, no-UDG vs half-UDG.
set.seed(208)

libs <- c("no-UDG", "half-UDG")
ends <- c("5'", "3'")
subs <- c("C>T", "G>A")
positions <- 1:25

base_rate <- function(lib, end, sub, pos) {
  bg <- 0.007
  terminal <- (end == "5'" && sub == "C>T") || (end == "3'" && sub == "G>A")
  if (lib == "no-UDG") {
    if (terminal) {
      peak <- if (sub == "C>T") 0.31 else 0.28
      lam <- if (sub == "C>T") 3.6 else 3.9
      bg + (peak - bg) * exp(-(pos - 1) / lam)
    } else {
      0.01 + 0.008 * exp(-(pos - 1) / 6)
    }
  } else if (terminal) {
    ifelse(pos == 1, 0.17, ifelse(pos == 2, 0.028, bg))
  } else {
    bg
  }
}

rows <- list()
for (lib in libs) {
  for (end in ends) {
    for (sub in subs) {
      rate <- base_rate(lib, end, sub, positions) + stats::rnorm(25, 0, 0.0035)
      rate <- pmax(0, rate)
      rows[[length(rows) + 1L]] <- data.frame(
        library = lib,
        end = end,
        pos = positions,
        rate = round(rate, 4),
        substitution = sub
      )
    }
  }
}
df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
