#' Swimlane timeline with parallel category arrows
#'
#' Stacks one ribbon-style arrow lane per group (e.g. method family or
#' project stream) on a single shared date axis. Each lane gets its own
#' thick bar axis, connectors, and labels; era bands and year breaks (when
#' requested) span the full stack.
#'
#' @param data Event data frame.
#' @param mapping Aesthetics; must include `x` (event date) and `label`
#'   (topic text), plus a grouping column via `group`, `fill`, or `colour`
#'   (checked in that order) to determine lanes. Optional `xend`/`xmax` for
#'   interval events (drawn as span bars), and other aesthetics as in
#'   [ggtimeline()].
#' @param lane_spacing Vertical distance between consecutive lane axes.
#' @param side Label placement per lane: `"auto"` (default), `"alternate"`,
#'   `"above"`, or `"below"`.
#' @param elbowed If `TRUE`, use elbowed connectors.
#' @param base_height,height_step,label_width_days,min_gap_days,label_method
#'   Layout parameters; see [ggtimeline()].
#' @param label_size Topic label text size.
#' @param axis_height,axis_tip,axis_fill Bar axis appearance; see
#'   [geom_timeline_axis()].
#' @param connector_colour,connector_size Connector line appearance.
#' @param label_box If `TRUE` (default), draw boxed labels.
#' @param span_height,span_alpha Interval span-bar appearance (used only
#'   when `xend`/`xmax` is mapped).
#' @param eras Optional era bands spanning the full lane stack; see
#'   [geom_timeline_era()] / [ggtimeline()].
#' @param era_alpha Default era band opacity.
#' @param year_breaks,year_labels,year_size,year_colours Year annotations
#'   drawn once above the top lane; see [compute_year_breaks()].
#' @param expand Fraction of the event date span used for horizontal padding.
#' @param lane_labels If `TRUE` (default), draw the lane/group name to the
#'   left of each lane's axis.
#' @param lane_label_size Text size for lane name labels.
#' @param background Plot background colour.
#' @param ... Reserved for forward compatibility.
#' @return A [ggplot2::ggplot()] object.
#' @export
#' @seealso [facet_timeline()], [ggtimeline()]
#' @examples
#' \donttest{
#' library(ggplot2)
#' data("phenotype_methods_timeline")
#' ggtimeline_swimlane(
#'   phenotype_methods_timeline,
#'   aes(x = date, label = topic, group = category, fill = category),
#'   lane_spacing = 3
#' )
#' }
ggtimeline_swimlane <- function(data,
                                mapping,
                                lane_spacing = 3.2,
                                side = c("auto", "alternate", "above", "below"),
                                elbowed = FALSE,
                                base_height = 1.1,
                                height_step = 0.75,
                                label_width_days = 100,
                                min_gap_days = 21,
                                label_method = "simple",
                                label_size = 3,
                                axis_height = 0.42,
                                axis_tip = 0.015,
                                axis_fill = "white",
                                connector_colour = "#A8A8A4",
                                connector_size = 0.45,
                                label_box = TRUE,
                                span_height = 0.12,
                                span_alpha = 0.8,
                                eras = NULL,
                                era_alpha = 0.16,
                                year_breaks = NULL,
                                year_labels = NULL,
                                year_size = 4.8,
                                year_colours = NULL,
                                expand = 0.1,
                                lane_labels = TRUE,
                                lane_label_size = 3.6,
                                background = "white",
                                ...) {
  side <- match.arg(side)
  if (missing(mapping)) {
    rlang::abort("`mapping` must be supplied.")
  }
  if (!is.data.frame(data) || nrow(data) == 0L) {
    rlang::abort("`data` must be a non-empty data frame.")
  }

  cols <- .resolve_cols(data, mapping)
  if (!cols$date %in% names(data)) {
    rlang::abort(sprintf("Column '%s' not found in `data`.", cols$date))
  }
  group_col <- cols$group %||% cols$fill %||% cols$colour
  if (is.null(group_col) || !group_col %in% names(data)) {
    rlang::abort(
      "`ggtimeline_swimlane()` needs a grouping column via aes(group = ), aes(fill = ), or aes(colour = )."
    )
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
  has_intervals <- !is.null(cols$date_end) && cols$date_end %in% names(data)

  group_vals <- data[[group_col]]
  if (!is.factor(group_vals)) {
    group_vals <- factor(group_vals, levels = unique(as.character(group_vals)))
  }
  lane_names <- levels(group_vals)
  lanes <- split(data, group_vals)
  lanes <- lanes[vapply(lanes, nrow, integer(1)) > 0L]
  lane_names <- lane_names[lane_names %in% names(lanes)]
  n_lanes <- length(lanes)
  if (n_lanes == 0L) {
    rlang::abort("No non-empty lanes found for `ggtimeline_swimlane()`.")
  }

  date_vec <- data[[cols$date]]
  x_num <- .date_to_numeric(date_vec)
  if (has_intervals) {
    x_end_num <- .date_to_numeric(data[[cols$date_end]])
    x_range <- range(c(x_num, x_end_num), na.rm = TRUE)
  } else {
    x_range <- range(x_num, na.rm = TRUE)
  }
  event_span <- diff(x_range)
  if (!is.finite(event_span) || event_span <= 0) {
    event_span <- 365
  }
  plot_span <- event_span * (1 + expand * 2.2)

  plot_pieces <- vector("list", n_lanes)
  axis_pieces <- vector("list", n_lanes)
  lane_label_pieces <- vector("list", n_lanes)

  for (i in seq_len(n_lanes)) {
    axis_y_i <- (i - 1L) * lane_spacing
    ld <- lanes[[lane_names[i]]]
    config <- list(
      axis_y = axis_y_i,
      base_height = base_height,
      height_step = height_step,
      label_width_days = label_width_days,
      min_gap_days = min_gap_days,
      elbow_fraction = 0.35,
      plot_span = plot_span
    )
    layout <- .build_layout(
      data = ld,
      date_col = cols$date,
      topic_col = label_col,
      side = side,
      config = config,
      group_col = cols$group,
      label_size = label_size,
      boxed = isTRUE(label_box),
      label_method = label_method,
      date_end_col = if (has_intervals) cols$date_end else NULL
    )
    pd <- cbind(ld, layout)
    # `.build_layout()` computes label offsets relative to a zero baseline;
    # shift them onto this lane's own axis position.
    pd$.timeline_label_y <- pd$.timeline_label_y + axis_y_i
    pd$y <- ifelse(
      pd$.timeline_side == "above",
      axis_y_i + axis_height,
      axis_y_i - axis_height
    )
    pd$.timeline_span_y <- ifelse(
      pd$.timeline_side == "above",
      pd$y + span_height + 0.03,
      pd$y - span_height - 0.03
    )
    pd$.timeline_stem_y <- ifelse(
      pd$.timeline_is_interval,
      pd$.timeline_span_y,
      pd$y
    )
    pd$.timeline_lane <- lane_names[i]
    plot_pieces[[i]] <- pd

    axis_pieces[[i]] <- data.frame(
      xmin = as.Date(x_range[1] - event_span * 0.02, origin = "1970-01-01"),
      xmax = as.Date(x_range[2] + max(event_span * axis_tip * 1.25, 35) +
                       event_span * 0.03, origin = "1970-01-01"),
      y = axis_y_i,
      .timeline_lane = lane_names[i]
    )
    lane_label_pieces[[i]] <- data.frame(
      x = as.Date(x_range[1] - event_span * 0.02, origin = "1970-01-01"),
      y = axis_y_i,
      label = as.character(lane_names[i])
    )
  }

  plot_df <- do.call(rbind, plot_pieces)
  axis_df <- do.call(rbind, axis_pieces)
  lane_label_df <- do.call(rbind, lane_label_pieces)

  y_vals <- c(
    plot_df$.timeline_label_y,
    axis_df$y - axis_height,
    axis_df$y + axis_height
  )
  y_range <- range(y_vals, na.rm = TRUE)
  y_pad <- max(height_step * 0.6, 0.4)
  y_limits <- c(y_range[1] - y_pad, y_range[2] + y_pad)

  year_df <- NULL
  top_axis_y <- max(axis_df$y) + axis_height
  if (!is.null(year_breaks)) {
    year_df <- compute_year_breaks(
      from = min(axis_df$xmin),
      to = max(axis_df$xmax),
      breaks = year_breaks,
      labels = year_labels,
      side = "above",
      axis_y = top_axis_y,
      colours = year_colours %||% timeline_palette()[seq_len(10)]
    )
    if (!is.null(year_df) && nrow(year_df) > 0L) {
      if ("colour" %in% names(year_df)) {
        year_df$.timeline_year_colour <- year_df$colour
        year_df$colour <- NULL
      }
      y_limits[2] <- max(y_limits[2], top_axis_y + 0.32 + y_pad)
    }
  }

  era_df <- .normalise_eras(eras, palette = timeline_palette(), default_alpha = era_alpha)

  p <- ggplot2::ggplot(plot_df, mapping)

  if (!is.null(era_df) && nrow(era_df) > 0L) {
    era_df$ymin <- y_limits[1]
    era_df$ymax <- y_limits[2]
    p <- p + geom_timeline_era(
      data = era_df,
      mapping = ggplot2::aes(
        xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, label = label
      ),
      inherit.aes = FALSE,
      alpha = era_alpha,
      show_bounds = TRUE
    )
  }

  p <- p + geom_timeline_axis(
    data = axis_df,
    mapping = ggplot2::aes(xmin = xmin, xmax = xmax, y = y),
    inherit.aes = FALSE,
    colour = "#6B6B66",
    fill = axis_fill,
    shape = "bar",
    height = axis_height,
    tip_frac = axis_tip
  )

  if (isTRUE(lane_labels)) {
    p <- p + ggplot2::geom_text(
      data = lane_label_df,
      mapping = ggplot2::aes(x = x, y = y, label = label),
      inherit.aes = FALSE,
      hjust = 1,
      nudge_x = -event_span * 0.012,
      size = lane_label_size,
      fontface = "bold",
      colour = "#2A2A2A"
    )
  }

  if (has_intervals && any(plot_df$.timeline_is_interval)) {
    span_df <- plot_df[plot_df$.timeline_is_interval, , drop = FALSE]
    span_map <- ggplot2::aes(xmin = .timeline_x_start, xmax = .timeline_x_end, y = .timeline_span_y)
    if (!is.null(cols$fill) && cols$fill %in% names(span_df)) {
      span_map <- utils::modifyList(span_map, ggplot2::aes(fill = .data[[cols$fill]]))
    }
    p <- p + geom_timeline_span(
      data = span_df,
      mapping = span_map,
      inherit.aes = FALSE,
      height = span_height,
      alpha = span_alpha,
      colour = NA,
      show.legend = TRUE
    )
  }

  p <- p + geom_timeline_connector(
    data = plot_df,
    mapping = ggplot2::aes(
      x = .timeline_anchor_x,
      y = .timeline_stem_y,
      .timeline_label_x = .timeline_label_x,
      .timeline_label_y = .timeline_label_y
    ),
    inherit.aes = FALSE,
    elbowed = elbowed,
    colour = connector_colour,
    size = connector_size,
    stat = "identity"
  )

  if (isTRUE(label_box)) {
    p <- p + ggplot2::geom_label(
      mapping = ggplot2::aes(
        x = .timeline_label_x,
        y = .timeline_label_y,
        label = .data[[label_col]]
      ),
      inherit.aes = TRUE,
      size = label_size,
      label.size = 0.12,
      label.padding = grid::unit(4, "pt"),
      label.r = grid::unit(4, "pt"),
      fontface = "bold",
      colour = "white",
      vjust = ifelse(plot_df$.timeline_side == "above", 0, 1),
      hjust = 0.5,
      show.legend = c(fill = TRUE, shape = FALSE, colour = FALSE),
      key_glyph = "polygon"
    )
  } else {
    p <- p + geom_timeline_label(
      mapping = ggplot2::aes(
        x = .data[[cols$date]],
        label = .data[[label_col]],
        .timeline_label_x = .timeline_text_x,
        .timeline_label_y = .timeline_label_y,
        .timeline_side = .timeline_side
      ),
      inherit.aes = TRUE,
      stat = "identity",
      size = label_size,
      fontface = "bold",
      colour = "#2A2A2A",
      show.legend = FALSE
    )
  }

  if (!is.null(year_df) && nrow(year_df) > 0L) {
    p <- p + geom_timeline_year(
      data = year_df,
      mapping = ggplot2::aes(
        x = x, y = y, label = label, .timeline_year_side = .timeline_year_side
      ),
      inherit.aes = FALSE,
      size = year_size,
      offset = 0.32
    )
  }

  x_min <- x_range[1] - event_span * (0.02 + expand * 0.6)
  x_max <- x_range[2] + event_span * (0.05 + expand * 0.6)
  if (isTRUE(lane_labels)) {
    lane_half <- .estimate_year_label_half_days(
      lane_names, year_size = lane_label_size, date_span = max(x_max - x_min, 1)
    )
    x_min <- x_min - lane_half * 2.1
  }

  p +
    ggplot2::scale_x_date(limits = c(as.Date(x_min, origin = "1970-01-01"),
                                     as.Date(x_max, origin = "1970-01-01")),
                          expand = ggplot2::expansion(mult = 0, add = 0)) +
    ggplot2::scale_y_continuous(limits = y_limits, expand = c(0, 0)) +
    .timeline_theme(background = background)
}

#' Facet helper for swimlane-style timelines
#'
#' Thin wrapper over [ggplot2::facet_wrap()] intended for use with
#' [ggtimeline()] output when a per-panel (rather than stacked-lane) layout
#' is preferred. See [ggtimeline_swimlane()] for a single-panel, stacked
#' alternative.
#'
#' @param facets A facetting specification (formula or [ggplot2::vars()]).
#' @param ncol Number of columns. Defaults to `1` (one row per facet).
#' @param scales Axis scale sharing across panels; see
#'   [ggplot2::facet_wrap()]. Defaults to `"free_y"` so each panel keeps its
#'   own label stacking range.
#' @param ... Additional arguments passed to [ggplot2::facet_wrap()].
#' @return A ggplot2 `Facet` object, addable via `+` to a `ggtimeline()` plot.
#' @export
#' @seealso [ggtimeline_swimlane()]
#' @examples
#' \donttest{
#' library(ggplot2)
#' data("phenotype_methods_timeline")
#' ggtimeline(
#'   phenotype_methods_timeline,
#'   aes(x = date, label = topic, fill = category)
#' ) +
#'   facet_timeline(~category)
#' }
facet_timeline <- function(facets, ncol = 1, scales = "free_y", ...) {
  ggplot2::facet_wrap(facets, ncol = ncol, scales = scales, ...)
}
