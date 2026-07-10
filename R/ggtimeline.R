#' Create a timeline plot
#'
#' High-level interface for building timeline visualisations with sensible
#' defaults. Accepts a data frame with date, topic, and optional aesthetic
#' columns. Automatically places labels above and below the axis, staggers
#' heights to reduce overlap, and draws elbowed connectors.
#'
#' @param data A data frame containing timeline events.
#' @param mapping An [ggplot2::aes()] mapping. Required aesthetics are
#'   `x` (date) and `label` (topic text). Optional aesthetics include
#'   `colour`, `fill`, `shape`, `size`, `linetype`, `alpha`, and `group`
#'   for shared styling.
#' @param style Timeline visual style: `"classic"` (axis points with ring
#'   endpoints), `"ribbon"` (thick bar with boxed labels), `"milestone"`
#'   (boxed labels with endpoint markers), or `"minimal"` (compact dotted
#'   connectors).
#' @param side Label placement: `"auto"` (default), `"alternate"`, `"above"`,
#'   or `"below"`.
#' @param elbowed If `TRUE` (default), use elbowed connectors.
#' @param base_height Base distance from the axis to the first label tier.
#' @param height_step Additional vertical offset per overlap tier on the same
#'   side. Increase to add more space between stacked labels.
#' @param label_width_days Approximate horizontal label width for overlap
#'   detection.
#' @param label_size Topic label text size.
#' @param min_gap_days Minimum horizontal gap between labels on the same side.
#' @param axis_y Y position of the timeline axis.
#' @param axis_arrow If `TRUE` (default), draw a closed arrowhead at the
#'   right end of the axis pointing toward the future.
#' @param start_cap If `TRUE` (default for classic/milestone), draw a filled
#'   dot at the left origin of the axis.
#' @param connector_colour Colour for elbow connector lines. Defaults to a
#'   style-specific neutral grey.
#' @param year_breaks Year annotations along the axis. `NULL` omits year labels.
#'   `"auto"` picks a sensible interval from the date span. A string like
#'   `"2 years"` or `"5 years"` sets a fixed interval. A numeric vector of
#'   years or Date vector sets explicit positions. See [compute_year_breaks()].
#' @param year_labels Optional character labels for year breaks.
#' @param year_side Placement of year labels: `"alternate"` (default), `"above"`,
#'   or `"below"` the axis.
#' @param year_size Year label text size.
#' @param year_colours Optional character vector of colours cycling across
#'   year labels.
#' @param year_offset Distance of year labels from the axis in y-units.
#' @param date_breaks Date breaks for the (hidden) x scale; used mainly when
#'   `year_breaks = NULL`.
#' @param date_labels Date label format for the x scale when `year_breaks = NULL`.
#' @param expand Axis padding beyond first/last events (fraction of range).
#' @param background Plot background colour.
#' @return A [ggplot2::ggplot()] object that can be further customised with
#'   standard ggplot2 layers, scales, and themes.
#' @export
#' @examples
#' \donttest{
#' library(ggplot2)
#' data("phenotype_methods_timeline")
#'
#' ggtimeline(
#'   phenotype_methods_timeline,
#'   aes(x = date, label = topic, colour = category, fill = category),
#'   style = "classic",
#'   year_breaks = "2 years",
#'   base_height = 1.1,
#'   height_step = 0.7
#' ) +
#'   scale_timeline_colour() +
#'   scale_timeline_fill()
#' }
ggtimeline <- function(data,
                       mapping,
                       style = c("classic", "ribbon", "minimal", "milestone"),
                       side = c("auto", "alternate", "above", "below"),
                       elbowed = TRUE,
                       base_height = 1,
                       height_step = 0.6,
                       label_width_days = 90,
                       label_size = 3.2,
                       min_gap_days = 14,
                       axis_y = 0,
                       axis_arrow = TRUE,
                       start_cap = NULL,
                       connector_colour = NULL,
                       year_breaks = NULL,
                       year_labels = NULL,
                       year_side = c("alternate", "above", "below"),
                       year_size = 5.5,
                       year_colours = NULL,
                       year_offset = 0.32,
                       date_breaks = ggplot2::waiver(),
                       date_labels = "%Y",
                       expand = 0.08,
                       background = "#F5F4F0") {
  style <- match.arg(style)
  side <- match.arg(side)
  year_side <- match.arg(year_side)
  style_params <- .timeline_style_params(style)

  if (missing(mapping)) {
    rlang::abort("`mapping` must be supplied.")
  }

  cols <- .resolve_cols(data, mapping)
  if (!cols$date %in% names(data)) {
    rlang::abort(sprintf("Column '%s' not found in `data`.", cols$date))
  }

  mapping_names <- .get_mapping_names(mapping)
  label_col <- if ("label" %in% names(mapping_names)) {
    mapping_names[["label"]]
  } else {
    cols$topic
  }
  if (!label_col %in% names(data)) {
    rlang::abort(sprintf("Label column '%s' not found in `data`.", label_col))
  }

  if (is.null(start_cap)) {
    start_cap <- isTRUE(style_params$start_cap)
  }
  if (is.null(connector_colour)) {
    connector_colour <- style_params$connector_colour
  }

  config <- list(
    axis_y = axis_y,
    base_height = base_height,
    height_step = height_step,
    label_width_days = label_width_days,
    min_gap_days = min_gap_days,
    elbow_fraction = 0.35
  )

  layout <- .build_layout(
    data = data,
    date_col = cols$date,
    topic_col = label_col,
    side = side,
    config = config,
    group_col = cols$group
  )

  plot_df <- cbind(data, layout)
  plot_df$y <- axis_y
  date_vec <- data[[cols$date]]
  x_num <- .date_to_numeric(date_vec)

  x_range <- range(x_num, na.rm = TRUE)
  pad <- diff(x_range) * expand
  if (!is.finite(pad) || pad == 0) {
    pad <- 365
  }

  axis_df <- data.frame(
    xmin = as.Date(x_range[1] - pad, origin = "1970-01-01"),
    xmax = as.Date(x_range[2] + pad * 1.15, origin = "1970-01-01"),
    y = axis_y
  )

  year_df <- NULL
  if (!is.null(year_breaks)) {
    year_df <- compute_year_breaks(
      from = axis_df$xmin,
      to = axis_df$xmax,
      breaks = year_breaks,
      labels = year_labels,
      side = year_side,
      axis_y = axis_y,
      colours = year_colours %||% timeline_palette()[seq_len(10)]
    )
  }

  y_vals <- c(plot_df$.timeline_label_y, axis_y)
  if (!is.null(year_df) && nrow(year_df) > 0L) {
    year_y <- year_df$y + ifelse(
      year_df$.timeline_year_side == "above",
      year_offset,
      -year_offset
    )
    y_vals <- c(y_vals, year_y)
  }
  y_range <- range(y_vals, na.rm = TRUE)
  y_pad <- max(diff(y_range) * 0.12, 0.55)

  p <- ggplot2::ggplot(plot_df, mapping)

  p <- p +
    geom_timeline_axis(
      data = axis_df,
      mapping = ggplot2::aes(xmin = xmin, xmax = xmax, y = y),
      inherit.aes = FALSE,
      size = style_params$axis_size,
      colour = style_params$axis_color,
      arrow = axis_arrow,
      start_cap = start_cap
    )

  if (!is.null(year_df) && nrow(year_df) > 0L) {
    p <- p + geom_timeline_year(
      data = year_df,
      mapping = ggplot2::aes(
        x = x,
        y = y,
        label = label,
        .timeline_year_side = .timeline_year_side,
        colour = if ("colour" %in% names(year_df)) .data[["colour"]] else NULL
      ),
      inherit.aes = FALSE,
      size = year_size,
      offset = year_offset
    )
  }

  if (!is.na(style_params$point_shape)) {
    p <- p + geom_timeline_point(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        y = y
      ),
      stat = "identity",
      shape = style_params$point_shape,
      fill = style_params$point_fill,
      stroke = style_params$point_stroke,
      size = 3.2
    )
  }

  p <- p + geom_timeline_connector(
    mapping = ggplot2::aes(
      x = .data[[cols$date]],
      y = y,
      .timeline_elbow_x = .timeline_elbow_x,
      .timeline_label_y = .timeline_label_y
    ),
    inherit.aes = TRUE,
    elbowed = elbowed,
    linetype = style_params$connector_linetype,
    colour = connector_colour,
    stat = "identity"
  )

  if (isTRUE(style_params$endpoint)) {
    p <- p + geom_timeline_endpoint(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        .timeline_label_y = .timeline_label_y
      ),
      fill = style_params$point_fill,
      stat = "identity",
      size = 4.8,
      stroke = 1.3
    )
  }

  if (isTRUE(style_params$label_box)) {
    p <- p + ggplot2::geom_label(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        y = .timeline_label_y,
        label = .data[[label_col]]
      ),
      inherit.aes = TRUE,
      size = label_size * 0.85,
      label.size = 0.12,
      label.padding = grid::unit(3, "pt"),
      label.r = grid::unit(4, "pt"),
      fontface = "bold",
      colour = "white",
      vjust = ifelse(plot_df$.timeline_side == "above", 0, 1),
      hjust = 0
    )
  } else {
    p <- p + geom_timeline_label(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        label = .data[[label_col]],
        .timeline_label_y = .timeline_label_y,
        .timeline_side = .timeline_side
      ),
      inherit.aes = TRUE,
      stat = "identity",
      size = label_size,
      fontface = "bold",
      colour = "#2A2A2A"
    )
  }

  x_scale <- if (is.null(year_breaks)) {
    ggplot2::scale_x_date(
      breaks = date_breaks,
      date_labels = date_labels,
      expand = ggplot2::expansion(mult = c(expand, expand * 1.2))
    )
  } else {
    ggplot2::scale_x_date(
      breaks = NULL,
      labels = NULL,
      expand = ggplot2::expansion(mult = c(expand, expand * 1.2))
    )
  }

  p +
    x_scale +
    ggplot2::scale_y_continuous(
      limits = c(y_range[1] - y_pad, y_range[2] + y_pad),
      expand = c(0, 0)
    ) +
    .timeline_theme(background = background)
}

