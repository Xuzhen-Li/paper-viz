# House-style PCA scatter of accessions, coloured by region with pv_palette("geo") (west -> east).
# PCA is computed here from the genotypes in data.csv; axis titles give % variance explained.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

region_order <- c("Iberia", "W Europe", "Balkans", "Caucasus", "Central Asia", "East Asia")   # west -> east
SIM_NOTE <- "Simulated data for illustration; not biological results"

d <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
g <- as.matrix(d[, grepl("^snp", names(d))])
g <- g[, apply(g, 2, stats::var) > 0]
pc <- stats::prcomp(g, center = TRUE, scale. = TRUE)
ve <- 100 * pc$sdev^2 / sum(pc$sdev^2)                    # % variance explained
sc <- data.frame(region = factor(d$region, levels = region_order), pc1 = pc$x[, 1], pc2 = pc$x[, 2])
if (stats::cor(sc$pc1, as.integer(sc$region)) < 0) sc$pc1 <- -sc$pc1   # west on the left
cols <- stats::setNames(pv_palette("geo"), region_order)
n_per <- table(sc$region); n_snp <- ncol(g)
stopifnot(all(n_per == n_per[[1]]), n_snp == 300)
# the simulation draws every SNP independently (no linkage), i.e. what an LD-pruned panel approximates
FOOT <- sprintf("n = %d per region; %d unlinked SNPs (equivalent to LD-pruned)\n%s", n_per[[1]], n_snp, SIM_NOTE)
stopifnot(length(cols) == 6, nlevels(sc$region) == 6)

# direct labels: black text with a square key in the region colour (squares, so keys are not read as samples) (the light geo colours are too pale for
# text on white), placed by hand just outside each cluster for this seed. The check below fails if a label
# box would touch any point, so a change of data cannot silently put a label on the points.
cen <- stats::aggregate(cbind(pc1, pc2) ~ region, sc, mean)
rx <- diff(range(sc$pc1)); ry <- diff(range(sc$pc2))
lab <- data.frame(region = factor(region_order, levels = region_order),
                  dx = c(0.25, 0.00, -0.15, 0.25, 0.00, 0.00),     # offset from the centroid, fraction of range
                  dy = c(0.07, -0.27, 0.15, 0.09, -0.20, 0.21))
lab <- merge(lab, cen, by = "region")
lab$tx <- lab$pc1 + lab$dx * rx; lab$ty <- lab$pc2 + lab$dy * ry
lab$w <- nchar(as.character(lab$region)) * 1.62 / 70 * rx * 1.2 # label width at 9 pt, panel ~70 mm
lab$tx0 <- lab$tx - lab$w / 2                                # text is centred; key dot sits left of it
lab$kx <- lab$tx0 - 0.03 * rx
xl <- range(sc$pc1, lab$kx - 0.03 * rx, lab$tx0 + lab$w + 0.03 * rx) + c(-0.02, 0.02) * rx
yl <- range(sc$pc2, lab$ty) + c(-0.19, 0.08) * ry
hh <- 0.035 * ry                                              # half text height
clash <- vapply(seq_len(nrow(lab)), function(k) any(sc$pc1 > lab$kx[k] - 0.02 * rx & sc$pc1 < lab$tx0[k] + lab$w[k] &
                                                      abs(sc$pc2 - lab$ty[k]) < hh + 0.03 * ry), FALSE)
if (any(clash)) print(cbind(lab[, c("region", "tx0", "ty", "w")], clash)); stopifnot(!any(clash))
minus <- function(x) gsub("-", "\u2212", format(x, trim = TRUE))

p <- ggplot(sc, aes(pc1, pc2)) +
  geom_point(aes(fill = region), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             colour = "black") +
  geom_point(data = lab, aes(kx, ty, fill = region), shape = 22, size = 1.6, stroke = HOUSE_POINT$stroke,
             colour = "black") +
  geom_text(data = lab, aes(tx0, ty, label = region), hjust = 0, size = pv_pt2size(7)) +
  annotate("text", x = xl[2], y = yl[1], label = FOOT, hjust = 1, vjust = -0.25, lineheight = 0.95, size = pv_pt2size(5),
           colour = pv_palette("house_grey")[["mid"]]) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_x_continuous(limits = xl, labels = minus, expand = c(0, 0)) +
  scale_y_continuous(limits = yl, labels = minus, expand = c(0, 0)) +
  labs(x = sprintf("PC1 (%.1f%%)", ve[1]), y = sprintf("PC2 (%.1f%%)", ve[2])) +
  theme_house()

pv_save_house(p, "figure", cells = "2x2")
message(sprintf("PC1 %.2f%%, PC2 %.2f%%", ve[1], ve[2]))
message("wrote preview.png")
