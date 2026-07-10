#' Timeline axis geom
#'
#' Draws the horizontal timeline axis. Typically added via [ggtimeline()].
#'
#' @inheritParams ggplot2::layer
#' @param size Axis line width.
#' @param colour Axis line colour.
#' @param arrow If `TRUE` (default), draw a closed arrowhead at the right end
#'   of the axis pointing toward the future.
#' @param start_cap If `TRUE` (default), draw a filled dot at the left origin.
#' @param arrow_length Arrowhead length ([grid::unit()] or numeric passed to
#'   [grid::arrow()]).
#' @inheritParams ggplot2::layer
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_axis
geom_timeline_axis <- function(mapping = NULL, data = NULL,
                               stat = "identity",
                               position = "identity",
                               size = 0.8,
                               colour = "grey30",
                               arrow = TRUE,
                               start_cap = TRUE,
                               arrow_length = grid::unit(0.25, "cm"),
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
      arrow = arrow,
      start_cap = start_cap,
      arrow_length = arrow_length,
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

  extra_params = c("na.rm", "arrow", "start_cap", "arrow_length"),

  draw_panel = function(data, panel_params, coord, size = 0.8, colour = "grey30",
                        linetype = 1, arrow = TRUE, start_cap = TRUE,
                        arrow_length = grid::unit(0.25, "cm"), ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    data <- ggplot2::coord_munch(coord, data, panel_params)
    row <- data[1, , drop = FALSE]
    alpha_val <- if ("alpha" %in% names(row) && !is.na(row$alpha)) row$alpha else 1
    line_col <- alpha(colour, alpha_val)

    axis_arrow <- if (isTRUE(arrow)) {
      grid::arrow(length = arrow_length, type = "closed")
    } else {
      NULL
    }

    line <- grid::segmentsGrob(
      x0 = row$xmin,
      y0 = row$y,
      x1 = row$xmax,
      y1 = row$y,
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
