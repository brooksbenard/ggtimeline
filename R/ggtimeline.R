#' Create a timeline plot
#'
#' High-level interface for building timeline visualisations with sensible
#' defaults. Accepts a data frame with date, topic, and optional aesthetic
#' columns. The current visualisation is a **ribbon** timeline: thick bar
#' arrow with boxed labels, vertical connectors that stack when labels would
#' overlap, optional in-arrow years/era bands, and optional edge markers.
#' Additional visualisation types may be added later via `style`.
#'
#' @param data A data frame containing timeline events.
#' @param mapping An [ggplot2::aes()] mapping. Required aesthetics are
#'   `x` (date) and `label` (topic text). Optional aesthetics include
#'   `colour`, `fill`, `shape`, `size`, `linetype`, `alpha`, and `group`
#'   for shared styling.
#' @param style Visualisation type. Currently only `"ribbon"` is available.
#' @param side Label placement: `"auto"` (default), `"alternate"`, `"above"`,
#'   or `"below"`.
#' @param elbowed If `TRUE`, use elbowed connectors. Defaults to `FALSE`
#'   (straight vertical stems).
#' @param base_height Base distance from the axis to the first label tier.
#' @param height_step Additional vertical offset per overlap tier on the same
#'   side. Increase to add more space between stacked labels.
#' @param label_width_days Approximate horizontal label width for overlap
#'   detection.
#' @param label_size Topic label text size (mm, ggplot2 text size). Applied
#'   directly to plain and boxed labels.
#' @param min_gap_days Minimum horizontal gap between labels on the same side.
#' @param axis_y Y position of the timeline axis.
#' @param axis_shape Axis geometry: `"bar"` (thick arrow body with a normal tip;
#'   years fit inside) or `"line"`. Defaults by style.
#' @param axis_height,axis_width Half-height (vertical thickness) of the bar
#'   arrow in y-units. `axis_width` is an alias for `axis_height`; if both are
#'   set, `axis_width` wins.
#' @param axis_tip Fraction of the axis length used for the right arrowhead
#'   depth. Smaller values give a shorter, less stretched tip. Defaults to
#'   `0.015`.
#' @param axis_fill Interior fill colour of the bar arrow.
#' @param axis_arrow If `TRUE` (default), draw a closed arrowhead at the
#'   right end when `axis_shape = "line"`. Bar tips are always drawn.
#' @param start_cap If `TRUE`, draw a filled dot at the left origin of a line
#'   axis. Ignored for bar axes.
#' @param connector_colour Colour for connector lines. Defaults to a
#'   style-specific colour.
#' @param connector_size Width of connector lines (ggplot2 line size).
#' @param show_points If `TRUE`, draw event markers where connectors meet the
#'   axis. Defaults to `FALSE` (clean stems). When a `shape` aesthetic is
#'   mapped and points are shown, markers use that scale and sit on the bar
#'   edge (not the ribbon centre).
#' @param eras Optional data frame of background era bands with `start`/`end`
#'   (or `xmin`/`xmax`) and optional `label`, `fill`/`colour`, and `alpha`
#'   columns. See [geom_timeline_era()].
#' @param era_alpha Default opacity for era bands when `eras$alpha` is missing.
#' @param era_label_size Text size for era labels drawn at the top of each band.
#' @param era_label_colour Colour for era labels. Defaults to a darkened band
#'   colour when `NULL`.
#' @param year_breaks Year annotations along the axis. `NULL` omits year labels.
#'   `"auto"` picks a sensible interval from the date span. A string like
#'   `"2 years"` or `"5 years"` sets a fixed interval. A numeric vector of
#'   years or Date vector sets explicit positions. See [compute_year_breaks()].
#' @param year_labels Optional character labels for year breaks.
#' @param year_side Placement of year labels: `"inside"` (default for bar
#'   styles; years sit in the arrow body), `"alternate"`, `"above"`, or
#'   `"below"`.
#' @param year_size Year label text size.
#' @param year_colours Optional character vector of colours for year labels.
#'   Defaults to the axis colour when `year_side = "inside"`.
#' @param year_offset Distance of year labels from the axis in y-units.
#'   Ignored when `year_side = "inside"`.
#' @param year_lines Optional dashed vertical year-boundary ticks drawn
#'   **inside the timeline arrow** only (not full-panel era bounds).
#'   `FALSE` (default) omits them. `TRUE` draws a tick every year (or matches
#'   the numeric interval in `year_breaks` when that is like `"2 years"`).
#'   An integer (or string like `"2 years"`) sets the years between ticks.
#' @param year_line_colour Colour for in-arrow year ticks. Defaults to a
#'   medium grey.
#' @param year_line_size,year_line_width Width of in-arrow year ticks
#'   (`year_line_width` is an alias for `year_line_size`).
#' @param year_line_alpha Opacity of in-arrow year ticks (0–1). Defaults to
#'   `0.85`.
#' @param year_line_linetype Linetype for in-arrow year ticks (default
#'   `"dashed"`).
#' @param label_method Label placement algorithm: `"simple"` (default) stacks
#'   overlapping labels vertically with straight connectors; `"auto"` /
#'   `"mark"` allow horizontal spreading; `"repel"` adds a repulsion pass
#'   (soft dependency on **ggrepel**).
#' @param date_breaks Date breaks for the (hidden) x scale; used mainly when
#'   `year_breaks = NULL`.
#' @param date_labels Date label format for the x scale when `year_breaks = NULL`.
#' @param expand Fraction of the event date span used mainly for overall scale
#'   and right-side tip clearance. The left arrow edge stays close to the first
#'   event (a small fraction of this pad); the right side still grows enough to
#'   clear labels and the arrow tip.
#' @param background Plot background colour.
#' @return A [ggplot2::ggplot()] object that can be further customised with
#'   standard ggplot2 layers, scales, and themes.
#' @export
#' @examples
#' \donttest{
#' library(ggplot2)
#' data("phenotype_methods_timeline")
#'
#' eras <- data.frame(
#'   start = as.Date(c("2020-07-01", "2023-01-01", "2025-01-01")),
#'   end = as.Date(c("2022-12-31", "2024-12-31", "2026-12-31")),
#'   label = c("Emergence", "Expansion", "Acceleration"),
#'   fill = c("#4C72B0", "#55A868", "#C44E52")
#' )
#'
#' ggtimeline(
#'   phenotype_methods_timeline,
#'   aes(x = date, label = topic, fill = category, shape = status),
#'   style = "ribbon",
#'   year_breaks = "1 year",
#'   eras = eras,
#'   base_height = 1.3,
#'   height_step = 0.9
#' ) +
#'   scale_timeline_fill() +
#'   scale_timeline_shape()
#' }
ggtimeline <- function(data,
                       mapping,
                       style = "ribbon",
                       side = c("auto", "alternate", "above", "below"),
                       elbowed = NULL,
                       base_height = 1.1,
                       height_step = 0.75,
                       label_width_days = 100,
                       label_size = 3,
                       min_gap_days = 21,
                       label_method = NULL,
                       axis_y = 0,
                       axis_shape = NULL,
                       axis_height = NULL,
                       axis_width = NULL,
                       axis_tip = NULL,
                       axis_fill = NULL,
                       axis_arrow = TRUE,
                       start_cap = NULL,
                       connector_colour = NULL,
                       connector_size = 0.45,
                       show_points = NULL,
                       eras = NULL,
                       era_alpha = 0.16,
                       era_label_size = NULL,
                       era_label_colour = NULL,
                       year_breaks = NULL,
                       year_labels = NULL,
                       year_side = NULL,
                       year_size = 4.8,
                       year_colours = NULL,
                       year_offset = 0.32,
                       year_lines = FALSE,
                       year_line_colour = NULL,
                       year_line_size = 0.35,
                       year_line_width = NULL,
                       year_line_alpha = 0.85,
                       year_line_linetype = "dashed",
                       date_breaks = ggplot2::waiver(),
                       date_labels = "%Y",
                       expand = 0.1,
                       background = "white") {
  style <- match.arg(style, "ribbon")
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

  if (is.null(elbowed)) {
    elbowed <- isTRUE(style_params$elbowed_default)
  }
  if (is.null(label_method)) {
    label_method <- style_params$label_method_default %||% "simple"
  }
  label_method <- match.arg(label_method, c("auto", "mark", "repel", "simple"))
  if (is.null(axis_shape)) {
    axis_shape <- style_params$axis_shape %||% "bar"
  }
  # Accept legacy "chevron" as an alias for the thick bar arrow.
  if (identical(axis_shape, "chevron")) {
    axis_shape <- "bar"
  }
  axis_shape <- match.arg(axis_shape, c("bar", "line"))
  if (!is.null(axis_width)) {
    axis_height <- axis_width
  }
  if (is.null(axis_height)) {
    axis_height <- style_params$axis_height %||% 0.42
  }
  if (is.null(axis_tip) || !is.finite(axis_tip) || axis_tip <= 0) {
    axis_tip <- style_params$axis_tip %||% 0.015
  }
  if (is.null(axis_fill)) {
    axis_fill <- style_params$axis_fill %||% "white"
  }
  if (is.null(start_cap)) {
    start_cap <- isTRUE(style_params$start_cap)
  }
  if (is.null(connector_colour)) {
    connector_colour <- style_params$connector_colour
  }
  if (is.null(connector_size) || !is.finite(connector_size)) {
    connector_size <- 0.45
  }
  if (is.null(show_points)) {
    show_points <- !is.na(style_params$point_shape)
  }
  show_points <- isTRUE(show_points)
  if (is.null(year_side)) {
    year_side <- style_params$year_side_default %||% "alternate"
  }
  year_side <- match.arg(year_side, c("alternate", "above", "below", "inside"))
  if (is.null(era_label_size)) {
    era_label_size <- max(year_size * 0.7, 3.2)
  }

  date_vec <- data[[cols$date]]
  x_num <- .date_to_numeric(date_vec)
  x_range <- range(x_num, na.rm = TRUE)
  event_span <- diff(x_range)
  if (!is.finite(event_span) || event_span <= 0) {
    event_span <- 365
  }
  # Match width estimates to the eventual plot span (event range + expand padding).
  plot_span <- event_span * (1 + expand * 2.2)

  config <- list(
    axis_y = axis_y,
    base_height = base_height,
    height_step = height_step,
    label_width_days = label_width_days,
    min_gap_days = min_gap_days,
    elbow_fraction = 0.35,
    plot_span = plot_span
  )

  layout <- .build_layout(
    data = data,
    date_col = cols$date,
    topic_col = label_col,
    side = side,
    config = config,
    group_col = cols$group,
    label_size = label_size,
    boxed = isTRUE(style_params$label_box),
    label_method = label_method
  )

  plot_df <- cbind(data, layout)
  # Anchor stems on the thick-bar top/bottom edges; thin line axes keep the
  # centerline.
  if (identical(axis_shape, "bar")) {
    plot_df$y <- ifelse(
      plot_df$.timeline_side == "above",
      axis_y + axis_height,
      axis_y - axis_height
    )
  } else {
    plot_df$y <- axis_y
  }

  pad <- event_span * expand
  if (!is.finite(pad) || pad <= 0) {
    pad <- 45
  }

  # Extend the arrow far enough that label boxes/text and the tip are not clipped.
  label_x_num <- .date_to_numeric(layout$.timeline_label_x)
  text_x_num <- .date_to_numeric(layout$.timeline_text_x)
  label_widths <- .estimate_label_width_days(
    as.character(data[[label_col]]),
    config,
    label_size = label_size,
    date_span = plot_span
  )
  if (isTRUE(style_params$label_box)) {
    # Boxed labels are centered on the connector; cap half-width so long
    # labels do not invent a year of empty arrow past the last events.
    half_w <- pmin(label_widths * 0.5, max(event_span * 0.06, 90))
    label_left <- min(label_x_num - half_w, na.rm = TRUE)
    content_max <- max(x_range[2], max(label_x_num + half_w, na.rm = TRUE))
  } else {
    half_w <- pmin(label_widths * 0.85, max(event_span * 0.1, 140))
    label_left <- min(label_x_num, na.rm = TRUE)
    content_max <- max(
      x_range[2],
      max(text_x_num + half_w, na.rm = TRUE)
    )
  }

  tip_len <- max(event_span * axis_tip * 1.25, 35)
  # Keep the left edge close to the first event. `expand` mainly affects the
  # overall scale; left clearance is a light fraction of that pad.
  left_pad <- max(min(pad * 0.22, event_span * 0.02), 14)
  x_min <- x_range[1] - left_pad
  # Tip is drawn inside [xmin, xmax]; push xmax past content so the tip
  # sits fully clear of the last events/labels.
  x_max <- content_max + tip_len

  axis_df <- data.frame(
    xmin = as.Date(x_min, origin = "1970-01-01"),
    xmax = as.Date(x_max, origin = "1970-01-01"),
    y = axis_y
  )

  era_df <- .normalise_eras(
    eras,
    palette = timeline_palette(),
    default_alpha = era_alpha
  )

  year_df <- NULL
  if (!is.null(year_breaks)) {
    if (is.null(year_colours)) {
      if (identical(year_side, "inside") &&
            !is.null(style_params$year_colour_default)) {
        year_colours <- style_params$year_colour_default
      } else {
        year_colours <- timeline_palette()[seq_len(10)]
      }
    }
    year_df <- compute_year_breaks(
      from = axis_df$xmin,
      to = axis_df$xmax,
      breaks = year_breaks,
      labels = year_labels,
      side = year_side,
      axis_y = axis_y,
      colours = year_colours
    )

    # In-arrow (and near-edge) years need horizontal clearance so glyphs are
    # not clipped by the bar ends when an early/late event shares that year.
    if (!is.null(year_df) && nrow(year_df) > 0L) {
      axis_span <- max(x_max - x_min, 1)
      year_half <- .estimate_year_label_half_days(
        labels = year_df$label,
        year_size = year_size,
        date_span = axis_span
      )
      year_buf <- year_half + max(event_span * 0.01, 14)
      year_x <- .date_to_numeric(year_df$x)
      x_min <- min(x_min, min(year_x, na.rm = TRUE) - year_buf)
      body_max <- max(content_max, max(year_x, na.rm = TRUE) + year_buf)
      tip_len <- max(event_span * axis_tip * 1.25, 35)
      x_max <- body_max + tip_len
      axis_df$xmin <- as.Date(x_min, origin = "1970-01-01")
      axis_df$xmax <- as.Date(x_max, origin = "1970-01-01")

      year_df <- compute_year_breaks(
        from = axis_df$xmin,
        to = axis_df$xmax,
        breaks = year_breaks,
        labels = year_labels,
        side = year_side,
        axis_y = axis_y,
        colours = year_colours
      )
      # Keep year labels out of the tip triangle.
      if (!is.null(year_df) && nrow(year_df) > 0L) {
        tip_cut <- x_max - tip_len * 0.9
        keep <- .date_to_numeric(year_df$x) <= tip_cut
        year_df <- year_df[keep, , drop = FALSE]
      }
    }
  }

  y_vals <- c(plot_df$.timeline_label_y, axis_y)
  if (identical(axis_shape, "bar")) {
    y_vals <- c(y_vals, axis_y + axis_height, axis_y - axis_height)
  }
  if (!is.null(year_df) && nrow(year_df) > 0L) {
    year_y <- ifelse(
      year_df$.timeline_year_side == "inside",
      year_df$y,
      year_df$y + ifelse(
        year_df$.timeline_year_side == "above",
        year_offset,
        -year_offset
      )
    )
    y_vals <- c(y_vals, year_y)
  }
  y_range <- range(y_vals, na.rm = TRUE)
  # Account for label glyph/box extent beyond the connector tip, then keep
  # panel padding tight so extreme labels are not surrounded by empty bands.
  glyph_extent <- if (isTRUE(style_params$label_box)) {
    max(height_step * 0.55, label_size * 0.14)
  } else {
    max(height_step * 0.25, label_size * 0.08)
  }
  y_top <- y_range[2] + glyph_extent
  y_bot <- y_range[1] - glyph_extent
  y_pad <- 0.12
  # Slim strip only at the top for era labels (not mirrored below).
  has_era_labels <- !is.null(era_df) &&
    any(!is.na(era_df$label) & nzchar(as.character(era_df$label)))
  era_top_pad <- if (has_era_labels) max(era_label_size * 0.14, 0.5) else 0
  y_limits <- c(y_bot - y_pad, y_top + y_pad + era_top_pad)

  p <- ggplot2::ggplot(plot_df, mapping)

  if (!is.null(era_df) && nrow(era_df) > 0L) {
    # Keep era bands within the arrow span so tighter x-limits do not drop them.
    # Also pull eras that begin before the first event up to the arrow start.
    era_df$xmin <- pmax(era_df$xmin, axis_df$xmin)
    era_df$xmax <- pmin(era_df$xmax, axis_df$xmax)
    era_df <- era_df[era_df$xmax > era_df$xmin, , drop = FALSE]
    era_df$ymin <- y_limits[1]
    era_df$ymax <- y_limits[2]
    # Keep fill/alpha as plain data columns so event fill scales are untouched.
    p <- p + geom_timeline_era(
      data = era_df,
      mapping = ggplot2::aes(
        xmin = xmin,
        xmax = xmax,
        ymin = ymin,
        ymax = ymax,
        label = label
      ),
      inherit.aes = FALSE,
      alpha = era_alpha,
      label_size = era_label_size,
      label_colour = era_label_colour,
      label_y = y_limits[2],
      show_bounds = TRUE
    )
  }

  p <- p +
    geom_timeline_axis(
      data = axis_df,
      mapping = ggplot2::aes(xmin = xmin, xmax = xmax, y = y),
      inherit.aes = FALSE,
      size = style_params$axis_size,
      colour = style_params$axis_color,
      fill = axis_fill,
      shape = axis_shape,
      height = axis_height,
      tip_frac = axis_tip,
      arrow = axis_arrow,
      start_cap = start_cap
    )

  # Year-change ticks drawn on top of the arrow fill, inset from the outline.
  year_line_every <- .parse_year_line_every(year_lines, year_breaks)
  if (!is.null(year_line_every)) {
    line_xs <- compute_year_lines(
      from = axis_df$xmin,
      to = axis_df$xmax,
      every = year_line_every
    )
    if (length(line_xs) > 0L) {
      if (!is.null(year_line_width)) {
        year_line_size <- year_line_width
      }
      if (is.null(year_line_colour)) {
        year_line_colour <- "#9A9A9A"
      }
      if (is.null(year_line_size) || !is.finite(year_line_size)) {
        year_line_size <- 0.35
      }
      if (is.null(year_line_alpha) || !is.finite(year_line_alpha)) {
        year_line_alpha <- 0.85
      }
      year_line_alpha <- max(0, min(1, year_line_alpha))
      if (identical(axis_shape, "bar")) {
        # Pull ends in from the top/bottom strokes so ticks sit inside the fill.
        inset <- max(axis_height * 0.14, 0.045)
        inset <- min(inset, axis_height * 0.4)
        line_ymin <- axis_y - axis_height + inset
        line_ymax <- axis_y + axis_height - inset
      } else {
        line_ymin <- axis_y - 0.06
        line_ymax <- axis_y + 0.06
      }
      tip_cut <- .date_to_numeric(axis_df$xmax) -
        max((.date_to_numeric(axis_df$xmax) - .date_to_numeric(axis_df$xmin)) *
              axis_tip, 18)
      line_xs <- line_xs[.date_to_numeric(line_xs) <= tip_cut]
      if (length(line_xs) > 0L && line_ymax > line_ymin) {
        year_line_df <- data.frame(
          x = line_xs,
          xend = line_xs,
          y = line_ymin,
          yend = line_ymax
        )
        p <- p + ggplot2::geom_segment(
          data = year_line_df,
          mapping = ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
          inherit.aes = FALSE,
          colour = year_line_colour,
          linewidth = year_line_size,
          linetype = year_line_linetype,
          alpha = year_line_alpha
        )
      }
    }
  }

  if (!is.null(year_df) && nrow(year_df) > 0L) {
    year_colour_default <- style_params$year_colour_default %||%
      style_params$axis_color
    if ("colour" %in% names(year_df)) {
      year_df$.timeline_year_colour <- year_df$colour
      year_df$colour <- NULL
    }
    p <- p + geom_timeline_year(
      data = year_df,
      mapping = ggplot2::aes(
        x = x,
        y = y,
        label = label,
        .timeline_year_side = .timeline_year_side
      ),
      inherit.aes = FALSE,
      size = year_size,
      offset = year_offset,
      colour = year_colour_default
    )
  }

  p <- p + geom_timeline_connector(
    data = plot_df,
    mapping = ggplot2::aes(
      x = .data[[cols$date]],
      y = y,
      .timeline_label_x = .timeline_label_x,
      .timeline_label_y = .timeline_label_y
    ),
    inherit.aes = FALSE,
    elbowed = elbowed,
    linetype = style_params$connector_linetype,
    colour = connector_colour,
    size = connector_size,
    stat = "identity"
  )

  has_shape <- !is.null(cols$shape) && cols$shape %in% names(plot_df)
  # Draw markers after the bar/connectors so they sit on the ribbon edge.
  if (show_points) {
    point_colour <- style_params$axis_color %||% "grey35"
    point_fill <- style_params$point_fill
    if (is.null(point_fill) || is.na(point_fill)) {
      point_fill <- "white"
    }
    point_stroke <- style_params$point_stroke
    if (is.null(point_stroke) || is.na(point_stroke) || point_stroke <= 0) {
      point_stroke <- 1.1
    }
    if (has_shape) {
      # Avoid fixed `shape=` so the mapped aesthetic is honoured.
      p <- p + ggplot2::geom_point(
        data = plot_df,
        mapping = ggplot2::aes(
          x = .data[[cols$date]],
          y = y,
          shape = .data[[cols$shape]]
        ),
        inherit.aes = FALSE,
        size = 3.0,
        colour = point_colour,
        fill = point_fill,
        stroke = point_stroke
      )
    } else {
      point_shape <- style_params$point_shape
      if (is.null(point_shape) || is.na(point_shape)) {
        point_shape <- 21
      }
      p <- p + geom_timeline_point(
        mapping = ggplot2::aes(
          x = .data[[cols$date]],
          y = y
        ),
        stat = "identity",
        shape = point_shape,
        fill = point_fill,
        stroke = point_stroke,
        size = 3.0,
        colour = point_colour,
        show.legend = FALSE
      )
    }
  }

  if (isTRUE(style_params$endpoint)) {
    p <- p + geom_timeline_endpoint(
      mapping = ggplot2::aes(
        x = .timeline_label_x,
        .timeline_label_y = .timeline_label_y
      ),
      inherit.aes = FALSE,
      fill = style_params$point_fill,
      colour = style_params$axis_color,
      stat = "identity",
      size = 4.6,
      stroke = 1.25
    )
  }

  if (isTRUE(style_params$label_box)) {
    # Center boxed labels on the connector tip so they are not left-offset.
    # key_glyph = polygon avoids geom_label's default "a" legend glyphs.
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

    if (has_shape && !show_points) {
      # Legend-only markers when shapes are mapped but stems stay clean.
      p <- p + ggplot2::geom_point(
        data = plot_df,
        mapping = ggplot2::aes(
          x = .data[[cols$date]],
          y = y,
          shape = .data[[cols$shape]]
        ),
        inherit.aes = FALSE,
        size = 3.2,
        colour = "grey35",
        fill = "white",
        alpha = 0,
        stroke = 1.1
      ) +
        ggplot2::guides(
          shape = ggplot2::guide_legend(override.aes = list(alpha = 1, size = 3.2))
        )
    }
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

  # Leave clear space past the tip so the arrowhead is not panel-clipped.
  # On the left, allow room for label overhang and the left edge of year glyphs.
  panel_margin_left <- max(
    event_span * 0.008,
    10,
    x_min - label_left + 6
  )
  if (!is.null(year_df) && nrow(year_df) > 0L) {
    year_x_left <- min(.date_to_numeric(year_df$x), na.rm = TRUE)
    year_half_panel <- .estimate_year_label_half_days(
      year_df$label, year_size, date_span = max(x_max - x_min, 1)
    )
    panel_margin_left <- max(
      panel_margin_left,
      (x_min - (year_x_left - year_half_panel - 8))
    )
  }
  panel_margin_left <- max(panel_margin_left, 8)
  panel_margin_right <- max(event_span * 0.045, 85)
  x_limits <- c(
    as.Date(x_min - panel_margin_left, origin = "1970-01-01"),
    as.Date(x_max + panel_margin_right, origin = "1970-01-01")
  )
  x_scale <- if (is.null(year_breaks)) {
    ggplot2::scale_x_date(
      breaks = date_breaks,
      date_labels = date_labels,
      limits = x_limits,
      expand = ggplot2::expansion(mult = 0, add = 0)
    )
  } else {
    ggplot2::scale_x_date(
      breaks = NULL,
      labels = NULL,
      limits = x_limits,
      expand = ggplot2::expansion(mult = 0, add = 0)
    )
  }

  p +
    x_scale +
    ggplot2::scale_y_continuous(
      limits = y_limits,
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
