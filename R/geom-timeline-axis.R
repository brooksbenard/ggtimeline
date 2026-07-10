#' Timeline axis geom
#'
#' Draws the horizontal timeline axis. Typically added via [ggtimeline()].
#'
#' @inheritParams ggplot2::layer
#' @param size Axis line width.
#' @param colour Axis line colour.
#' @inheritParams ggplot2::layer
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_axis
geom_timeline_axis <- function(mapping = NULL, data = NULL,
                               stat = "identity",
                               position = "identity",
                               size = 0.8,
                               colour = "grey30",
                               show.legend = FALSE,
                               inherit.aes = TRUE,
                               ...) {
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
      ...
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
    linetype = 1
  ),

  draw_key = ggplot2::draw_key_blank,

  draw_panel = function(data, panel_params, coord, size = 0.8, colour = "grey30",
                        linetype = 1, ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    data <- ggplot2::coord_munch(coord, data, panel_params)
    row <- data[1, , drop = FALSE]
    alpha_val <- if ("alpha" %in% names(row) && !is.na(row$alpha)) row$alpha else 1

    grid::segmentsGrob(
      x0 = row$xmin,
      y0 = row$y,
      x1 = row$xmax,
      y1 = row$y,
      gp = grid::gpar(
        col = alpha(colour, alpha_val),
        lwd = size * ggplot2::.pt,
        lty = linetype
      )
    )
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
