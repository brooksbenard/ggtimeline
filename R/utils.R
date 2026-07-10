# Internal helpers for timeline layout and drawing.

.timeline_defaults <- function() {
  list(
    axis_y = 0,
    base_height = 1,
    height_step = 0.6,
    label_width_days = 90,
    min_gap_days = 14,
    elbow_fraction = 0.35,
    point_size = 3.2,
    endpoint_size = 4.8,
    label_hjust = 0,
    label_size = 3.2,
    year_offset = 0.32,
    connector_colour = "#A8A8A8"
  )
}

#' Default timeline colour palette
#'
#' A refined, publication-ready palette for timeline categories and events.
#'
#' @param n Number of colours to return. If greater than the number of named
#'   colours, additional colours are interpolated.
#' @return A named or unnamed character vector of hex colours.
#' @export
timeline_palette <- function(n = NULL) {
  base <- c(
    "#4C72B0", "#DD8452", "#55A868", "#C44E52", "#8172B3",
    "#937860", "#DA8BC3", "#8C8C8C", "#CCB974", "#64B5CD"
  )
  named <- c(
    "bulk+sc" = "#4C72B0",
    "sc cohort" = "#55A868",
    "spatial+bulk" = "#C44E52",
    "meta-framework" = "#8172B3",
    "other" = "#DD8452",
    "peer-reviewed" = "#4C72B0",
    "preprint" = "#DD8452"
  )
  if (is.null(n)) {
    return(named)
  }
  if (n <= length(base)) {
    return(base[seq_len(n)])
  }
  grDevices::colorRampPalette(base)(n)
}

#' Compute year break positions for timeline annotation
#'
#' Generates a data frame of year labels suitable for [geom_timeline_year()].
#'
#' @param from,start Start date (Date, POSIXct, or numeric). `start` is an alias.
#' @param to,end End date. `end` is an alias.
#' @param breaks Year interval specification:
#'   \itemize{
#'     \item `"auto"` picks a sensible interval from the date span.
#'     \item A character string like `"1 year"`, `"2 years"`, `"5 years"`.
#'     \item A numeric vector of years (converted to mid-year dates).
#'     \item A Date vector of explicit break positions.
#'   }
#' @param labels Character labels; defaults to formatted years.
#' @param side Placement relative to the axis: `"alternate"` (default),
#'   `"above"`, or `"below"`.
#' @param axis_y Y position of the timeline axis.
#' @param colours Optional character vector of colours cycling across years.
#' @return A data frame with columns `x`, `label`, `y`, `.timeline_year_side`,
#'   and optionally `colour`.
#' @export
#' @examples
#' compute_year_breaks(
#'   from = as.Date("2020-01-01"),
#'   to = as.Date("2026-12-01"),
#'   breaks = "2 years"
#' )
compute_year_breaks <- function(from, to,
                                breaks = "auto",
                                labels = NULL,
                                side = c("alternate", "above", "below"),
                                axis_y = 0,
                                colours = NULL,
                                start = NULL,
                                end = NULL) {
  if (!is.null(start)) from <- start
  if (!is.null(end)) to <- end
  side <- match.arg(side)
  start <- .as_date_safe(from)
  end <- .as_date_safe(to)

  if (is.null(start) || is.null(end)) {
    rlang::abort("`from` and `to` must be valid dates.")
  }
  if (start > end) {
    tmp <- start
    start <- end
    end <- tmp
  }

  if (is.character(breaks) && length(breaks) == 1L) {
    if (breaks == "auto") {
      span_years <- as.numeric(difftime(end, start, units = "days")) / 365.25
      step <- if (span_years <= 4) {
        1L
      } else if (span_years <= 12) {
        2L
      } else if (span_years <= 35) {
        5L
      } else {
        10L
      }
      start_year <- as.integer(format(start, "%Y"))
      end_year <- as.integer(format(end, "%Y"))
      years <- seq(start_year, end_year, by = step)
    } else {
      by_match <- regmatches(breaks, regexpr("[0-9]+", breaks))
      step <- if (length(by_match)) as.integer(by_match[1]) else 1L
      start_year <- as.integer(format(start, "%Y"))
      end_year <- as.integer(format(end, "%Y"))
      years <- seq(start_year, end_year, by = step)
    }
    xs <- as.Date(paste0(years, "-07-01"))
  } else if (inherits(breaks, "Date")) {
    xs <- breaks
    years <- as.integer(format(xs, "%Y"))
  } else if (is.numeric(breaks)) {
    years <- as.integer(breaks)
    xs <- as.Date(paste0(years, "-07-01"))
  } else {
    rlang::abort("`breaks` must be 'auto', a date interval string, numeric years, or Date vector.")
  }

  xs <- xs[xs >= start & xs <= end]
  if (length(xs) == 0L) {
    return(data.frame(
      x = as.Date(character()),
      label = character(),
      y = numeric(),
      .timeline_year_side = character(),
      stringsAsFactors = FALSE
    ))
  }

  if (is.null(labels)) {
    labels <- format(xs, "%Y")
  } else if (length(labels) != length(xs)) {
    rlang::abort("`labels` must be the same length as computed breaks.")
  }

  sides <- switch(
    side,
    above = rep("above", length(xs)),
    below = rep("below", length(xs)),
    alternate = rep(c("above", "below"), length.out = length(xs))
  )

  out <- data.frame(
    x = xs,
    label = as.character(labels),
    y = axis_y,
    .timeline_year_side = sides,
    stringsAsFactors = FALSE
  )

  if (!is.null(colours)) {
    out$colour <- rep(colours, length.out = nrow(out))
  }

  out
}

