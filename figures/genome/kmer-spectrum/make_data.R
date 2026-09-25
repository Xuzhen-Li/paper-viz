# GenomeScope-style diploid spectra. Linear-scale peaks; tail after 2n falls only.
set.seed(211)

nb_part <- function(mult, mu, size, weight) {
  weight * stats::dnbinom(mult, size = size, mu = mu)
}

one_spectrum <- function(mult, lambda, het_w, hom_w, err_w) {
  err <- err_w * exp(-1.25 * (mult - 1))
  het <- nb_part(mult, lambda / 2, 10, het_w)
  hom <- nb_part(mult, lambda, 16, hom_w)
  model_of <- function(rep_w) {
    err + het + hom + nb_part(mult, lambda * 2, 12, rep_w)
  }
  hom_ix <- which.min(abs(mult - lambda))
  rep_w <- hom_w * 0.04
  model <- model_of(rep_w)
  repeat {
    tail <- model[hom_ix:length(model)]
    if (all(diff(tail) <= 0)) break
    rep_w <- rep_w * 0.5
    if (rep_w < hom_w * 0.001) {
      model <- model_of(0)
      break
    }
    model <- model_of(rep_w)
  }
  count <- model
  body <- seq_len(hom_ix + 2L)
  count[body] <- pmax(0, count[body] * (1 + stats::rnorm(length(body), 0, 0.03)))
  if (hom_ix < length(count)) {
    for (i in (hom_ix + 1L):length(count)) {
      if (count[i] > count[i - 1L]) count[i] <- count[i - 1L] * 0.94
    }
  }
  data.frame(
    multiplicity = mult,
    count = round(count),
    model = round(model),
    lambda = lambda
  )
}

high <- one_spectrum(1:78, lambda = 26, het_w = 9.2e5, hom_w = 6.4e5, err_w = 6.5e6)
low <- one_spectrum(1:96, lambda = 32, het_w = 7.5e4, hom_w = 1.05e6, err_w = 5.5e6)
df <- rbind(
  data.frame(library = "High-het", high),
  data.frame(library = "Low-het", low)
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
