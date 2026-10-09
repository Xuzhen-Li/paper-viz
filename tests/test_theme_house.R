# Smoke test for styles/r/theme_house.R. Run from the repo root:
#   Rscript tests/test_theme_house.R
# Checks: theme renders; PNG pixel size = mm / 25.4 * 600; PDF page size = mm / 25.4 * 72;
# PDF text is real text (fonts embedded); single-column single panel gets +2 pt once;
# legacy theme_viz() / pv_palette("categorical") are unchanged.
root <- normalizePath(".")
if (!file.exists(file.path(root, "styles/r/theme_house.R"))) stop("run from the repo root")
source(file.path(root, "styles/r/theme_house.R"))
library(ggplot2)

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
pdf_raw <- function(f) {
  r <- readBin(f, "raw", file.info(f)$size)
  rawToChar(r[r != as.raw(0)])
}
has_poppler <- nzchar(Sys.which("pdfinfo")) && nzchar(Sys.which("pdffonts"))
# PDF page size in pt (pdfinfo when present, else the first /MediaBox if it is not compressed).
pdf_box <- function(f) {
  if (has_poppler) {
    line <- grep("^Page size:", system2("pdfinfo", shQuote(f), stdout = TRUE), value = TRUE)
    return(as.numeric(regmatches(line, gregexpr("[0-9.]+", line))[[1]][1:2]))
  }
  txt <- pdf_raw(f)
  m <- regmatches(txt, regexpr("/MediaBox *\\[[^]]*\\]", txt, useBytes = TRUE))
  if (!length(m)) return(NULL)
  as.numeric(strsplit(trimws(gsub("[^0-9. ]", " ", m)), " +")[[1]])[3:4]
}
# TRUE if every font is embedded (text stays text; nothing outlined). NA if it cannot be read.
pdf_fonts_embedded <- function(f) {
  if (has_poppler) {
    out <- system2("pdffonts", shQuote(f), stdout = TRUE)[-(1:2)]
    return(length(out) > 0 && all(grepl(" yes +(yes|no) +(yes|no) +[0-9]+ +[0-9]+ *$", out)))
  }
  txt <- pdf_raw(f)
  if (grepl("/FontFile", txt, useBytes = TRUE)) TRUE else NA
}

# legacy interfaces --------------------------------------------------------
chip <- c("#134aa3", "#f6a3b1", "#0b5475", "#dc1f26", "#835ca6", "#f7922c", "#fbee61", "#981b1e")
check(identical(pv_palette(), chip), "pv_palette() default is the chip eight")
check(identical(pv_palette("categorical", 3), chip[1:3]), "pv_palette('categorical', 3)")
check(length(pv_palette("categorical", 10)) == 10, "pv_palette('categorical', 10) still ramps")
check(identical(pv_palette("sequential"), c("#F7FBFF", "#C6DBEF", "#6BAED6", "#2171B5", "#08306B")),
      "pv_palette('sequential') unchanged")
check(inherits(theme_viz(), "theme"), "theme_viz() still returns a theme")
check(is.function(pv_save), "pv_save() still available")

# house palettes -------------------------------------------------------------
check(identical(unname(pv_palette("house", 3)), c("#1F72AE", "#F77E12", "#119B76")), "pv_palette('house', 3)")
check(length(pv_palette("house_div")) == 9 && pv_palette("house_div")[5] == "#F7F7F7", "house_div centre #F7F7F7")
check(identical(unname(pv_palette("ssp")["SSP5-8.5"]), "#9C2125"), "ssp named colours")
check(inherits(try(pv_palette("house", 10), silent = TRUE), "try-error"), "house refuses > 9 colours")

# theme -----------------------------------------------------------------------
th <- theme_house()
check(th$axis.text$size == 7 && th$axis.title$size == 8 && th$plot.tag$size == 10, "theme_house sizes 7/8/10")
check(th$plot.tag$face == "bold" && th$axis.title$face == "plain", "tag bold, axis title plain")
check(abs(th$panel.border$linewidth * .pt * 72 / 96 - 0.5) < 1e-9, "frame 0.5 pt")
check(inherits(th$panel.grid, "element_blank"), "no grid")

set.seed(1)
d <- data.frame(x = rnorm(40), y = rnorm(40), g = rep(c("A", "B"), 20))
p <- ggplot(d, aes(x, y, fill = g)) +
  geom_point(shape = 21, size = 2.3, stroke = 0.3) +
  geom_line(aes(colour = g), linewidth = pv_house_lw("main")) +
  annotate("text", x = 0, y = 2, label = "label 7 pt", size = pv_pt2size(7)) +
  scale_fill_manual(values = unname(pv_palette("house", 2))) +
  scale_colour_manual(values = unname(pv_palette("house", 2))) +
  labs(x = "Value x (unit)", y = "Value y (unit)") +
  theme_house()