.as_date_safe <- function(x) {
  if (inherits(x, "Date")) {
    return(x)
  }
  if (inherits(x, "POSIXt")) {
    return(as.Date(x))
  }
  if (is.numeric(x) && length(x) == 1L) {
    return(as.Date(x, origin = "1970-01-01"))
  }
  suppressWarnings(as.Date(x))
}

.date_to_numeric <- function(x) {
  if (inherits(x, "Date")) {
    as.numeric(x)
  } else if (inherits(x, "POSIXt")) {
    as.numeric(as.Date(x))
  } else {
    as.numeric(x)
  }
}

.estimate_label_width <- function(labels, width_days, char_width = 6) {
  nchar(labels) * char_width * (width_days / 90)
}

.compute_sides <- function(dates, sides = c("auto", "above", "below", "alternate"),
                           labels = NULL, config = .timeline_defaults()) {
  sides <- match.arg(sides)
  n <- length(dates)
  if (n == 0L) {
    return(character())
  }
  if (sides == "above") {
    return(rep("above", n))
  }
  if (sides == "below") {
    return(rep("below", n))
  }
  if (sides == "alternate") {
    out <- rep(c("above", "below"), length.out = n)
    return(out)
  }

  if (is.null(labels)) {
    labels <- rep("label", n)
  }

  ord <- order(dates)
  side <- rep(NA_character_, n)
  above_end <- -Inf
  below_end <- -Inf
  width <- .estimate_label_width(labels, config$label_width_days)

  for (i in ord) {
    w <- width[i]
    start <- dates[i] - w / 2
    end <- dates[i] + w / 2
    above_overlap <- start <= above_end
    below_overlap <- start <= below_end
    if (!above_overlap && below_overlap) {
      side[i] <- "above"
      above_end <- end
    } else if (above_overlap && !below_overlap) {
      side[i] <- "below"
      below_end <- end
    } else if (!above_overlap && !below_overlap) {
      if (above_end <= below_end) {
        side[i] <- "above"
        above_end <- end
      } else {
        side[i] <- "below"
        below_end <- end
      }
    } else {
      if (above_end <= below_end) {
        side[i] <- "above"
        above_end <- end
      } else {
        side[i] <- "below"
        below_end <- end
      }
    }
  }
  side
}

.compute_label_heights <- function(dates, sides, labels, config) {
  n <- length(dates)
  if (n == 0L) {
    return(numeric())
  }
  width <- .estimate_label_width(labels, config$label_width_days)
  tier <- integer(n)
  ord <- order(dates)

  for (side in c("above", "below")) {
    idx <- ord[sides[ord] == side]
    if (length(idx) == 0L) {
      next
    }
    ends <- rep(-Inf, 0L)
    for (i in idx) {
      start <- dates[i] - width[i] / 2
      end <- dates[i] + width[i] / 2
      placed <- FALSE
      for (t in seq_along(ends)) {
        if (start > ends[t] + config$min_gap_days) {
          tier[i] <- t
          ends[t] <- end
          placed <- TRUE
          break
        }
      }
      if (!placed) {
        tier[i] <- length(ends) + 1L
        ends <- c(ends, end)
      }
    }
  }
  tier
}

.build_layout <- function(data, date_col, topic_col, side, config, group_col = NULL) {
  dates <- .date_to_numeric(data[[date_col]])
  labels <- as.character(data[[topic_col]])
  sides <- .compute_sides(dates, sides = side, labels = labels, config = config)
  tiers <- .compute_label_heights(dates, sides, labels, config)

  sign <- ifelse(sides == "above", 1, -1)
  label_y <- sign * (config$base_height + (tiers - 1L) * config$height_step)
  axis_y <- rep(config$axis_y, length(dates))

  span <- max(diff(range(dates)), 1)
  elbow_x_num <- dates + sign * config$elbow_fraction * config$base_height *
    (config$label_width_days / span)

  if (inherits(data[[date_col]], "Date")) {
    elbow_x <- as.Date(elbow_x_num, origin = "1970-01-01")
  } else {
    elbow_x <- elbow_x_num
  }

  out <- data.frame(
    .timeline_x = dates,
    .timeline_y = axis_y,
    .timeline_label = labels,
    .timeline_side = sides,
    .timeline_tier = tiers,
    .timeline_label_y = label_y,
    .timeline_elbow_x = elbow_x,
    stringsAsFactors = FALSE
  )
  if (!is.null(group_col) && group_col %in% names(data)) {
    out$.timeline_group <- data[[group_col]]
  }
  out
}

