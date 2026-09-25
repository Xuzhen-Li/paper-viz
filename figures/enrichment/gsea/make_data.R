# Ranked list and running enrichment scores. Hits are biased, not truncated.
# Run from this directory.
set.seed(519)
n <- 500
metric <- sort(seq(2.4, -2.2, length.out = n) + stats::rnorm(n, 0, 0.12), decreasing = TRUE)
running_es <- function(hit, weight) {
  hit_w <- ifelse(hit, abs(weight), 0)
  hit_w <- hit_w / sum(hit_w)
  miss <- ifelse(hit, 0, 1 / (n - sum(hit)))
  cumsum(hit_w - miss)
}
pick <- function(prob, k) {
  ix <- integer()
  pr <- prob
  for (i in seq_len(k)) {
    pr <- pr / sum(pr)
    j <- sample.int(n, 1, prob = pr)
    ix <- c(ix, j)
    pr[j] <- 0
  }
  ix
}
sets <- list(
  "Interferon response" = pick(stats::plogis(1.4 * metric), 42),
  "Oxidative phosphorylation" = pick(stats::plogis(-1.15 * metric), 38)
)
rows <- lapply(names(sets), function(s) {
  hit <- rep(0, n)
  hit[sets[[s]]] <- 1
  data.frame(
    set = s,
    rank = seq_len(n),
    es = running_es(hit == 1, metric),
    hit = hit,
    metric = metric
  )
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
