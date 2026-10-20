# Simulated yearly publication counts for three topics (2000-2025) and four dated events.
# Writes data.csv (year, topic, n) and data_events.csv (year, event). Run from this directory.
set.seed(20261019)
years <- 2000:2025
topics <- c("Topic A", "Topic B", "Topic C")
start <- c(2000, 2006, 2013)      # first year with papers
rate <- c(0.17, 0.24, 0.33)       # yearly growth on the log scale
base <- c(6, 4, 3)
rows <- list()
for (i in seq_along(topics)) {
  t <- pmax(years - start[i], -1)
  mu <- ifelse(t < 0, 0, base[i] * exp(rate[i] * t))
  mu <- pmin(mu, 420)              # growth levels off
  rows[[i]] <- data.frame(year = years, topic = topics[i], n = stats::rpois(length(years), mu),
                          stringsAsFactors = FALSE)
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
events <- data.frame(
  year = c(2005, 2011, 2016, 2021),
  event = c("Method X", "Benchmark", "Consortium", "Guidelines"),
  stringsAsFactors = FALSE
)
utils::write.csv(events, "data_events.csv", row.names = FALSE)
message("wrote data.csv and data_events.csv")
