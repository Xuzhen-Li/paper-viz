# One 2 Mb locus, four tracks: depth, ATAC, RNA, CNV. 500 bins each.
set.seed(207)

n <- 500L
pos <- seq(10e6 + 2000, 12e6 - 2000, length.out = n)
x <- pos - 10e6

depth <- 40 + stats::rnorm(n, 0, 3.2)
atac <- stats::rexp(n, rate = 1 / 8)
rna <- stats::rexp(n, rate = 1 / 6)
cnv <- rep(2, n)

dip <- function(center, width, depth_to, cnv_to) {
  hit <- abs(x - center) < width
  depth[hit] <<- depth_to + stats::rnorm(sum(hit), 0, 2)
  cnv[hit] <<- cnv_to
}
dip(0.85e6, 0.15e6, 20, 1)
dip(1.35e6, 0.14e6, 62, 3)

peak <- function(center, width, height) {
  height * exp(-0.5 * ((x - center) / width)^2)
}
atac <- atac + peak(0.42e6, 18000, 220) + peak(1.62e6, 14000, 160)
rna <- rna +
  peak(0.46e6, 8000, 90) + peak(0.50e6, 7000, 110) + peak(0.545e6, 9000, 80) +
  peak(1.66e6, 10000, 100) + peak(1.71e6, 8000, 70)

depth <- pmax(0, depth)
atac <- pmax(0, atac)
rna <- pmax(0, rna)

df <- rbind(
  data.frame(track = "Depth", pos = pos, value = round(depth, 2)),
  data.frame(track = "ATAC", pos = pos, value = round(atac, 2)),
  data.frame(track = "RNA", pos = pos, value = round(rna, 2)),
  data.frame(track = "CNV", pos = pos, value = cnv)
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
