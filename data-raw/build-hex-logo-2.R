# Build package hex sticker from ggtimeline_logo_2.png.
# Run from package root: Rscript data-raw/build-hex-logo-2.R
#
# Writes the canonical pkgdown / README logo to man/figures/logo.png
# (and copies under inst/figures/), matching PhenoMapR layout.

if (!requireNamespace("magick", quietly = TRUE)) {
  stop("Install magick: install.packages('magick')", call. = FALSE)
}

root <- if (file.exists("ggtimeline_logo_2.png")) {
  "."
} else {
  dirname(dirname(normalizePath(sys.frame(1)$ofile %||% ".", winslash = "/")))
}

src <- file.path(root, "ggtimeline_logo_2.png")
out_dir <- file.path(root, "man", "figures")
inst_dir <- file.path(root, "inst", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(inst_dir, recursive = TRUE, showWarnings = FALSE)
out <- file.path(out_dir, "logo.png")
out_alt <- file.path(out_dir, "logo-2.png")

off_white <- "#F6F5F1"
border_col <- "#3A4A59"

canvas_w <- 1280L
canvas_h <- 1480L
cx <- canvas_w / 2
cy <- canvas_h / 2
R <- min(canvas_w, canvas_h) * 0.48

angles <- seq(-90, 270, by = 60) * pi / 180
hx <- cx + R * cos(angles)
hy <- cy + R * sin(angles)
border_w <- round(R * 0.07)

canvas <- magick::image_blank(canvas_w, canvas_h, color = "transparent")
fill_hex <- magick::image_draw(canvas)
polygon(hx, hy, col = off_white, border = NA)
grDevices::dev.off()

art <- magick::image_read(src)
art <- magick::image_resize(art, "1600x")
art <- magick::image_transparent(art, color = "black", fuzz = 16)
art <- magick::image_trim(art)

# Fill most of the hex interior without touching the border.
# Limiting box leaves ~border + small gap on each side (~88% of flat chord).
flat_w <- 2 * R * (sqrt(3) / 2)
flat_h <- 2 * R
inset <- border_w + R * 0.045
max_w <- round(flat_w - 2 * inset)
max_h <- round(flat_h - 2 * inset)
# Fit within the box; preserve aspect ratio.
art <- magick::image_resize(art, paste0(max_w, "x", max_h))
art_info <- magick::image_info(art)

art_x <- round(cx - art_info$width / 2)
art_y <- round(cy - art_info$height / 2)

sticker <- magick::image_composite(
  fill_hex, art,
  offset = sprintf("+%d+%d", art_x, art_y)
)

border_hex <- magick::image_draw(magick::image_blank(canvas_w, canvas_h, "transparent"))
polygon(hx, hy, col = NA, border = border_col, lwd = border_w)
grDevices::dev.off()
sticker <- magick::image_composite(sticker, border_hex)

magick::image_write(sticker, path = out, format = "png")
# Keep logo-2.png as an alias of the same hex for clarity in data-raw/docs.
magick::image_write(sticker, path = out_alt, format = "png")
file.copy(out, file.path(inst_dir, "logo.png"), overwrite = TRUE)
file.copy(out, file.path(inst_dir, "ggtimeline_logo.png"), overwrite = TRUE)

message(
  "Wrote ", normalizePath(out, winslash = "/"),
  "\n  (also man/figures/logo-2.png + inst/figures/logo.png)",
  "\n  art ", art_info$width, "x", art_info$height,
  "px (centered; max box ", max_w, "x", max_h, ")"
)