#' Timeline scale helpers
#'
#' @param palette Character vector of colours for timeline categories.
#'   Defaults to [timeline_palette()].
#' @param ... Additional arguments passed to [ggplot2::scale_colour_manual()]
#'   or [ggplot2::scale_fill_manual()].
#' @name timeline_scales
#' @export
scale_timeline_colour <- function(palette = NULL, ...) {
  if (is.null(palette)) {
    palette <- timeline_palette()
  }
  ggplot2::scale_colour_manual(values = palette, ...)
}

#' @rdname timeline_scales
#' @export
scale_timeline_fill <- function(palette = NULL, ...) {
  if (is.null(palette)) {
    palette <- timeline_palette()
  }
  ggplot2::scale_fill_manual(values = palette, ...)
}

#' @rdname timeline_scales
#' @export
scale_timeline_shape <- function(...) {
  ggplot2::scale_shape_manual(
    values = c(
      "peer-reviewed" = 21,
      "preprint" = 24
    ),
    ...
  )
}

#' @rdname timeline_scales
#' @param guide A ggplot2 guide function, typically [ggplot2::guide_legend()].
#' @export
timeline_group_guide <- function(guide = ggplot2::guide_legend(
  override.aes = list(
    linetype = 0,
    size = 4
  )
)) {
  guide
}
