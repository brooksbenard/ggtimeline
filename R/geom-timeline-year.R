#' Timeline year annotation geom
#'
#' Draws large year labels along the timeline axis, typically alternating
#' above and below. Use via [ggtimeline()] or add directly after computing
#' break positions with [compute_year_breaks()].
#'
#' @inheritParams ggplot2::layer
#' @param size Year label text size.
#' @param colour Year label colour (overridden by mapped `colour` aesthetic).
#' @param offset Distance from the axis line in y-units.
#' @param fontface Font face for year labels.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_year
geom_timeline_year <- function(mapping = NULL, data = NULL,
                               stat = "identity",
                               position = "identity",
                               size = 5.5,
                               colour = "grey35",
                               offset = 0.32,
                               fontface = "bold",
                               show.legend = FALSE,
                               inherit.aes = TRUE,
                               ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineYear,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      size = size,
      colour = colour,
      offset = offset,
      fontface = fontface,
      ...
    )
  )
}

#' @rdname geom_timeline_year
#' @export
GeomTimelineYear <- ggplot2::ggproto(
  "GeomTimelineYear",
  ggplot2::Geom,

  required_aes = c("x", "label", "y", ".timeline_year_side"),
  default_aes = ggplot2::aes(
    colour = "grey35",
    alpha = 1,
    family = "",
    fontface = "bold"
  ),

  draw_key = ggplot2::draw_key_text,

  extra_params = c("na.rm", "size", "offset", "fontface"),

  draw_panel = function(data, panel_params, coord,
                        size = 5.5,
                        colour = "grey35",
                        offset = 0.32,
                        fontface = "bold",
                        ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    grobs <- vector("list", nrow(data))
    for (i in seq_len(nrow(data))) {
      row <- data[i, , drop = FALSE]
      sign <- if (row$.timeline_year_side == "above") 1 else -1
      label_y <- row$y + sign * offset
      pt <- ggplot2::coord_munch(
        coord,
        data.frame(x = row$x, y = label_y),
        panel_params
      )
      text_colour <- row$colour %||% colour
      grobs[[i]] <- grid::textGrob(
        label = as.character(row$label),
        x = pt$x,
        y = pt$y,
        hjust = 0.5,
        vjust = 0.5,
        gp = grid::gpar(
          col = alpha(text_colour, row$alpha %||% 1),
          fontsize = size * ggplot2::.pt,
          fontfamily = row$family %||% "",
          fontface = row$fontface %||% fontface
        )
      )
    }
    do.call(grid::grobTree, grobs)
  }
)
