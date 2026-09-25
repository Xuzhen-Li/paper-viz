# Eight items, six time points. Ranks move by a few adjacent swaps, not a reshuffle.
# Run from this directory.
set.seed(7078)
items <- c("TP53", "KRAS", "EGFR", "PIK3CA", "PTEN", "BRAF", "APC", "IDH1")
times <- paste0("T", 1:6)
order_now <- items
rows <- list(data.frame(item = order_now, time = times[1], rank = seq_along(order_now)))
for (t in 2:6) {
  n_swap <- sample(1:3, 1)
  for (s in seq_len(n_swap)) {
    i <- sample(seq_len(length(order_now) - 1), 1)
    order_now[c(i, i + 1)] <- order_now[c(i + 1, i)]
  }
  rows[[t]] <- data.frame(item = order_now, time = times[t], rank = seq_along(order_now))
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
