# Simulated land-cover areas (km²) of one catchment. Run from this directory.
set.seed(20261015)
cover <- c("Cropland", "Forest", "Grassland", "Urban", "Wetland", "Water", "Bare", "Shrub")
share <- c(0.38, 0.27, 0.16, 0.09, 0.05, 0.025, 0.015, 0.01)
area <- round(1284 * share * exp(stats::rnorm(length(share), 0, 0.05)), 1)
utils::write.csv(data.frame(cover = cover, area_km2 = area), "data.csv", row.names = FALSE)
message("wrote data.csv rows=", length(cover))
