# Environmental correlations and Mantel tests against eight omics distances.
set.seed(310)

n <- 24L
env_names <- c(
  "pH", "SOC", "TN", "TP", "Moisture", "Temp",
  "NH4", "NO3", "Salinity", "Clay", "NPP", "Elevation"
)
z1 <- rnorm(n)
z2 <- rnorm(n)
z3 <- rnorm(n)
env <- cbind(
  pH = z1 + rnorm(n, 0, 0.35),
  SOC = 0.75 * z1 + rnorm(n, 0, 0.45),
  TN = 0.62 * z1 + rnorm(n, 0, 0.5),
  TP = 0.35 * z1 + rnorm(n, 0, 0.8),
  Moisture = z2 + rnorm(n, 0, 0.4),
  Temp = -0.55 * z2 + rnorm(n, 0, 0.55),
  NH4 = 0.4 * z2 + rnorm(n, 0, 0.7),
  NO3 = rnorm(n),
  Salinity = z3 + rnorm(n, 0, 0.4),
  Clay = 0.5 * z3 + rnorm(n, 0, 0.6),
  NPP = 0.45 * z1 + 0.35 * z2 + rnorm(n, 0, 0.55),
  Elevation = -0.4 * z2 + rnorm(n, 0, 0.7)
)
colnames(env) <- env_names

omics_names <- c("Bacteria", "Fungi", "Archaea", "Protist", "Nematode", "AMF", "Enzyme", "Metabolite")
# which env axes each omics actually tracks; the rest is noise
drivers <- list(
  Bacteria = c("pH", "SOC", "TN"),
  Fungi = c("SOC", "Moisture", "NPP"),
  Archaea = c("pH", "Salinity"),
  Protist = c("Moisture", "Temp"),
  Nematode = c("NPP", "Moisture"),
  AMF = c("SOC", "TP"),
  Enzyme = c("TN", "SOC", "Temp"),
  Metabolite = c("pH", "NO3")
)

env_rows <- list()
for (i in seq_along(env_names)) {
  for (j in seq_along(env_names)) {
    if (j < i) next
    ct <- stats::cor.test(env[, i], env[, j])
    env_rows[[length(env_rows) + 1L]] <- data.frame(
      var_a = env_names[i], var_b = env_names[j],
      r = round(unname(ct$estimate), 3),
      p = signif(ct$p.value, 3),
      mantel_r = NA_real_,
      stringsAsFactors = FALSE
    )
  }
}

mantel_rows <- list()
for (om in omics_names) {
  beta <- setNames(rep(0, length(env_names)), env_names)
  beta[drivers[[om]]] <- runif(length(drivers[[om]]), 0.8, 1.4)
  lat <- as.numeric(scale(env) %*% beta) + rnorm(n, 0, 1.1)
  # a small multivariate table so the distance is not a single perfect axis
  tab <- cbind(lat + rnorm(n, 0, 0.8), 0.4 * lat + rnorm(n, 0, 1), rnorm(n))
  d_om <- stats::dist(tab)
  for (v in env_names) {
    mt <- vegan::mantel(d_om, stats::dist(env[, v]), permutations = 199)
    mantel_rows[[length(mantel_rows) + 1L]] <- data.frame(
      var_a = om, var_b = v,
      r = NA_real_,
      p = signif(mt$signif, 3),
      mantel_r = round(mt$statistic, 3),
      stringsAsFactors = FALSE
    )
  }
}

out <- rbind(do.call(rbind, env_rows), do.call(rbind, mantel_rows))
utils::write.csv(out, "data.csv", row.names = FALSE)
