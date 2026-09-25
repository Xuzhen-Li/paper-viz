# Six gene models: exons, UTRs, domains, point mutations. One locus has two isoforms.
set.seed(203)

place_exons <- function(n, L) {
  n_int <- n - 1L
  exon_mean <- L * 0.45 / n
  exons <- pmax(90, stats::rnorm(n, exon_mean, exon_mean * 0.22))
  introns <- stats::rexp(n_int, rate = 1 / (L * 0.55 / n_int))
  total <- sum(exons) + sum(introns)
  exons <- exons / total * L
  introns <- introns / total * L
  exons <- pmax(80, exons)
  total <- sum(exons) + sum(introns)
  exons <- exons * L / total
  introns <- introns * L / total
  starts <- numeric(n)
  pos <- 1
  for (i in seq_len(n)) {
    starts[i] <- pos
    pos <- pos + exons[i]
    if (i < n) pos <- pos + introns[i]
  }
  data.frame(start = round(starts), end = round(starts + exons - 1))
}

push <- function(rows, gene, feature, start, end, strand) {
  rows[[length(rows) + 1L]] <- data.frame(
    gene = gene, feature = feature, start = as.integer(start),
    end = as.integer(end), strand = strand
  )
  rows
}

spec <- data.frame(
  gene = c("Gene1", "Gene2.1", "Gene3", "Gene4", "Gene5", "Gene6"),
  strand = c("+", "+", "-", "+", "-", "+"),
  n_exon = c(5L, 6L, 4L, 8L, 7L, 5L),
  length_bp = c(4200L, 5600L, 3100L, 7800L, 6400L, 4800L),
  stringsAsFactors = FALSE
)

rows <- list()
exon_store <- list()
for (i in seq_len(nrow(spec))) {
  g <- spec$gene[i]
  st <- spec$strand[i]
  ex <- place_exons(spec$n_exon[i], spec$length_bp[i])
  exon_store[[g]] <- ex
  # Terminal exons split into UTR + CDS. Strand sets which end is 5'.
  for (j in seq_len(nrow(ex))) {
    a <- ex$start[j]
    b <- ex$end[j]
    is_first <- j == 1L
    is_last <- j == nrow(ex)
    five_end <- if (st == "+") is_first else is_last
    three_end <- if (st == "+") is_last else is_first
    if (five_end && (b - a) > 180) {
      utr_end <- a + sample(80:180, 1)
      rows <- push(rows, g, "utr", a, utr_end, st)
      rows <- push(rows, g, "exon", utr_end + 1L, b, st)
    } else if (three_end && (b - a) > 180) {
      utr_start <- b - sample(80:160, 1)
      rows <- push(rows, g, "exon", a, utr_start - 1L, st)
      rows <- push(rows, g, "utr", utr_start, b, st)
    } else {
      rows <- push(rows, g, "exon", a, b, st)
    }
  }
  cds <- do.call(rbind, rows)
  cds <- cds[cds$gene == g & cds$feature == "exon", , drop = FALSE]
  n_dom <- if (nrow(cds) >= 4) 2L else 1L
  take <- sample(seq_len(nrow(cds)), n_dom)
  for (j in take) {
    a <- cds$start[j]
    b <- cds$end[j]
    span <- b - a
    if (span < 70) next
    d0 <- a + round(span * 0.2)
    d1 <- a + round(span * 0.75)
    rows <- push(rows, g, "domain", d0, d1, st)
  }
  n_mut <- sample(2:3, 1)
  for (m in seq_len(n_mut)) {
    j <- sample(seq_len(nrow(ex)), 1)
    pos <- sample(ex$start[j]:ex$end[j], 1)
    rows <- push(rows, g, "mutation", pos, pos, st)
  }
}

# Isoform Gene2.2 skips the third exon of Gene2.1; other exons stay aligned.
ex2 <- exon_store[["Gene2.1"]]
keep <- setdiff(seq_len(nrow(ex2)), 3L)
for (j in keep) {
  a <- ex2$start[j]
  b <- ex2$end[j]
  if (j == 1L) {
    utr_end <- a + 140L
    rows <- push(rows, "Gene2.2", "utr", a, utr_end, "+")
    rows <- push(rows, "Gene2.2", "exon", utr_end + 1L, b, "+")
  } else if (j == nrow(ex2)) {
    utr_start <- b - 120L
    rows <- push(rows, "Gene2.2", "exon", a, utr_start - 1L, "+")
    rows <- push(rows, "Gene2.2", "utr", utr_start, b, "+")
  } else {
    rows <- push(rows, "Gene2.2", "exon", a, b, "+")
  }
}
mid <- ex2[4, ]
rows <- push(
  rows, "Gene2.2", "domain",
  mid$start + 40L, mid$end - 40L, "+"
)
rows <- push(rows, "Gene2.2", "mutation", ex2$start[2] + 30L, ex2$start[2] + 30L, "+")

df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
