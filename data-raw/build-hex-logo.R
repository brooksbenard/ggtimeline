# Legacy text wordmark hex from ggtimeline_logo.png.
# Canonical package hex is built by data-raw/build-hex-logo-2.R → man/figures/logo.png
# This script writes logo-wordmark.png so it does not overwrite the package logo.

if (!requireNamespace("magick", quietly = TRUE)) {
  stop("Install magick: install.packages('magick')", call. = FALSE)
}

root <- if (file.exists("ggtimeline_logo.png")) {
  "."
} else {
  dirname(dirname(normalizePath(sys.frame(1)$ofile %||% ".", winslash = "/")))
}

src <- file.path(root, "ggtimeline_logo.png")
out_dir <- file.path(root, "man", "figures")
fonts_dir <- normalizePath(file.path(root, "data-raw", "fonts"), mustWork = TRUE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out <- file.path(out_dir, "logo-wordmark.png")

off_white <- "#F6F5F1"
border_col <- "#3A4A59"
text_col <- "#404040"

canvas_w <- 1280L
canvas_h <- 1480L
cx <- canvas_w / 2
cy <- canvas_h / 2
R <- min(canvas_w, canvas_h) * 0.48

# Pointy-top hex vertices (y grows downward in magick devices).
angles <- seq(-90, 270, by = 60) * pi / 180
hx <- cx + R * cos(angles)
hy <- cy + R * sin(angles)
border_w <- round(R * 0.07)

canvas <- magick::image_blank(canvas_w, canvas_h, color = "transparent")
fill_hex <- magick::image_draw(canvas)
polygon(hx, hy, col = off_white, border = NA)
grDevices::dev.off()

# Process timeline art: drop black backdrop, trim.
art <- magick::image_read(src)
art <- magick::image_resize(art, "1400x")
art <- magick::image_transparent(art, color = "black", fuzz = 16)
art <- magick::image_trim(art)

# Slightly under the flat chord so art matches the reference look but
# stays just inside the hex border (reference was clipping at ~full width).
flat_half_w <- R * (sqrt(3) / 2)
target_art_w <- round(2 * flat_half_w * 0.80)
art <- magick::image_resize(art, paste0(target_art_w, "x"))
art_info <- magick::image_info(art)

# Vertical placement matching the reference (high in the upper half).
art_x <- round(cx - art_info$width / 2)
art_y <- round(cy - art_info$height / 2 - R * 0.16)

sticker <- magick::image_composite(
  fill_hex, art,
  offset = sprintf("+%d+%d", art_x, art_y)
)

# Prefer system Century Gothic Regular; otherwise TeX Gyre Adventor Regular
# (URW Gothic — open geometric gothic commonly used as a Century Gothic stand-in).
.resolve_wordmark_font <- function(fonts_dir) {
  mf <- magick::magick_fonts()
  cg <- which(
    grepl("^Century Gothic$", mf$family, ignore.case = TRUE) &
      grepl("Regular|Normal", mf$name, ignore.case = TRUE)
  )
  if (length(cg)) {
    return(list(name = mf$name[cg[1]], label = "Century Gothic Regular"))
  }

  # Local fontconfig pointing at data-raw/fonts so ImageMagick can find Adventor.
  adventor <- file.path(fonts_dir, "texgyreadventor-regular.otf")
  if (!file.exists(adventor)) {
    stop("Missing ", adventor, call. = FALSE)
  }
  conf <- tempfile(fileext = ".conf")
  writeLines(
    c(
      '<?xml version="1.0"?>',
      '<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">',
      "<fontconfig>",
      paste0("  <dir>", fonts_dir, "</dir>"),
      "</fontconfig>"
    ),
    conf
  )
  Sys.setenv(FONTCONFIG_FILE = conf)
  # Rebuild magick font cache for this process if available.
  try(magick::magick_fonts(), silent = TRUE)
  mf2 <- magick::magick_fonts()
  ad <- which(grepl("TeXGyreAdventor-Regular|TeX Gyre Adventor", mf2$name, ignore.case = TRUE) |
    grepl("TeX Gyre Adventor", mf2$family, ignore.case = TRUE))
  if (!length(ad)) {
    # Fallback: pass the file path directly.
    return(list(name = adventor, label = "TeX Gyre Adventor Regular (file)"))
  }
  list(name = mf2$name[ad[1]], label = "TeX Gyre Adventor Regular (Century Gothic stand-in)")
}

font <- .resolve_wordmark_font(fonts_dir)
text_pt <- round(canvas_w * 0.062)
text_y <- round(cy + R * 0.42)
sticker <- magick::image_annotate(
  sticker,
  text = "ggtimeline",
  font = font$name,
  size = text_pt,
  color = text_col,
  gravity = "North",
  location = sprintf("+0+%d", text_y - round(text_pt * 0.35))
)

# Dark grey-blue border on top.
border_hex <- magick::image_draw(magick::image_blank(canvas_w, canvas_h, "transparent"))
polygon(hx, hy, col = NA, border = border_col, lwd = border_w)
grDevices::dev.off()
sticker <- magick::image_composite(sticker, border_hex)

magick::image_write(sticker, path = out, format = "png")
message(
  "Wrote ", normalizePath(out, winslash = "/"),
  "\n  art width=", art_info$width, "px (~80% of hex flat chord)",
  "\n  font=", font$label, " [", font$name, "]"
)
