#' Timeline layout stat
#'
#' Computes label positions, sides (above/below), staggered heights, and
#' elbow connector coordinates for timeline events.
#'
#' @inheritParams ggplot2::layer
#' @param side Label placement strategy: `"auto"` (default) picks above or
#'   below to reduce overlap, `"alternate"` alternates sides, or force
#'   `"above"` / `"below"`.
#' @param base_height Base distance from the axis to the first label tier.
#' @param height_step Additional vertical offset per overlap tier.
#' @param label_width_days Approximate horizontal label width in date units
#'   for overlap detection.
#' @param min_gap_days Minimum horizontal gap between labels on the same side.
#' @param elbow_fraction Horizontal fraction of the connector elbow segment.
#' @param axis_y Y position of the timeline axis.
#' @inheritParams ggplot2::layer
#' @param ... Additional arguments passed to [ggplot2::layer()].
#' @export
#' @rdname stat_timeline
stat_timeline <- function(mapping = NULL, data = NULL,
                          geom = "point",
                          position = "identity",
                          side = "auto",
                          base_height = 0.8,
                          height_step = 0.55,
                          label_width_days = 90,
                          min_gap_days = 14,
                          elbow_fraction = 0.35,
                          axis_y = 0,
                          show.legend = FALSE,
                          inherit.aes = TRUE,
                          ...) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = StatTimeline,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      side = side,
      base_height = base_height,
      height_step = height_step,
      label_width_days = label_width_days,
      min_gap_days = min_gap_days,
      elbow_fraction = elbow_fraction,
      axis_y = axis_y,
      ...
    )
  )
}

#' @rdname stat_timeline
#' @export
StatTimeline <- ggplot2::ggproto(
  "StatTimeline",
  ggplot2::Stat,
  required_aes = c("x", "label"),
  default_aes = ggplot2::aes(
    y = 0,
    shape = 21,
    size = 3,
    colour = "grey30",
    fill = NA,
    alpha = 1,
    linetype = 1
  ),

  setup_params = function(data, params) {
    params
  },

  compute_panel = function(self, data, scales,
                           side = "auto",
                           base_height = 0.8,
                           height_step = 0.55,
                           label_width_days = 90,
                           min_gap_days = 14,
                           elbow_fraction = 0.35,
                           axis_y = 0) {
    if (nrow(data) == 0L) {
      return(data)
    }

    config <- list(
      axis_y = axis_y,
      base_height = base_height,
      height_step = height_step,
      label_width_days = label_width_days,
      min_gap_days = min_gap_days,
      elbow_fraction = elbow_fraction
    )

    dates <- .date_to_numeric(scales$x$map(data$x))
    labels <- as.character(data$label)
    sides <- .compute_sides(
      dates,
      sides = side,
      labels = labels,
      config = config
    )
    resolved <- .resolve_side_conflicts(
      dates = dates,
      labels = labels,
      sides = sides,
      config = config,
      label_size = 3.2,
      boxed = FALSE
    )
    label_y <- resolved$label_y
    label_x_num <- resolved$label_x
    tiers <- resolved$tiers

    if (inherits(data$x, "Date") || (is.numeric(data$x) && mean(dates, na.rm = TRUE) > 10000)) {
      label_x <- as.Date(label_x_num, origin = "1970-01-01")
    } else {
      label_x <- label_x_num
    }

    data$.timeline_x <- dates
    data$.timeline_y <- rep(config$axis_y, nrow(data))
    data$.timeline_label_x <- label_x
    data$.timeline_label_y <- label_y
    data$.timeline_anchor_x <- data$x
    data$.timeline_side <- sides
    data$.timeline_tier <- tiers
    data$y <- data$.timeline_y
    data
  }
)
