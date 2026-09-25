# PSMC / SMC++ style Ne trajectories. Both axes are later plotted on log10.
set.seed(107)
years <- round(exp(seq(log(2e3), log(2e6), length.out = 40)))
# Knots: years, Ne. Interpolate in log-log space.
knots_wild <- rbind(
  c(2e3, 7.5e4), c(8e3, 6.2e4), c(2e4, 4.2e4), c(6e4, 9.5e4),
  c(1.5e5, 1.25e5), c(4e5, 5.5e4), c(1e6, 3.2e4), c(2e6, 2.4e4)
)
knots_cul <- rbind(
  c(2e3, 5.5e3), c(8e3, 8.5e3), c(2e4, 2.4e4), c(6e4, 7.2e4),
  c(1.5e5, 1.15e5), c(4e5, 5.2e4), c(1e6, 3.2e4), c(2e6, 2.4e4)
)
interp_ne <- function(knots) {
  tt <- log10(years)
  tk <- log10(knots[, 1])
  nk <- log10(knots[, 2])
  stats::approx(tk, nk, xout = tt, rule = 2)$y
}
one <- function(pop, log_ne) {
  wiggle <- stats::filter(rnorm(length(years), 0, 0.03), c(0.25, 0.5, 0.25), sides = 2)
  wiggle[is.na(wiggle)] <- 0
  ne <- 10^(log_ne + as.numeric(wiggle))
  # wider bootstrap at recent and ancient ends
  rel <- 0.08 + 0.14 * abs(log10(years) - 5) / 1.6
  data.frame(
    pop = pop, years_ago = years,
    ne = round(ne), ne_low = round(ne * (1 - rel)), ne_high = round(ne * (1 + rel)),
    stringsAsFactors = FALSE
  )
}
df <- rbind(
  one("Wild N", interp_ne(knots_wild)),
  one("Cultivar A", interp_ne(knots_cul))
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
