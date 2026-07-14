#' Timeline era bands
#'
#' Draws background era rectangles inspired by
#' [jasonreisman/Timeline](https://github.com/jasonreisman/Timeline): lightly
#' tinted bands across a date range, optional dashed boundaries, and a label
#' at the top of each band.
#'
#' Colour and opacity can be set globally via `alpha` / mapped `fill`, or
#' per-row through data columns `fill` and `alpha` (used when not mapped as
#' aesthetics — the default in [ggtimeline()]).
#'
#' @inheritParams ggplot2::layer
#' @param alpha Default band opacity used when a row has no `alpha` value.
#' @param label_size Era label text size.
#' @param label_colour Optional fixed colour for era labels. When `NULL`,
#'   labels use a darkened version of each band's fill.
#' @param label_y Optional y position for era labels. Defaults to the top of
#'   each band (`ymax`).
#' @param show_bounds If `TRUE`, draw dashed vertical edges at era start/end.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_era
#' @examples
#' \donttest{
#' library(ggplot2)
#' eras <- data.frame(
#'   xmin = as.Date(c("2020-01-01", "2023-01-01")),
#'   xmax = as.Date(c("2022-12-31", "2026-06-01")),
#'   label = c("Emergence", "Expansion"),
#'   fill = c("#4C72B0", "#C44E52"),
#'   alpha = c(0.12, 0.2)
#' )
#' ggplot() +
#'   geom_timeline_era(
#'     data = eras,
#'     aes(xmin = xmin, xmax = xmax, label = label),
#'     ymin = -3, ymax = 3
#'   )
#' }
geom_timeline_era <- function(mapping = NULL, data = NULL,
                              stat = "identity",
                              position = "identity",
                              alpha = 0.12,
                              label_size = 3.2,
                              label_colour = NULL,
                              label_y = NULL,
                              show_bounds = TRUE,
                              show.legend = FALSE,
                              inherit.aes = FALSE,
                              ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineEra,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      alpha = alpha,
      label_size = label_size,
      label_colour = label_colour,
      label_y = label_y,
      show_bounds = show_bounds,
      ...
    )
  )
}

#' @rdname geom_timeline_era
#' @export
GeomTimelineEra <- ggplot2::ggproto(
  "GeomTimelineEra",
  ggplot2::Geom,

  required_aes = c("xmin", "xmax"),
  default_aes = ggplot2::aes(
    fill = "#C0C0C0",
    colour = NA,
    label = NA_character_,
    ymin = NA_real_,
    ymax = NA_real_,
    alpha = NA_real_,
    linetype = "dashed"
  ),

  draw_key = ggplot2::draw_key_rect,

  extra_params = c(
    "na.rm", "label_size", "label_colour", "label_y", "show_bounds", "alpha"
  ),

  draw_panel = function(data, panel_params, coord,
                        alpha = 0.12,
                        label_size = 3.2,
                        label_colour = NULL,
                        label_y = NULL,
                        show_bounds = TRUE,
                        ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    # Fall back to panel y-range when ymin/ymax not supplied.
    y_lim <- panel_params$y$continuous_range %||%
      panel_params$y.range %||%
      c(-1, 1)

    grobs <- vector("list", nrow(data))
    for (i in seq_len(nrow(data))) {
      row <- data[i, , drop = FALSE]
      ymin <- if (is.finite(row$ymin)) row$ymin else y_lim[1]
      ymax <- if (is.finite(row$ymax)) row$ymax else y_lim[2]
      band_alpha <- row$.era_alpha %||% row$alpha
      if (!is.finite(band_alpha)) {
        band_alpha <- alpha
      }
      fill_raw <- row$.era_fill %||% row$fill %||% "#C0C0C0"
      fill_col <- scales::alpha(fill_raw, band_alpha)
      edge_col <- scales::alpha(fill_raw, min(1, band_alpha * 3.5))

      rect_df <- data.frame(
        x = c(row$xmin, row$xmax, row$xmax, row$xmin),
        y = c(ymin, ymin, ymax, ymax)
      )
      rect_c <- ggplot2::coord_munch(coord, rect_df, panel_params)
      band <- grid::polygonGrob(
        x = rect_c$x,
        y = rect_c$y,
        default.units = "native",
        gp = grid::gpar(col = NA, fill = fill_col)
      )

      parts <- list(band)

      if (isTRUE(show_bounds)) {
        for (xv in list(row$xmin, row$xmax)) {
          edge_df <- data.frame(x = c(xv, xv), y = c(ymin, ymax))
          edge_c <- ggplot2::coord_munch(coord, edge_df, panel_params)
          parts[[length(parts) + 1L]] <- grid::segmentsGrob(
            x0 = edge_c$x[1],
            y0 = edge_c$y[1],
            x1 = edge_c$x[2],
            y1 = edge_c$y[2],
            gp = grid::gpar(
              col = edge_col,
              lwd = 0.6 * ggplot2::.pt,
              lty = row$linetype %||% "dashed"
            )
          )
        }
      }

      lab <- row$label
      if (!is.null(lab) && length(lab) && !is.na(lab) && nzchar(as.character(lab))) {
        # Place labels at the very top of the era band.
        ly <- label_y %||% ymax
        mid_x <- mean(c(.date_to_numeric(row$xmin), .date_to_numeric(row$xmax)))
        if (inherits(row$xmin, "Date") || inherits(row$xmax, "Date")) {
          mid_x <- as.Date(mid_x, origin = "1970-01-01")
        }
        lab_df <- data.frame(x = mid_x, y = ly)
        lab_c <- ggplot2::coord_munch(coord, lab_df, panel_params)
        # Prefer an explicit colour; otherwise a readable dark tint of the band.
        if (is.null(label_colour)) {
          rgb <- tryCatch(
            grDevices::col2rgb(fill_raw)[, 1],
            error = function(e) c(68, 68, 68)
          )
          text_col <- grDevices::rgb(
            rgb[1] * 0.42, rgb[2] * 0.42, rgb[3] * 0.42,
            maxColorValue = 255
          )
        } else {
          text_col <- label_colour
        }
        parts[[length(parts) + 1L]] <- grid::textGrob(
          label = as.character(lab),
          x = lab_c$x,
          y = lab_c$y,
          hjust = 0.5,
          vjust = 1,
          gp = grid::gpar(
            col = text_col,
            fontsize = label_size * ggplot2::.pt,
            fontface = "bold"
          )
        )
      }

      grobs[[i]] <- do.call(grid::grobTree, parts)
    }

    do.call(grid::grobTree, grobs)
  }
)