.elbow_segments <- function(x, y, label_y, elbow_x, side) {
  n <- length(x)
  x1 <- numeric(0)
  y1 <- numeric(0)
  x2 <- numeric(0)
  y2 <- numeric(0)
  for (i in seq_len(n)) {
    x1 <- c(x1, x[i], elbow_x[i])
    y1 <- c(y1, y[i], label_y[i])
    x2 <- c(x2, x[i], elbow_x[i])
    y2 <- c(y2, label_y[i], label_y[i])
  }
  data.frame(x = x1, y = y1, xend = x2, yend = y2)
}

.timeline_theme <- function(base_size = 11, background = "#F5F4F0") {
  ggplot2::theme_void(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = background, colour = NA),
      panel.background = ggplot2::element_rect(fill = background, colour = NA),
      plot.margin = ggplot2::margin(28, 32, 28, 32),
      plot.title = ggplot2::element_text(
        face = "bold",
        size = rel(1.45),
        colour = "#2A2A2A",
        hjust = 0.5,
        margin = ggplot2::margin(b = 6)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = "#666666",
        size = rel(1.05),
        hjust = 0.5,
        margin = ggplot2::margin(b = 18)
      ),
      plot.caption = ggplot2::element_text(
        colour = "#999999",
        size = rel(0.78),
        hjust = 0.5,
        margin = ggplot2::margin(t = 14)
      ),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold", size = rel(0.92), colour = "#444444"),
      legend.text = ggplot2::element_text(colour = "#555555", size = rel(0.88)),
      legend.key.size = grid::unit(0.45, "cm"),
      legend.spacing.x = grid::unit(0.25, "cm"),
      text = ggplot2::element_text(family = "sans", colour = "#333333")
    )
}

.timeline_style_params <- function(style) {
  style <- match.arg(style, c("classic", "ribbon", "minimal", "milestone"))
  switch(
    style,
    classic = list(
      axis_size = 0.65,
      axis_color = "#3D3D3D",
      point_shape = 21,
      point_fill = "white",
      point_stroke = 1.4,
      connector_linetype = "solid",
      connector_colour = "#B8B8B8",
      label_box = FALSE,
      endpoint = TRUE,
      show_axis_ends = TRUE,
      axis_arrow = TRUE,
      start_cap = TRUE
    ),
    ribbon = list(
      axis_size = 3.5,
      axis_color = "#D8D8D4",
      point_shape = NA,
      point_fill = NA,
      point_stroke = 0,
      connector_linetype = "solid",
      connector_colour = "#C8C8C4",
      label_box = TRUE,
      endpoint = FALSE,
      show_axis_ends = FALSE,
      axis_arrow = TRUE,
      start_cap = FALSE
    ),
    minimal = list(
      axis_size = 0.45,
      axis_color = "#888888",
      point_shape = 16,
      point_fill = NA,
      point_stroke = 0.9,
      connector_linetype = "dotted",
      connector_colour = "#BBBBBB",
      label_box = FALSE,
      endpoint = FALSE,
      show_axis_ends = FALSE,
      axis_arrow = TRUE,
      start_cap = FALSE
    ),
    milestone = list(
      axis_size = 1,
      axis_color = "#4A4A4A",
      point_shape = 21,
      point_fill = "white",
      point_stroke = 1.5,
      connector_linetype = "solid",
      connector_colour = "#AFAFAF",
      label_box = TRUE,
      endpoint = TRUE,
      show_axis_ends = TRUE,
      axis_arrow = TRUE,
      start_cap = TRUE
    )
  )
}

.get_mapping_names <- function(mapping) {
  if (is.null(mapping)) {
    return(list())
  }
  stats::setNames(
    vapply(mapping, rlang::as_name, character(1)),
    names(mapping)
  )
}

.resolve_cols <- function(data, mapping, default_date = "date", default_topic = "topic") {
  if (is.null(mapping)) {
    return(list(
      date = default_date,
      topic = default_topic,
      group = NULL,
      fill = NULL,
      colour = NULL,
      shape = NULL
    ))
  }
  cols <- .get_mapping_names(mapping)
  get_col <- function(name, default = NULL) {
    if (name %in% names(cols)) {
      return(cols[[name]])
    }
    default
  }
  list(
    date = get_col("x", default_date),
    topic = get_col("label", default_topic),
    group = get_col("group"),
    fill = get_col("fill"),
    colour = get_col("colour"),
    shape = get_col("shape")
  )
}
