#' Timeline axis geom
#'
#' Draws the horizontal timeline axis as a thick bar arrow (years can sit
#' inside via [geom_timeline_year()] with `side = "inside"`) or as a thin line.
#'
#' @inheritParams ggplot2::layer
#' @param size Outline width for the bar axis, or line width for `"line"`.
#' @param colour Axis colour.
#' @param fill Interior fill for the bar axis. Defaults to white.
#' @param shape Axis shape: `"bar"` (thick arrow body with a normal tip) or
#'   `"line"` (thin horizontal line).
#' @param height Half-height (vertical thickness) of the bar ribbon in y-units.
#'   Ignored for `"line"`.
#' @param tip_frac Fraction of the axis length used for the right arrow tip.
#'   Smaller values yield a shorter, less stretched head. Default `0.015`.
#' @param arrow If `TRUE` and `shape = "line"`, draw a closed arrowhead at the
#'   right end. For `"bar"`, the tip is always drawn as part of the polygon.
#' @param start_cap If `TRUE` and `shape = "line"`, draw a filled dot at the
#'   left origin.
#' @param arrow_length Arrowhead length for `"line"` shape.
#' @inheritParams ggplot2::layer
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_axis
geom_timeline_axis <- function(mapping = NULL, data = NULL,
                               stat = "identity",
                               position = "identity",
                               size = 0.8,
                               colour = "grey30",
                               fill = "white",
                               shape = c("bar", "line"),
                               height = 0.42,
                               tip_frac = 0.015,
                               arrow = TRUE,
                               start_cap = TRUE,
                               arrow_length = grid::unit(0.25, "cm"),
                               show.legend = FALSE,
                               inherit.aes = TRUE,
                               ...) {
  shape <- match.arg(shape)
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineAxis,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      size = size,
      colour = colour,
      fill = fill,
      shape = shape,
      height = height,
      tip_frac = tip_frac,
      arrow = arrow,
      start_cap = start_cap,
      arrow_length = arrow_length,
      ...
    )
  )
}

# Thick rectangular body with a compact right-pointing arrow tip.
.bar_arrow_vertices <- function(xmin, xmax, y, height, tip_frac) {
  xmin <- .date_to_numeric(xmin)
  xmax <- .date_to_numeric(xmax)
  span <- max(xmax - xmin, 1)
  # Keep the tip short even on long timelines so it does not look stretched.
  tip <- min(max(span * tip_frac, 18), max(span * 0.025, 45))
  half <- height
  body_end <- xmax - tip
  # Mild flare beyond the bar thickness for a conventional arrow look.
  tip_half <- half * 1.2

  data.frame(
    x = c(
      xmin,           # top-left
      body_end,       # top before tip
      body_end,       # top of tip base (outer)
      xmax,           # tip point
      body_end,       # bottom of tip base (outer)
      body_end,       # bottom before tip
      xmin,           # bottom-left
      xmin            # close
    ),
    y = c(
      y + half,
      y + half,
      y + tip_half,
      y,
      y - tip_half,
      y - half,
      y - half,
      y + half
    )
  )
}

