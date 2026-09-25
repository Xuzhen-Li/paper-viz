# Overlapping marker scores. Case/control is a noisy outcome, not a cut on the score.
# Run from this directory.
set.seed(524)
n <- 200
subject <- sprintf("P%03d", seq_len(n))
risk <- stats::rnorm(n)
t_event <- stats::rexp(n, rate = exp(-2.6 + 0.5 * risk))
t_censor <- stats::runif(n, 12, 48)
time <- pmin(t_event, t_censor)
label <- as.integer(t_event <= t_censor)
load <- c(AFP = 1.15, DCP = 0.62, ALT = 0.28)
rows <- lapply(names(load), function(m) {
  score <- 0.15 + load[[m]] * risk + stats::rnorm(n, 0, 1)
  data.frame(subject = subject, marker = m, score = score, label = label, time = time)
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
