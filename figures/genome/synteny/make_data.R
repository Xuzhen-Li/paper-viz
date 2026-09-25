# Two genomes, four chromosomes, 25 synteny blocks and 800 anchors.
set.seed(302)

chr_a <- c(82, 64, 53, 41) * 1e6
chr_b <- c(79, 67, 50, 44) * 1e6
n_chr <- 4L

# mostly collinear blocks, a few inversions and translocations
block_spec <- data.frame(
  block = sprintf("B%02d", 1:25),
  chr_i = c(1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 1, 2, 3, 4),
  chr_j = c(1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 2, 4, 1, 2),
  strand = c(1, 1, -1, 1, 1, 1, 1, 1, 1, -1, 1, 1, 1, -1, 1, 1, 1, 1, 1, -1, 1, 1, -1, 1, 1)
)

rows <- list()
for (i in seq_len(n_chr)) {
  rows[[length(rows) + 1L]] <- data.frame(
    genome = "A", chr = sprintf("A%d", i), start = 0, end = chr_a[i],
    block = "", identity = NA_real_, stringsAsFactors = FALSE
  )
  rows[[length(rows) + 1L]] <- data.frame(
    genome = "B", chr = sprintf("B%d", i), start = 0, end = chr_b[i],
    block = "", identity = NA_real_, stringsAsFactors = FALSE
  )
}

anchors <- list()
for (k in seq_len(nrow(block_spec))) {
  i <- block_spec$chr_i[k]
  j <- block_spec$chr_j[k]
  # place along a soft diagonal with jitter, leave telomere margins
  center <- (k %% 6) / 6
  if (center < 0.08) center <- 0.12
  wa <- round(runif(1, 7e6, 12e6))
  wb <- round(wa * runif(1, 0.85, 1.12))
  sa <- round(stats::quantile(seq(0.08 * chr_a[i], 0.88 * chr_a[i] - wa), probs = (sum(block_spec$chr_i[seq_len(k)] == i) - 0.5) / max(1, sum(block_spec$chr_i == i))))
  sb <- round(stats::quantile(seq(0.08 * chr_b[j], 0.88 * chr_b[j] - wb), probs = (sum(block_spec$chr_j[seq_len(k)] == j) - 0.5) / max(1, sum(block_spec$chr_j == j))))
  sa <- max(0, min(sa, chr_a[i] - wa))
  sb <- max(0, min(sb, chr_b[j] - wb))
  # small independent jitter so blocks are not a perfect ladder
  sa <- max(0, min(chr_a[i] - wa, sa + round(rnorm(1, 0, 0.4e6))))
  sb <- max(0, min(chr_b[j] - wb, sb + round(rnorm(1, 0, 0.5e6))))
  id_mean <- 76 + stats::rbeta(1, 2.1, 1.5) * 22
  if (block_spec$strand[k] < 0) {
    ea <- sa
    sa2 <- sa + wa
    eb <- sb + wb
    sb2 <- sb
  } else {
    sa2 <- sa
    ea <- sa + wa
    sb2 <- sb
    eb <- sb + wb
  }
  rows[[length(rows) + 1L]] <- data.frame(
    genome = "A", chr = sprintf("A%d", i), start = sa2, end = ea,
    block = block_spec$block[k], identity = round(id_mean, 2), stringsAsFactors = FALSE
  )
  rows[[length(rows) + 1L]] <- data.frame(
    genome = "B", chr = sprintf("B%d", j), start = sb2, end = eb,
    block = block_spec$block[k], identity = round(id_mean, 2), stringsAsFactors = FALSE
  )
  n_anc <- 32L
  for (a in seq_len(n_anc)) {
    # anchors wander inside the block (Gaussian around the block diagonal)
    u <- stats::rbeta(1, 2.2, 2.2)
    noise <- rnorm(1, 0, 0.03)
    ua <- min(0.98, max(0.02, u + noise))
    ub <- min(0.98, max(0.02, u + rnorm(1, 0, 0.025)))
    if (block_spec$strand[k] < 0) ub <- 1 - ub
    pa <- round(min(sa, sa + wa) + ua * wa)
    pb <- round(sb + ub * wb)
    ident <- min(99.6, max(72, id_mean + rnorm(1, 0, 2.4)))
    anchors[[length(anchors) + 1L]] <- data.frame(
      genome = "A", chr = sprintf("A%d", i), start = pa, end = pa,
      block = block_spec$block[k], identity = round(ident, 2), stringsAsFactors = FALSE
    )
    anchors[[length(anchors) + 1L]] <- data.frame(
      genome = "B", chr = sprintf("B%d", j), start = pb, end = pb,
      block = block_spec$block[k], identity = round(ident, 2), stringsAsFactors = FALSE
    )
  }
}

out <- rbind(do.call(rbind, rows), do.call(rbind, anchors))
utils::write.csv(out, "data.csv", row.names = FALSE)
