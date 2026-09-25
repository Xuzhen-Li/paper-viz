# Structural variants at least 50 bp. Insertions carry an LTR-sized mode.
set.seed(210)

draw_sv <- function(n, means, sds, probs) {
  out <- numeric(0)
  while (length(out) < n) {
    k <- sample.int(length(means), n, replace = TRUE, prob = probs)
    x <- stats::rlnorm(n, log(means[k]), sds[k])
    x <- x[x >= 50 & x <= 2e7]
    out <- c(out, x)
  }
  round(out[seq_len(n)])
}

n <- 400L
df <- rbind(
  data.frame(sv_type = "DEL", size_bp = draw_sv(n, c(320, 8000), c(0.7, 0.38), c(0.7, 0.3))),
  data.frame(sv_type = "INS", size_bp = draw_sv(n, c(200, 9200), c(0.6, 0.28), c(0.35, 0.65))),
  data.frame(sv_type = "DUP", size_bp = draw_sv(n, c(22000), c(0.95), c(1))),
  data.frame(sv_type = "INV", size_bp = draw_sv(n, c(480000), c(1.1), c(1)))
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
