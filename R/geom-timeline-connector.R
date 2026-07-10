#' Timeline elbow connector geom
#'
#' Draws elbowed connector lines from axis points to label positions.
#' Requires data processed by [stat_timeline()].
#'
#' @inheritParams ggplot2::layer
#' @param elbowed If `TRUE` (default), draw horizontal-then-vertical elbows;
#'   if `FALSE`, draw straight diagonal connectors.
#' @inheritParams ggplot2::layer
#' @param size Line width.
#' @param colour Line colour.
#' @param linetype Line type.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_connector
geom_timeline_connector <- function(mapping = NULL, data = NULL,
                                    stat = "timeline",
                                    position = "identity",
                                    elbowed = TRUE,
                                    size = 0.4,
                                    colour = "grey50",
                                    linetype = 1,
                                    show.legend = FALSE,
                                    inherit.aes = TRUE,
                                    ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineConnector,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      elbowed = elbowed,
      size = size,
      colour = colour,
      linetype = linetype,
      ...
    )
  )
}

#' @rdname geom_timeline_connector
#' @export
GeomTimelineConnector <- ggplot2::ggproto(
  "GeomTimelineConnector",
  ggplot2::Geom,

  required_aes = c("x", "y", ".timeline_elbow_x", ".timeline_label_y"),
  default_aes = ggplot2::aes(
    size = 0.4,
    colour = "grey50",
    alpha = 1,
    linetype = 1
  ),

  draw_key = ggplot2::draw_key_path,

  extra_params = c("na.rm", "elbowed"),

  draw_panel = function(data, panel_params, coord, elbowed = TRUE,
                        size = 0.4, colour = "grey50", linetype = 1, ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    grobs <- vector("list", nrow(data))
    for (i in seq_len(nrow(data))) {
      row <- data[i, , drop = FALSE]
      line_colour <- row$colour %||% colour
      line_size <- row$size %||% size
      line_lty <- row$linetype %||% linetype
      alpha_val <- row$alpha %||% 1

      if (isTRUE(elbowed)) {
        seg1 <- data.frame(
          x = c(row$x, row$.timeline_elbow_x),
          y = c(row$y, row$y)
        )
        seg2 <- data.frame(
          x = c(row$.timeline_elbow_x, row$.timeline_elbow_x),
          y = c(row$y, row$.timeline_label_y)
        )
        seg_list <- list(seg1, seg2)
      } else {
        seg_list <- list(data.frame(
          x = c(row$x, row$x),
          y = c(row$y, row$.timeline_label_y)
        ))
      }

      seg_grobs <- lapply(seg_list, function(pts) {
        pts <- ggplot2::coord_munch(coord, pts, panel_params)
        grid::segmentsGrob(
          x0 = pts$x[1],
          y0 = pts$y[1],
          x1 = pts$x[2],
          y1 = pts$y[2],
          gp = grid::gpar(
            col = alpha(line_colour, alpha_val),
            lwd = line_size * ggplot2::.pt,
            lty = line_lty,
            lineend = "round"
          )
        )
      })
      grobs[[i]] <- do.call(grid::grobTree, seg_grobs)
    }
    do.call(grid::grobTree, grobs)
  }
)

#' Timeline endpoint marker geom
#'
#' Draws ring-style endpoint markers at label positions (classic style).
#'
#' @inheritParams ggplot2::layer
#' @inheritParams ggplot2::layer
#' @param size Marker size.
#' @param shape Marker shape.
#' @param fill Marker fill colour.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_endpoint
geom_timeline_endpoint <- function(mapping = NULL, data = NULL,
                                   stat = "timeline",
                                   position = "identity",
                                   size = 4.5,
                                   shape = 21,
                                   fill = "white",
                                   show.legend = FALSE,
                                   inherit.aes = TRUE,
                                   ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineEndpoint,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      size = size,
      shape = shape,
      fill = fill,
      ...
    )
  )
}

#' @rdname geom_timeline_endpoint
#' @export
GeomTimelineEndpoint <- ggplot2::ggproto(
  "GeomTimelineEndpoint",
  ggplot2::GeomPoint,

  required_aes = c("x", ".timeline_label_y"),
  default_aes = ggplot2::aes(
    y = NULL,
    shape = 21,
    size = 4.5,
    colour = "grey30",
    fill = "white",
    alpha = 1,
    stroke = 1.2
  ),

  draw_key = ggplot2::draw_key_point,

  draw_panel = function(data, panel_params, coord) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }
    data$y <- data$.timeline_label_y
    coords <- ggplot2::coord_munch(coord, data, panel_params)
    grid::pointsGrob(
      x = coords$x,
      y = coords$.timeline_label_y,
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
