#' Add an emphasised milestone marker
#'
#' Adds a distinctive vertical marker (and optional label) to an existing
#' timeline plot via `plot + add_milestone(...)`.
#'
#' @param date Milestone date (`Date` or coercible).
#' @param label Optional annotation text.
#' @param colour Line/marker colour.
#' @param linetype Vertical guide linetype.
#' @param linewidth Vertical guide width.
#' @param size Marker size.
#' @param shape Marker pch (default diamond `23`).
#' @param label_size Label text size.
#' @param label_side `"above"` or `"below"` for the text.
#' @param label_offset Vertical offset of the label from the axis in y-units.
#' @param alpha Opacity.
#' @param ... Unused; reserved for forward compatibility.
#' @return A `timeline_annotation` object for use with `+`.
#' @export
#' @examples
#' \donttest{
#' library(ggplot2)
#' data("phenotype_methods_timeline")
#' ggtimeline(
#'   head(phenotype_methods_timeline, 8),
#'   aes(x = date, label = topic, fill = category)
#' ) +
#'   add_milestone(as.Date("2023-01-01"), label = "Key event")
#' }
add_milestone <- function(date,
                          label = NULL,
                          colour = "#C2185B",
                          linetype = "dashed",
                          linewidth = 0.5,
                          size = 3.5,
                          shape = 23,
                          label_size = 3.2,
                          label_side = c("above", "below"),
                          label_offset = 2.2,
                          alpha = 0.95,
                          ...) {
  label_side <- match.arg(label_side)
  date <- .as_date_safe(date)
  if (is.null(date) || is.na(date)) {
    rlang::abort("`date` must be a valid date.")
  }
  y_lab <- if (identical(label_side, "above")) label_offset else -label_offset
  layers <- list(
    ggplot2::geom_vline(
      xintercept = date,
      colour = colour,
      linetype = linetype,
      linewidth = linewidth,
      alpha = alpha
    ),
    ggplot2::annotate(
      "point",
      x = date,
      y = 0,
      shape = shape,
      size = size,
      fill = colour,
      colour = colour,
      alpha = alpha
    )
  )
  if (!is.null(label) && nzchar(as.character(label))) {
    layers[[length(layers) + 1L]] <- ggplot2::annotate(
      "text",
      x = date,
      y = y_lab,
      label = as.character(label),
      colour = colour,
      size = label_size,
      fontface = "bold",
      vjust = if (identical(label_side, "above")) 0 else 1
    )
  }
  structure(list(layers = layers), class = "timeline_annotation")
}

#' Add a labeled span bracket
#'
#' Draws a bracket above or below the axis covering `[start, end]`, distinct
#' from [geom_timeline_era()] fills and [geom_timeline_span()] event bars.
#'
#' @param start,end Date range endpoints.
#' @param label Bracket label text.
#' @param side `"above"` or `"below"`.
#' @param colour Bracket and label colour.
#' @param linewidth Line width.
#' @param label_size Label text size.
#' @param y Absolute y position of the bracket midline. If `NULL`, uses
#'   `offset` from the axis.
#' @param offset Distance from the axis when `y` is `NULL`.
#' @param tick Cap tick length in y-units.
#' @param alpha Opacity.
#' @param ... Unused; reserved for forward compatibility.
#' @return A `timeline_annotation` object for use with `+`.
#' @export
add_span <- function(start,
                     end,
                     label = NULL,
                     side = c("above", "below"),
                     colour = "#555555",
                     linewidth = 0.45,
                     label_size = 3.2,
                     y = NULL,
                     offset = 2.6,
                     tick = 0.18,
                     alpha = 0.95,
                     ...) {
  side <- match.arg(side)
  start <- .as_date_safe(start)
  end <- .as_date_safe(end)
  if (is.null(start) || is.null(end) || is.na(start) || is.na(end)) {
    rlang::abort("`start` and `end` must be valid dates.")
  }
  if (end < start) {
    tmp <- start
    start <- end
    end <- tmp
  }
  y0 <- y %||% if (identical(side, "above")) offset else -offset
  sign <- if (identical(side, "above")) -1 else 1
  y_tick <- y0 + sign * tick
  segs <- data.frame(
    x = c(start, start, end),
    xend = c(end, start, end),
    y = c(y0, y0, y0),
    yend = c(y0, y_tick, y_tick)
  )
  layers <- list(
    ggplot2::geom_segment(
      data = segs,
      mapping = ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
      inherit.aes = FALSE,
      colour = colour,
      linewidth = linewidth,
      alpha = alpha,
      lineend = "square"
    )
  )
  if (!is.null(label) && nzchar(as.character(label))) {
    mid <- as.Date(mean(c(as.numeric(start), as.numeric(end))), origin = "1970-01-01")
    layers[[length(layers) + 1L]] <- ggplot2::annotate(
      "text",
      x = mid,
      y = y0 - sign * 0.12,
      label = as.character(label),
      colour = colour,
      size = label_size,
      fontface = "bold",
      vjust = if (identical(side, "above")) 1 else 0
    )
  }
  structure(list(layers = layers), class = "timeline_annotation")
}

#' @export
ggplot_add.timeline_annotation <- function(object, plot, ...) {
  for (layer in object$layers) {
    plot <- plot + layer
  }
  plot
}
