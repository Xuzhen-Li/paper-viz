# One protein, eight domains, 25 mutations. Hotspots are a soft Gaussian mixture.
# Run from this directory.
set.seed(7080)
domains <- data.frame(
  domain = c("SP", "LBD", "Fn3", "TM", "JM", "Kinase", "C-lobe", "PEST"),
  start = c(1, 28, 142, 248, 271, 298, 512, 681),
  end = c(22, 128, 231, 268, 292, 498, 640, 724)
)
utils::write.csv(domains, "data_domains.csv", row.names = FALSE)

pos <- integer(0)
guard <- 0L
while (length(pos) < 25L && guard < 40L) {
  draw <- round(c(
    stats::rnorm(8, 78, 26),
    stats::rnorm(5, 186, 24),
    stats::rnorm(12, 392, 48),
    stats::rnorm(5, 575, 32),
    stats::rnorm(3, 700, 12)
  ))
  draw <- draw[draw >= 2 & draw <= 723]
  pos <- sort(unique(c(pos, draw)))
  guard <- guard + 1L
}
pos <- pos[seq_len(25)]
classes <- c("Missense", "Nonsense", "Frameshift", "Inframe")
class <- sample(classes, 25, replace = TRUE, prob = c(0.68, 0.14, 0.11, 0.07))
n <- rep(1L, 25)
hot <- sample.int(25, 6)
n[hot] <- stats::rnbinom(6, mu = 5.5, size = 2) + 2L
utils::write.csv(
  data.frame(pos = pos, class = class, n = n),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
