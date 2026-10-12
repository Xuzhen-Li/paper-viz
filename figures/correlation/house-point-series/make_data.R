# Simulated leaf temperature under a heat lamp (house example). Fixed seed; writes data.csv.
set.seed(6)
t <- seq(0, 3600, 30)
ar <- function(sd, phi = 0.9) as.numeric(stats::filter(rnorm(length(t), 0, sd), phi, "recursive"))
sim <- function(rise, tau, sd) 22.6 + rise * (1 - exp(-t / tau)) + ar(sd)
d <- rbind(
  data.frame(genotype = "WT",     height = "upper", time_s = t, temp_c = sim(16.0, 420, 0.10)),
  data.frame(genotype = "hsp-ko", height = "upper", time_s = t, temp_c = sim(13.5, 800, 0.10)),
  data.frame(genotype = "hsp-ko", height = "lower", time_s = t, temp_c = sim(4.6, 900, 0.18)),
  data.frame(genotype = "WT",     height = "lower", time_s = t, temp_c = sim(2.7, 900, 0.16))
)
d$temp_c <- round(d$temp_c, 2)
write.csv(d, "data.csv", row.names = FALSE)
