# Regression test for the legacy path styles/r/theme_viz.R (theme_viz() + pv_save()), which no catalog
# figure uses after the house restyle. Run from the repo root:
#   Rscript tests/test_theme_viz_legacy.R
# Checks: a 3-line plot saves PDF + 600 dpi PNG + 1200 px preview; PNG / PDF sizes match the mm given;
# PDF fonts are embedded and all of the theme_viz() sans family.
root <- normalizePath(".")
if (!file.exists(file.path(root, "styles/r/theme_viz.R"))) stop("run from the repo root")
source(file.path(root, "styles/r/theme_viz.R"))

fail <- 0L
check <- function(ok, msg) {
  cat(if (isTRUE(ok)) "ok  " else "FAIL", msg, "\n")
  if (!isTRUE(ok)) fail <<- fail + 1L
}
png_dims <- function(f) {
  con <- file(f, "rb"); on.exit(close(con))
  hdr <- readBin(con, "raw", 24)
  to_int <- function(b) sum(as.integer(b) * 256^(3:0))
  c(to_int(hdr[17:20]), to_int(hdr[21:24]))
}

td <- tempfile("viz_legacy_"); dir.create(td)
p <- ggplot2::ggplot(data.frame(x = 1:3, y = c(2, 1, 3)), ggplot2::aes(x, y)) +
  ggplot2::geom_line() + theme_viz()
pv_save(p, file.path(td, "figure"), width_mm = 85, height_mm = 60)

check(all(file.exists(file.path(td, c("figure.pdf", "figure.png", "preview.png")))),
      "pv_save() writes figure.pdf, figure.png and preview.png")
check(all(abs(png_dims(file.path(td, "figure.png")) - round(c(85, 60) / 25.4 * 600)) <= 1),
      "figure.png is 85 x 60 mm at 600 dpi")
check(abs(png_dims(file.path(td, "preview.png"))[1] - 1200) <= 1, "preview.png is 1200 px wide")
if (nzchar(Sys.which("pdffonts")) && nzchar(Sys.which("pdfinfo"))) {
  info <- system2("pdfinfo", shQuote(file.path(td, "figure.pdf")), stdout = TRUE)
  line <- grep("^Page size:", info, value = TRUE)
  pt <- as.numeric(regmatches(line, gregexpr("[0-9.]+", line))[[1]][1:2])
  check(all(abs(pt - c(85, 60) / 25.4 * 72) <= 1), "figure.pdf page is 85 x 60 mm (cairo rounds to whole pt)")
  fonts <- system2("pdffonts", shQuote(file.path(td, "figure.pdf")), stdout = TRUE)[-(1:2)]
  fam <- gsub(" ", "", viz_sans_family())
  names_ <- sub("^[A-Z]{6}\\+", "", sub(" .*$", "", fonts))
  check(length(fonts) > 0 && all(grepl("yes", substr(fonts, 60, 200))) &&
          all(grepl(fam, names_, ignore.case = TRUE) | grepl(sub("Arial", "ArialMT", fam), names_)),
        sprintf("PDF fonts embedded and all %s (%s)", viz_sans_family(), paste(unique(names_), collapse = ", ")))
} else cat("skip PDF font check (poppler not installed)\n")

if (fail) { cat(fail, "check(s) failed\n"); quit(status = 1) }
cat("all legacy theme_viz checks passed\n")
