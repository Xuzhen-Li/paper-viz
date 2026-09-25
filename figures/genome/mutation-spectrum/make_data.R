# SBS96 channels. CpG C>T and a softer T>C background, plus negative-binomial noise.
# Run from this directory.
set.seed(7081)
subs <- c("C>A", "C>G", "C>T", "T>A", "T>G", "T>C")
flank <- c("A", "C", "G", "T")
left <- rep(flank, each = 4)
right <- rep(flank, times = 4)
rows <- vector("list", 96)
k <- 1L
for (sub in subs) {
  mid <- substr(sub, 1, 1)
  for (i in seq_along(left)) {
    ctx <- paste0(left[i], mid, right[i])
    mu <- 8
    if (sub == "C>T" && right[i] == "G") mu <- 46
    if (sub == "C>T" && right[i] != "G") mu <- 14
    if (sub == "C>A") mu <- 11
    if (sub == "T>C") mu <- 18
    if (sub == "C>G") mu <- 4
    rows[[k]] <- data.frame(
      context = ctx,
      substitution = sub,
      count = as.integer(stats::rnbinom(1, mu = mu, size = 6))
    )
    k <- k + 1L
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