#' @rdname geom_timeline_axis
#' @export
GeomTimelineAxis <- ggplot2::ggproto(
  "GeomTimelineAxis",
  ggplot2::Geom,

  required_aes = c("xmin", "xmax", "y"),
  default_aes = ggplot2::aes(
    size = 0.8,
    colour = "grey30",
    fill = "white",
    linetype = 1,
    alpha = 1
  ),

  draw_key = ggplot2::draw_key_blank,

  extra_params = c(
    "na.rm", "arrow", "start_cap", "arrow_length",
    "shape", "height", "tip_frac", "fill"
  ),

  draw_panel = function(data, panel_params, coord,
                        size = 0.8,
                        colour = "grey30",
                        fill = "white",
                        linetype = 1,
                        shape = "bar",
                        height = 0.42,
                        tip_frac = 0.015,
                        arrow = TRUE,
                        start_cap = TRUE,
                        arrow_length = grid::unit(0.25, "cm"),
                        ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    row <- data[1, , drop = FALSE]
    alpha_val <- if ("alpha" %in% names(row) && !is.na(row$alpha)) row$alpha else 1
    line_col <- alpha(colour, alpha_val)
    fill_col <- alpha(fill %||% "white", alpha_val)

    # Back-compat: older callers may still pass shape = "chevron".
    if (identical(shape, "chevron")) {
      shape <- "bar"
    }

    if (identical(shape, "bar")) {
      verts <- .bar_arrow_vertices(
        xmin = row$xmin,
        xmax = row$xmax,
        y = row$y,
        height = height,
        tip_frac = tip_frac
      )
      if (inherits(row$xmin, "Date") || inherits(row$xmax, "Date")) {
        verts$x <- as.Date(verts$x, origin = "1970-01-01")
      }
      coords <- ggplot2::coord_munch(coord, verts, panel_params)
      return(grid::polygonGrob(
        x = coords$x,
        y = coords$y,
        default.units = "native",
        gp = grid::gpar(
          col = line_col,
          fill = fill_col,
          lwd = size * ggplot2::.pt,
          lty = linetype,
          linejoin = "mitre"
        )
      ))
    }

    # Thin line -------------------------------------------------------------
    munched <- ggplot2::coord_munch(
      coord,
      data.frame(
        x = c(row$xmin, row$xmax),
        y = c(row$y, row$y)
      ),
      panel_params
    )

    axis_arrow <- if (isTRUE(arrow)) {
      grid::arrow(length = arrow_length, type = "closed")
    } else {
      NULL
    }

    line <- grid::segmentsGrob(
      x0 = munched$x[1],
      y0 = munched$y[1],
      x1 = munched$x[2],
      y1 = munched$y[2],
      arrow = axis_arrow,
      gp = grid::gpar(
        col = line_col,
        lwd = size * ggplot2::.pt,
        lty = linetype,
        fill = line_col
      )
    )

    grobs <- list(line)
    if (isTRUE(start_cap)) {
      cap_size <- size * 2.2
      start_pt <- ggplot2::coord_munch(
        coord,
        data.frame(x = row$xmin, y = row$y),
        panel_params
      )
      grobs <- c(
        list(
          grid::pointsGrob(
            x = start_pt$x,
            y = start_pt$y,
            pch = 16,
            gp = grid::gpar(col = line_col, fill = line_col, cex = cap_size / 3)
          )
        ),
        grobs
      )
    }

    do.call(grid::grobTree, grobs)
  }
)

#' Timeline event points geom
#'
#' Draws event markers on the timeline axis.
#'
#' @inheritParams ggplot2::layer
#' @inheritParams ggplot2::layer
#' @param size Point size.
#' @param shape Point shape.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_point
geom_timeline_point <- function(mapping = NULL, data = NULL,
                                stat = "timeline",
                                position = "identity",
                                size = 3,
                                shape = 21,
                                show.legend = NA,
                                inherit.aes = TRUE,
                                ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelinePoint,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      size = size,
      shape = shape,
      ...
    )
  )
}

#' @rdname geom_timeline_point
#' @export
GeomTimelinePoint <- ggplot2::ggproto(
  "GeomTimelinePoint",
  ggplot2::GeomPoint,

  default_aes = ggplot2::aes(
    shape = 21,
    size = 3,
    colour = "grey30",
    fill = NA,
    alpha = 1,
    stroke = 1
  ),

  draw_panel = function(data, panel_params, coord) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }
    coords <- ggplot2::coord_munch(coord, data, panel_params)
    grid::pointsGrob(
      x = coords$x,
      y = coords$y,
      pch = coords$shape,
      gp = grid::gpar(
        col = alpha(coords$colour, coords$alpha),
        fill = alpha(coords$fill, coords$alpha),
        fontsize = coords$size * ggplot2::.pt,
        lwd = coords$stroke * ggplot2::.pt
      )
    )
  }
)
