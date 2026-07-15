#' Gantt-chart timeline variant
#'
#' Same aesthetic grammar as [ggtimeline()] but renders one horizontal bar
#' per row (grouped by an explicit `y` aesthetic, or by `label` when `y` is
#' not mapped) instead of a single shared arrow axis. Point events (no
#' `xend`/`xmax`) are drawn as short bars so they stay visible.
#'
#' @param data Event / interval data frame.
#' @param mapping An [ggplot2::aes()] mapping. Requires `x` (start date) and
#'   `label` (row/bar text). Optional `xend` (or `xmax`) for interval bars;
#'   optional `y` to control row grouping/order explicitly (otherwise rows
#'   are one per unique `label`, in first-appearance order). Other optional
#'   aesthetics include `fill` and `colour`.
#' @param bar_height Vertical thickness of each Gantt bar (in row units,
#'   `0`-`1`).
#' @param row_spacing Vertical distance between row centres.
#' @param label_position Where row labels are drawn: `"inside"` (default,
#'   left-aligned inside/near the bar start), `"axis"` (as y-axis row
#'   labels only), or `"none"` (no text labels; still shows the y axis
#'   categories).
#' @param label_size Text size for in-plot row labels.
#' @param label_colour Colour for in-plot row labels. Defaults to a colour
#'   that contrasts with `background`.
#' @param date_breaks,date_labels Passed to [ggplot2::scale_x_date()].
#' @param background Plot background colour.
#' @param ... Reserved for forward compatibility.
#' @return A [ggplot2::ggplot()] object.
#' @export
#' @examples
#' \donttest{
#' library(ggplot2)
#' trials <- data.frame(
#'   start = as.Date(c("2021-01-01", "2022-06-01", "2023-01-01")),
#'   end   = as.Date(c("2021-09-01", "2023-02-01", "2023-08-01")),
#'   topic = c("Phase I", "Phase II", "Phase III"),
#'   arm   = c("A", "B", "A")
#' )
#' ggtimeline_gantt(trials, aes(x = start, xend = end, label = topic, fill = arm))
#' }
ggtimeline_gantt <- function(data,
                             mapping,
                             bar_height = 0.55,
                             row_spacing = 1,
                             label_position = c("inside", "axis", "none"),
                             label_size = 3.2,
                             label_colour = NULL,
                             date_breaks = ggplot2::waiver(),
                             date_labels = "%Y",
                             background = "white",
                             ...) {
  label_position <- match.arg(label_position)
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
  mapping_names <- .get_mapping_names(mapping)
  label_col <- if ("label" %in% names(mapping_names)) {
    mapping_names[["label"]]
  } else {
    cols$topic
  }
  if (!label_col %in% names(data)) {
    rlang::abort(sprintf("Label column '%s' not found in `data`.", label_col))
  }
  has_end <- !is.null(cols$date_end) && cols$date_end %in% names(data)

  start_num <- .date_to_numeric(data[[cols$date]])
  end_num <- if (has_end) .date_to_numeric(data[[cols$date_end]]) else start_num
  swap <- is.finite(end_num) & is.finite(start_num) & end_num < start_num
  if (any(swap, na.rm = TRUE)) {
    tmp <- start_num[swap]
    start_num[swap] <- end_num[swap]
    end_num[swap] <- tmp
  }
  span <- diff(range(c(start_num, end_num), na.rm = TRUE))
  if (!is.finite(span) || span <= 0) {
    span <- 365
  }
  # Zero-length (point) events get a small visible sliver bar.
  min_bar <- max(span * 0.006, 1)
  zero_len <- (end_num - start_num) < min_bar
  end_num[zero_len] <- start_num[zero_len] + min_bar

  y_col <- if ("y" %in% names(mapping_names)) mapping_names[["y"]] else NULL
  if (!is.null(y_col) && y_col %in% names(data)) {
    row_vals <- data[[y_col]]
  } else {
    row_vals <- data[[label_col]]
  }
  row_levels <- unique(as.character(row_vals))
  row_factor <- factor(as.character(row_vals), levels = row_levels)
  # First row at the top, consistent with conventional Gantt charts.
  n_rows <- length(row_levels)
  row_y <- (n_rows - as.numeric(row_factor) + 1L) * row_spacing

  plot_df <- data
  plot_df$.gantt_y <- row_y
  plot_df$.gantt_xmin <- .as_date_like(data[[cols$date]], start_num)
  plot_df$.gantt_xmax <- .as_date_like(data[[cols$date]], end_num)

  bar_map <- ggplot2::aes(xmin = .gantt_xmin, xmax = .gantt_xmax, y = .gantt_y)
  if (!is.null(cols$fill) && cols$fill %in% names(plot_df)) {
    bar_map <- utils::modifyList(bar_map, ggplot2::aes(fill = .data[[cols$fill]]))
  }
  if (!is.null(cols$colour) && cols$colour %in% names(plot_df)) {
    bar_map <- utils::modifyList(bar_map, ggplot2::aes(colour = .data[[cols$colour]]))
  }
  span_args <- list(
    data = plot_df,
    mapping = bar_map,
    inherit.aes = FALSE,
    height = bar_height / 2,
    alpha = 0.92
  )
  if (is.null(cols$fill) || !cols$fill %in% names(plot_df)) {
    span_args$fill <- timeline_palette()[1]
  }
  if (is.null(cols$colour) || !cols$colour %in% names(plot_df)) {
    span_args$colour <- NA
  }

  p <- ggplot2::ggplot(plot_df, mapping) +
    do.call(geom_timeline_span, span_args)

  if (identical(label_position, "inside")) {
    text_colour <- label_colour %||% "#2A2A2A"
    p <- p + ggplot2::geom_text(
      data = plot_df,
      mapping = ggplot2::aes(x = .gantt_xmin, y = .gantt_y, label = .data[[label_col]]),
      inherit.aes = FALSE,
      hjust = 0,
      vjust = 0.5,
      nudge_x = span * 0.012,
      nudge_y = bar_height * 0.62,
      size = label_size,
      fontface = "bold",
      colour = text_colour
    )
  }

  y_breaks <- (n_rows - seq_len(n_rows) + 1L) * row_spacing
  y_labels <- row_levels

  p +
    ggplot2::scale_x_date(breaks = date_breaks, date_labels = date_labels) +
    ggplot2::scale_y_continuous(
      breaks = y_breaks,
      labels = y_labels,
      limits = c(0.5 * row_spacing, (n_rows + 0.6) * row_spacing),
      expand = c(0, 0)
    ) +
    theme_timeline("minimal") +
    ggplot2::theme(
      axis.text.y = if (!identical(label_position, "none")) {
        ggplot2::element_text(colour = "#333333", size = ggplot2::rel(0.9), hjust = 1)
      } else {
        ggplot2::element_blank()
      },
      axis.text.x = ggplot2::element_text(colour = "#555555", size = ggplot2::rel(0.85)),
      axis.line.x = ggplot2::element_line(colour = "grey70", linewidth = 0.4),
      axis.ticks.x = ggplot2::element_line(colour = "grey70", linewidth = 0.3),
      panel.grid.major.x = ggplot2::element_line(colour = "grey92", linewidth = 0.3),
      plot.background = ggplot2::element_rect(fill = background, colour = NA),
      panel.background = ggplot2::element_rect(fill = background, colour = NA)
    )
}

.as_date_like <- function(reference, numeric_vals) {
  if (inherits(reference, "Date")) {
    as.Date(numeric_vals, origin = "1970-01-01")
  } else {
    numeric_vals
  }
}
