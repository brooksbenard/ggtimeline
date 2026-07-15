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
#' @param tip_style Shape of the right end of a bar axis: `"arrow"` (default,
#'   a normal flared tip), `"flat"` / `"none"` (square end, no flare), or
#'   `"circle"` (rectangle body ending just before `xmax` plus a circular cap).
#'   Ignored for `shape = "line"`.
#' @param gradient If `TRUE`, fill the bar axis with a left-to-right linear
#'   gradient (light to `fill`) instead of a solid colour. Requires
#'   R >= 4.1 (uses [grid::linearGradient()]); falls back to a solid fill
#'   with a one-time warning on older R. Ignored for `shape = "line"`.
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
                               tip_style = c("arrow", "flat", "none", "circle"),
                               gradient = FALSE,
                               arrow = TRUE,
                               start_cap = TRUE,
                               arrow_length = grid::unit(0.25, "cm"),
                               show.legend = FALSE,
                               inherit.aes = TRUE,
                               ...) {
  shape <- match.arg(shape)
  tip_style <- match.arg(tip_style)
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
      tip_style = tip_style,
      gradient = gradient,
      arrow = arrow,
      start_cap = start_cap,
      arrow_length = arrow_length,
      ...
    )
  )
}

# Thick rectangular body with a compact right-pointing arrow tip.
.bar_arrow_vertices <- function(xmin, xmax, y, height, tip_frac,
                                tip_style = "arrow") {
  xmin <- .date_to_numeric(xmin)
  xmax <- .date_to_numeric(xmax)
  span <- max(xmax - xmin, 1)
  half <- height

  if (tip_style %in% c("flat", "none")) {
    return(data.frame(
      x = c(xmin, xmax, xmax, xmin, xmin),
      y = c(y + half, y + half, y - half, y - half, y + half)
    ))
  }

  if (identical(tip_style, "circle")) {
    # Reserve room for a circular cap at the right end; body stops short.
    cap_r <- half
    body_end <- max(xmax - cap_r * 1.6, xmin)
    return(data.frame(
      x = c(xmin, body_end, body_end, xmin, xmin),
      y = c(y + half, y + half, y - half, y - half, y + half)
    ))
  }

  # Default "arrow": mild flare beyond the bar thickness at the tip.
  # Keep the tip short even on long timelines so it does not look stretched.
  tip <- min(max(span * tip_frac, 18), max(span * 0.025, 45))
  body_end <- xmax - tip
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

# One-time warning cache for gradient fallback on older R.
.timeline_gradient_warned <- new.env(parent = emptyenv())

.timeline_gradient_fill <- function(fill_col, alpha_val) {
  if (!exists("linearGradient", where = asNamespace("grid"), inherits = FALSE)) {
    if (!isTRUE(.timeline_gradient_warned$warned)) {
      rlang::warn(
        "`axis_gradient = TRUE` requires R >= 4.1 (grid::linearGradient); using a solid fill instead."
      )
      .timeline_gradient_warned$warned <- TRUE
    }
    return(fill_col)
  }
  light <- tryCatch({
    rgb <- grDevices::col2rgb(fill_col)[, 1]
    lightened <- pmin(255, rgb + (255 - rgb) * 0.72)
    grDevices::rgb(lightened[1], lightened[2], lightened[3], maxColorValue = 255)
  }, error = function(e) "#FFFFFF")
  grid::linearGradient(
    colours = alpha(c(light, fill_col), alpha_val),
    x1 = 0, y1 = 0.5, x2 = 1, y2 = 0.5
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
    "shape", "height", "tip_frac", "fill", "tip_style", "gradient"
  ),

  draw_panel = function(data, panel_params, coord,
                        size = 0.8,
                        colour = "grey30",
                        fill = "white",
                        linetype = 1,
                        shape = "bar",
                        height = 0.42,
                        tip_frac = 0.015,
                        tip_style = "arrow",
                        gradient = FALSE,
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
        tip_frac = tip_frac,
        tip_style = tip_style
      )
      if (inherits(row$xmin, "Date") || inherits(row$xmax, "Date")) {
        verts$x <- as.Date(verts$x, origin = "1970-01-01")
      }
      coords <- ggplot2::coord_munch(coord, verts, panel_params)
      body_fill <- if (isTRUE(gradient)) {
        .timeline_gradient_fill(fill %||% "white", alpha_val)
      } else {
        fill_col
      }
      body_grob <- grid::polygonGrob(
        x = coords$x,
        y = coords$y,
        default.units = "native",
        gp = grid::gpar(
          col = line_col,
          fill = body_fill,
          lwd = size * ggplot2::.pt,
          lty = linetype,
          linejoin = "mitre"
        )
      )

      if (!identical(tip_style, "circle")) {
        return(body_grob)
      }

      # Circular cap at the right end, radius approximately the bar height.
      xmax_num <- .date_to_numeric(row$xmax)
      xmin_num <- .date_to_numeric(row$xmin)
      cap_r <- height
      cap_x <- xmax_num - cap_r
      cap_pt <- data.frame(x = cap_x, y = row$y)
      if (inherits(row$xmin, "Date") || inherits(row$xmax, "Date")) {
        cap_pt$x <- as.Date(cap_pt$x, origin = "1970-01-01")
      }
      cap_c <- ggplot2::coord_munch(coord, cap_pt, panel_params)
      # Convert the y-unit radius to npc via the panel's y range.
      y_range <- panel_params$y.range %||%
        panel_params$y$continuous_range %||% c(-1, 1)
      r_npc <- grid::unit(cap_r / diff(y_range), "npc")
      cap_grob <- grid::circleGrob(
        x = cap_c$x,
        y = cap_c$y,
        r = r_npc,
        gp = grid::gpar(col = line_col, fill = body_fill, lwd = size * ggplot2::.pt)
      )
      return(grid::grobTree(body_grob, cap_grob))
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
