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
#' @param base_height Base distance from axis to first label tier.
#' @param height_step Additional vertical offset per overlap tier.
#' @param label_width_days Approximate label width for overlap detection.
#' @param min_gap_days Minimum horizontal gap between labels on the same side.
#' @param axis_y Y position of the timeline axis.
#' @param date_breaks Date breaks passed to [ggplot2::scale_x_date()].
#' @param date_labels Date label format passed to [ggplot2::scale_x_date()].
#' @param expand Axis padding beyond first/last events (fraction of range).
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
#'   style = "classic"
#' ) +
#'   scale_timeline_colour() +
#'   scale_timeline_fill()
#' }
ggtimeline <- function(data,
                       mapping,
                       style = c("classic", "ribbon", "minimal", "milestone"),
                       side = c("auto", "alternate", "above", "below"),
                       elbowed = TRUE,
                       base_height = 0.8,
                       height_step = 0.55,
                       label_width_days = 90,
                       min_gap_days = 14,
                       axis_y = 0,
                       date_breaks = ggplot2::waiver(),
                       date_labels = "%Y",
                       expand = 0.06) {
  style <- match.arg(style)
  side <- match.arg(side)
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
    xmax = as.Date(x_range[2] + pad, origin = "1970-01-01"),
    y = axis_y
  )

  y_vals <- c(plot_df$.timeline_label_y, axis_y)
  y_range <- range(y_vals, na.rm = TRUE)
  y_pad <- max(diff(y_range) * 0.15, 0.5)

  p <- ggplot2::ggplot(plot_df, mapping)

  p <- p +
    geom_timeline_axis(
      data = axis_df,
      mapping = ggplot2::aes(xmin = xmin, xmax = xmax, y = y),
      inherit.aes = FALSE,
      size = style_params$axis_size,
      colour = style_params$axis_color
    )

  if (!is.na(style_params$point_shape)) {
    p <- p + geom_timeline_point(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        y = y
      ),
      stat = "identity",
      shape = style_params$point_shape,
      fill = style_params$point_fill,
      stroke = style_params$point_stroke
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
    stat = "identity"
  )

  if (isTRUE(style_params$endpoint)) {
    p <- p + geom_timeline_endpoint(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        .timeline_label_y = .timeline_label_y
      ),
      fill = style_params$point_fill,
      stat = "identity"
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
      size = 2.8,
      label.size = 0.15,
      label.padding = grid::unit(2, "pt"),
      label.r = grid::unit(3, "pt"),
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
      fontface = "bold"
    )
  }

  p +
    ggplot2::scale_x_date(
      breaks = date_breaks,
      date_labels = date_labels,
      expand = ggplot2::expansion(mult = c(expand, expand))
    ) +
    ggplot2::scale_y_continuous(
      limits = c(y_range[1] - y_pad, y_range[2] + y_pad),
      expand = c(0, 0)
    ) +
    .timeline_theme()
}

#' Timeline scale helpers
#'
#' @param palette Character vector of colours for timeline categories.
#' @param ... Additional arguments passed to [ggplot2::scale_colour_manual()]
#'   or [ggplot2::scale_fill_manual()].
#' @name timeline_scales
#' @export
scale_timeline_colour <- function(palette = NULL, ...) {
  if (is.null(palette)) {
    palette <- c(
      "bulk+sc" = "#4E79A7",
      "sc cohort" = "#59A14F",
      "spatial+bulk" = "#E15759",
      "meta-framework" = "#B07AA1",
      "other" = "#F28E2B"
    )
  }
  ggplot2::scale_colour_manual(values = palette, ...)
}

#' @rdname timeline_scales
#' @export
scale_timeline_fill <- function(palette = NULL, ...) {
  if (is.null(palette)) {
    palette <- c(
      "bulk+sc" = "#4E79A7",
      "sc cohort" = "#59A14F",
      "spatial+bulk" = "#E15759",
      "meta-framework" = "#B07AA1",
      "other" = "#F28E2F"
    )
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
