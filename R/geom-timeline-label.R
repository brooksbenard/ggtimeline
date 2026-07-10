#' Timeline label geom
#'
#' Draws topic labels at computed positions. Supports plain text or
#' rounded label boxes (ribbon/milestone styles).
#'
#' @inheritParams ggplot2::layer
#' @param boxed If `TRUE`, draw labels inside rounded rectangles.
#' @param label.size Border width for boxed labels.
#' @param label.padding Padding around boxed label text.
#' @param label.r Corner radius for boxed labels.
#' @inheritParams ggplot2::layer
#' @param size Text size.
#' @param colour Text colour.
#' @param hjust,vjust,angle,family,fontface,lineheight Passed to label drawing.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_label
geom_timeline_label <- function(mapping = NULL, data = NULL,
                                stat = "timeline",
                                position = "identity",
                                boxed = FALSE,
                                size = 3.5,
                                colour = "black",
                                hjust = 0,
                                vjust = 0.5,
                                angle = 0,
                                family = "",
                                fontface = "plain",
                                lineheight = 0.9,
                                label.size = 0.15,
                                label.padding = grid::unit(0.25, "lines"),
                                label.r = grid::unit(0.15, "lines"),
                                show.legend = FALSE,
                                inherit.aes = TRUE,
                                ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineLabel,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      boxed = boxed,
      size = size,
      colour = colour,
      hjust = hjust,
      vjust = vjust,
      angle = angle,
      family = family,
      fontface = fontface,
      lineheight = lineheight,
      label.size = label.size,
      label.padding = label.padding,
      label.r = label.r,
      ...
    )
  )
}

#' @rdname geom_timeline_label
#' @export
GeomTimelineLabel <- ggplot2::ggproto(
  "GeomTimelineLabel",
  ggplot2::Geom,

  required_aes = c("x", "label", ".timeline_label_x", ".timeline_label_y", ".timeline_side"),
  default_aes = ggplot2::aes(
    y = NULL,
    size = 3.5,
    colour = "black",
    fill = "grey90",
    alpha = 1,
    hjust = 0,
    vjust = 0.5,
    angle = 0,
    family = "",
    fontface = "plain",
    lineheight = 0.9
  ),

  draw_key = ggplot2::draw_key_text,

  extra_params = c("na.rm", "boxed", "label.size", "label.padding", "label.r"),

  draw_panel = function(data, panel_params, coord, boxed = FALSE,
                        label.size = 0.15,
                        label.padding = grid::unit(0.25, "lines"),
                        label.r = grid::unit(0.15, "lines"),
                        ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    data$x <- if (".timeline_label_x" %in% names(data)) data$.timeline_label_x else data$x
    data$y <- data$.timeline_label_y
    data$hjust <- ifelse(
      data$.timeline_side == "above",
      pmax(data$hjust, 0),
      pmax(data$hjust, 0)
    )
    data$vjust <- ifelse(
      data$.timeline_side == "above",
      0,
      1
    )

    if (!isTRUE(boxed)) {
      return(ggplot2::GeomText$draw_panel(data, panel_params, coord))
    }

    grobs <- vector("list", nrow(data))
    for (i in seq_len(nrow(data))) {
      row <- data[i, , drop = FALSE]
      pt <- ggplot2::coord_munch(
        coord,
        data.frame(x = row$x, y = row$.timeline_label_y),
        panel_params
      )
      txt <- grid::textGrob(
        label = row$label,
        x = pt$x,
        y = pt$y,
        hjust = row$hjust,
        vjust = row$vjust,
        rot = row$angle,
        gp = grid::gpar(
          col = alpha(row$colour, row$alpha),
          fontsize = row$size * ggplot2::.pt,
          fontfamily = row$family,
          fontface = row$fontface,
          lineheight = row$lineheight
        )
      )
      grobs[[i]] <- grid::roundrectGrob(
        x = pt$x,
        y = pt$y,
        width = grid::unit(1, "npc"),
        height = grid::unit(1, "npc"),
        r = label.r,
        gp = grid::gpar(
          col = alpha(row$colour, row$alpha),
          fill = alpha(row$fill, row$alpha),
          lwd = label.size * ggplot2::.pt
        ),
        just = c(row$hjust, row$vjust)
      )
      grobs[[i]] <- grid::grobTree(
        grobs[[i]],
        txt
      )
    }
    grid::grobTree(grobs = grobs)
  }
)

#' Timeline label geom with bold topic and optional description
#'
#' @inheritParams geom_timeline_label
#' @param description_aes Name of the aesthetic column containing secondary
#'   description text displayed below the topic in smaller grey type.
#' @inheritParams ggplot2::layer
#' @param topic_size,description_size,description_colour Text styling for rich labels.
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname geom_timeline_label_rich
geom_timeline_label_rich <- function(mapping = NULL, data = NULL,
                                     stat = "timeline",
                                     position = "identity",
                                     description_aes = "description",
                                     topic_size = 3.8,
                                     description_size = 2.8,
                                     description_colour = "grey55",
                                     show.legend = FALSE,
                                     inherit.aes = TRUE,
                                     ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTimelineLabelRich,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      description_aes = description_aes,
      topic_size = topic_size,
      description_size = description_size,
      description_colour = description_colour,
      ...
    )
  )
}

#' @rdname geom_timeline_label_rich
#' @export
GeomTimelineLabelRich <- ggplot2::ggproto(
  "GeomTimelineLabelRich",
  ggplot2::Geom,

  required_aes = c("x", "label", ".timeline_label_y", ".timeline_side"),
  default_aes = ggplot2::aes(
    description = NULL,
    colour = "black",
    alpha = 1,
    family = "",
    fontface = "bold"
  ),

  draw_key = ggplot2::draw_key_text,

  draw_panel = function(data, panel_params, coord,
                        topic_size = 3.8,
                        description_size = 2.8,
                        description_colour = "grey55",
                        ...) {
    if (nrow(data) == 0L) {
      return(grid::nullGrob())
    }

    grobs <- vector("list", nrow(data))
    for (i in seq_len(nrow(data))) {
      row <- data[i, , drop = FALSE]
      pt <- ggplot2::coord_munch(
        coord,
        data.frame(x = row$x, y = row$.timeline_label_y),
        panel_params
      )
      vjust <- if (row$.timeline_side == "above") 0 else 1
      topic <- grid::textGrob(
        label = row$label,
        x = pt$x,
        y = pt$y,
        hjust = 0,
        vjust = vjust,
        gp = grid::gpar(
          col = alpha(row$colour, row$alpha),
          fontsize = topic_size * ggplot2::.pt,
          fontfamily = row$family,
          fontface = row$fontface %||% "bold"
        )
      )
      desc <- grid::nullGrob()
      if (!is.null(row$description) && !is.na(row$description) &&
            nzchar(as.character(row$description))) {
        offset <- if (row$.timeline_side == "above") -0.08 else 0.08
        desc <- grid::textGrob(
          label = as.character(row$description),
          x = pt$x,
          y = pt$y + offset,
          hjust = 0,
          vjust = vjust,
          gp = grid::gpar(
            col = alpha(description_colour, row$alpha),
            fontsize = description_size * ggplot2::.pt,
            fontfamily = row$family,
            fontface = "plain",
            lineheight = 0.95
          )
        )
      }
      grobs[[i]] <- grid::grobTree(topic, desc)
    }
    grid::grobTree(grobs = grobs)
  }
)
