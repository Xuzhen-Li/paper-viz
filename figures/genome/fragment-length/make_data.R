# Three libraries: short ancient inserts, nucleosome-protected ancient, modern WGS.
set.seed(209)

draw_trunc <- function(n, fun, lo, hi) {
  out <- numeric(0)
  while (length(out) < n) {
    x <- fun(n)
    x <- x[x >= lo & x <= hi]
    out <- c(out, x)
  }
  round(out[seq_len(n)])
}

n <- 2000L
ancient <- draw_trunc(n, function(m) stats::rlnorm(m, log(48), 0.38), 30, 220)
nuc_short <- draw_trunc(round(n * 0.72), function(m) stats::rlnorm(m, log(58), 0.32), 30, 140)
nuc_long <- draw_trunc(n - length(nuc_short), function(m) stats::rnorm(m, 167, 14), 130, 230)
nucleosome <- sample(c(nuc_short, nuc_long))
modern <- draw_trunc(n, function(m) stats::rnorm(m, 280, 42), 80, 480)

df <- rbind(
  data.frame(library = "Ancient", length_bp = ancient),
  data.frame(library = "Nucleosome", length_bp = nucleosome),
  data.frame(library = "Modern", length_bp = modern)
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv bytes ", file.info("data.csv")$size)