# Normalise era specifications for ggtimeline().
.normalise_eras <- function(eras, palette = timeline_palette(),
                            default_alpha = 0.16) {
  if (is.null(eras)) {
    return(NULL)
  }
  if (!is.data.frame(eras) || nrow(eras) == 0L) {
    return(NULL)
  }

  nm <- names(eras)
  pick <- function(candidates) {
    hit <- candidates[candidates %in% nm]
    if (length(hit)) hit[[1]] else NULL
  }

  start_col <- pick(c("xmin", "start", "from", "begin"))
  end_col <- pick(c("xmax", "end", "to"))
  if (is.null(start_col) || is.null(end_col)) {
    rlang::abort(
      "`eras` must include start/end columns (e.g. `start`/`end` or `xmin`/`xmax`)."
    )
  }

  to_date <- function(x) {
    if (inherits(x, "Date")) {
      return(x)
    }
    if (inherits(x, "POSIXt")) {
      return(as.Date(x))
    }
    suppressWarnings(as.Date(x))
  }

  xmin <- to_date(eras[[start_col]])
  xmax <- to_date(eras[[end_col]])

  label_col <- pick(c("label", "name", "era"))
  label <- if (is.null(label_col)) {
    rep(NA_character_, nrow(eras))
  } else {
    as.character(eras[[label_col]])
  }

  fill_col <- pick(c("fill", "colour", "color"))
  fill <- if (is.null(fill_col)) {
    if (is.function(palette)) {
      palette(nrow(eras))
    } else {
      cols <- unname(as.character(palette))
      if (length(cols) < nrow(eras)) {
        timeline_palette(nrow(eras))
      } else {
        cols[seq_len(nrow(eras))]
      }
    }
  } else {
    as.character(eras[[fill_col]])
  }

  alpha_col <- pick(c("alpha", "opacity"))
  band_alpha <- if (is.null(alpha_col)) {
    rep(default_alpha, nrow(eras))
  } else {
    a <- as.numeric(eras[[alpha_col]])
    a[!is.finite(a)] <- default_alpha
    a
  }

  data.frame(
    xmin = xmin,
    xmax = xmax,
    label = label,
    .era_fill = fill,
    .era_alpha = band_alpha,
    stringsAsFactors = FALSE
  )
}
