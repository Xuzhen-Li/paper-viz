# Simulated berry weight vs anthocyanin for three grape groups. Run from this directory.
set.seed(20261008)
wine <- c("Cabernet Sauvignon", "Merlot", "Syrah", "Pinot Noir", "Malbec", "Nebbiolo", "Sangiovese",
          "Tempranillo", "Grenache", "Zinfandel", "Cabernet Franc", "Mourvedre", "Petit Verdot",
          "Carmenere", "Gamay", "Barbera", "Aglianico", "Touriga Nacional", "Tannat", "Saperavi",
          "Dornfelder", "Lemberger", "Marselan", "Cinsault", "Carignan", "Dolcetto")
table <- c("Red Globe", "Flame Seedless", "Crimson Seedless", "Kyoho", "Summer Black", "Muscat Hamburg",
           "Black Monukka", "Autumn Royal", "Fujiminori", "Jumbo Grape", "Kaiji", "Ruby Seedless",
           "Black Emerald", "Midnight Beauty", "Benitaka", "Moldova", "Victoria Red", "Sweet Celebration",
           "Scarlet Royal", "Ralli Seedless")
wild <- paste0("VS", sprintf("%03d", c(12, 27, 31, 44, 58, 63, 71, 85, 92, 104, 117, 126, 133, 141)))
d <- rbind(
  data.frame(group = "Wild", name = wild, berry_weight_g = exp(stats::runif(14, log(0.35), log(0.95)))),
  data.frame(group = "Wine", name = wine, berry_weight_g = exp(stats::runif(26, log(0.9), log(2.6)))),
  data.frame(group = "Table", name = table, berry_weight_g = exp(stats::runif(20, log(2.8), log(11))))
)
lw <- log(d$berry_weight_g)
mu <- ifelse(d$group == "Wild", 9.0 - 3.2 * lw, ifelse(d$group == "Wine", 8.6 - 4.6 * lw, 4.6 - 1.55 * lw))
sdv <- ifelse(d$group == "Wild", 1.0, ifelse(d$group == "Wine", 0.95, 0.55))
d$anthocyanin_mg_g <- pmax(mu + stats::rnorm(nrow(d), 0, sdv), 0.2)
d$berry_weight_g <- round(d$berry_weight_g, 3)
d$anthocyanin_mg_g <- round(d$anthocyanin_mg_g, 3)
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
