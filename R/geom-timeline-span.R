#' Timeline interval / span geom
#'
#' Draws horizontal bars for events with a start (`x` / `xmin`) and end
#' (`xend` / `xmax`) date. Intended to sit just above or below the ribbon
#' arrow; connectors and labels still use the interval midpoint by default.
#'
#' @inheritParams ggplot2::layer
#' @param height Vertical half-thickness of each span bar in y-units.
#' @param linewidth Outline width.
#' @param colour Outline colour.
#' @param fill Bar fill colour.
#' @param alpha Opacity.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_span
#' @examples
#' \donttest{
#' library(ggplot2)
#' events <- data.frame(
#'   start = as.Date(c("2021-01-01", "2022-06-01")),
#'   end = as.Date(c("2021-09-01", "2023-03-01")),
#'   topic = c("Phase I", "Phase II"),
#'   y = c(0.55, -0.55)
#' )
#' ggplot(events, aes(xmin = start, xmax = end, y = y, fill = topic)) +
#'   geom_timeline_span(height = 0.12) +
#'   theme_void()
#' }
geom_timeline_span <- function(mapping = NULL, data = NULL,
                               stat = "identity",
                               position = "identity",
                               height = 0.12,
                               linewidth = NULL,
                               colour = NULL,
                               fill = NULL,
                               alpha = NULL,
                               show.legend = NA,
                               inherit.aes = TRUE,
                               ...) {
  # Only forward colour/fill/alpha/linewidth as fixed params when the caller
  # explicitly sets them; otherwise let a mapped (possibly inherited) aes or
  # `default_aes` supply the value. Forcing these into `params` unconditionally
  # would silently override an inherited `fill`/`colour` mapping.
  params <- list(height = height, ...)
  if (!is.null(linewidth)) params$linewidth <- linewidth
  if (!is.null(colour)) params$colour <- colour
  if (!is.null(fill)) params$fill <- fill
  if (!is.null(alpha)) params$alpha <- alpha
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineSpan,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = params
  )
}

#' @rdname geom_timeline_span
#' @export
GeomTimelineSpan <- ggplot2::ggproto(
  "GeomTimelineSpan",
  ggplot2::Geom,

  # Prefer xmin/xmax; x/xend are accepted aliases (listed so ggplot keeps them).
  required_aes = c("y"),
  default_aes = ggplot2::aes(
    xmin = NA,
    xmax = NA,
    x = NA,
    xend = NA,
    colour = NA,
    fill = "grey50",
    linewidth = 0.3,
    alpha = 0.85,
    linetype = 1
  ),

  draw_key = ggplot2::draw_key_polygon,

  extra_params = c("na.rm", "height"),

  setup_data = function(data, params) {
    has_xmin <- "xmin" %in% names(data) && any(!is.na(data$xmin))
    has_x <- "x" %in% names(data) && "xend" %in% names(data) &&
      any(!is.na(data$x))
    if (!has_xmin && has_x) {
      data$xmin <- data$x
      data$xmax <- data$xend
    }
    if (!all(c("xmin", "xmax") %in% names(data)) ||
          all(is.na(data$xmin)) || all(is.na(data$xmax))) {
      rlang::abort(
        "`geom_timeline_span()` needs `xmin`/`xmax` or `x`/`xend` aesthetics."
      )
    }
    # Swap inverted intervals.
    swap <- .date_to_numeric(data$xmax) < .date_to_numeric(data$xmin)
    if (any(swap, na.rm = TRUE)) {
      tmp <- data$xmin[swap]
      data$xmin[swap] <- data$xmax[swap]
      data$xmax[swap] <- tmp
    }
    data
  },

  draw_panel = function(data, panel_params, coord,
                        height = 0.12,
                        ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    half <- height
    if ("height" %in% names(data) && any(is.finite(data$height))) {
      half <- data$height
      half[!is.finite(half)] <- height
    } else {
      half <- rep(height, nrow(data))
    }

    lw <- if ("linewidth" %in% names(data)) data$linewidth else 0.3
    rects <- data.frame(
      xmin = data$xmin,
      xmax = data$xmax,
      ymin = data$y - half,
      ymax = data$y + half,
      colour = data$colour,
      fill = data$fill,
      alpha = data$alpha,
      linewidth = lw,
      linetype = data$linetype,
      stringsAsFactors = FALSE
    )

    ggplot2::GeomRect$draw_panel(rects, panel_params, coord)
  }
)