out <- file.path(tempdir(), "house-test")
dir.create(out, showWarnings = FALSE)
for (case in list(list("single", 89, 76, 2), list("double", 183, 60, 0))) {
  w <- case[[1]]; mm_w <- case[[2]]; mm_h <- case[[3]]; want_bump <- case[[4]]
  res <- pv_save_house(p, file.path(out, w), width = w, height_mm = mm_h, preview = TRUE)
  check(res$bump == want_bump, sprintf("%s: bump = %s pt", w, want_bump))
  dims <- png_dims(res$png)
  want <- round(c(mm_w, mm_h) / 25.4 * 600)
  check(all(abs(dims - want) <= 1), sprintf("%s: PNG %dx%d px (want %dx%d at 600 dpi)", w, dims[1], dims[2], want[1], want[2]))
  box <- pdf_box(res$pdf)
  wantpt <- c(mm_w, mm_h) / 25.4 * 72
  if (is.null(box)) {
    cat("skip", w, ": PDF page size (no pdfinfo; MediaBox compressed)\n")
  } else {
    check(all(abs(box - wantpt) < 1), sprintf("%s: PDF %.1fx%.1f pt (want %.1fx%.1f)", w, box[1], box[2], wantpt[1], wantpt[2]))
  }
  emb <- pdf_fonts_embedded(res$pdf)
  if (is.na(emb)) cat("skip", w, ": PDF font check (no pdffonts)\n") else
    check(emb, sprintf("%s: PDF fonts embedded as text (not outlined)", w))
  check(png_dims(file.path(out, "preview.png"))[1] == 1200, sprintf("%s: preview.png 1200 px wide", w))
}
# no double bump; input plot untouched
p9 <- p + theme_house(base_size = 9)
check(pv_save_house(p9, file.path(out, "s9"), "single", 76, preview = FALSE)$bump == 0, "base_size 9 not bumped again")
bp <- pv_bump_text(p, 2)
check(bp$theme$axis.text$size == 9 && bp$theme$axis.title$size == 10, "bump: ticks 9, axis titles 10")
check(abs(bp$layers[[3]]$aes_params$size - pv_pt2size(9)) < 1e-9, "bump: annotate text 7 -> 9 pt")
check(abs(p$layers[[3]]$aes_params$size - pv_pt2size(7)) < 1e-9, "bump leaves the input plot unchanged")
check(pv_save_house(p + facet_wrap(~g), file.path(out, "facet"), "single", 60, preview = FALSE)$bump == 0,
      "faceted plot at 89 mm is not bumped")

# in-plot text uses the theme font (no device-default NimbusSans etc.) ----------------
if (has_poppler) {
  fonts_of <- function(f) {
    out <- system2("pdffonts", shQuote(f), stdout = TRUE)[-(1:2)]
    sub("^[A-Z]{6}\\+", "", vapply(strsplit(trimws(out), " +"), `[`, "", 1))
  }
  pt <- ggplot(d, aes(x, y)) + geom_point() + geom_text(aes(label = g)) +
    geom_label(data = d[1:2, ], aes(label = g)) +
    annotate("text", x = 0, y = 0, label = "note") + theme_house()
  # also prove the save-time patch works without the geom defaults set at source time
  old <- list(text = GeomText$default_aes$family, label = GeomLabel$default_aes$family)
  update_geom_defaults("text", list(family = "")); update_geom_defaults("label", list(family = ""))
  res <- pv_save_house(pt, file.path(out, "fonts"), "double", 60, preview = FALSE)
  pw <- if (requireNamespace("patchwork", quietly = TRUE)) patchwork::wrap_plots(pt, pt) else pt
  res2 <- pv_save_house(pw, file.path(out, "fonts_pw"), "double", 60, preview = FALSE)
  pv_house_geom_defaults()
  for (f in c(res$pdf, res2$pdf)) {
    fs <- fonts_of(f)
    check(length(fs) > 0 && !any(grepl("Nimbus", fs)) && length(unique(substr(gsub("[^A-Za-z]", "", fs), 1, 5))) == 1,
          sprintf("%s: one font family in PDF (%s)", basename(f), paste(unique(fs), collapse = ", ")))
  }
} else cat("skip font-family check (no pdffonts)\n")

# point size: demo A values, physical size shared with Python house.POINT -------------
pd <- pv_point_dims()
check(abs(pd[["outer_mm"]] - 2.04) < 0.02 && abs(pd[["outline_pt"]] - 0.425) < 0.005,
      sprintf("HOUSE_POINT: outer %.2f mm, outline %.3f pt", pd[["outer_mm"]], pd[["outline_pt"]]))

if (fail) { cat(fail, "check(s) failed\n"); quit(status = 1) }
cat("all R house-theme checks passed\n")
