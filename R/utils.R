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

.resolve_timeline_palette <- function(palette = NULL) {
  if (is.null(palette)) {
    return(timeline_palette())
  }
  if (is.character(palette) && length(palette) == 1L &&
        !grepl("^#", palette)) {
    key <- tolower(palette)
    if (identical(key, "default")) {
      return(timeline_palette())
    }
    presets <- .timeline_palette_presets()
    if (key %in% names(presets)) {
      cols <- presets[[key]]
      named <- timeline_palette()
      # Keep familiar category names when counts match.
      if (length(named) <= length(cols)) {
        names(cols)[seq_along(named)] <- names(named)
      }
      return(cols)
    }
  }
  palette
}

.wrap_labels <- function(labels, width = NULL) {
  labels <- as.character(labels)
  if (is.null(width) || !is.finite(width) || width < 1) {
    return(labels)
  }
  width <- as.integer(width)
  if (requireNamespace("stringr", quietly = TRUE)) {
    return(stringr::str_wrap(labels, width = width))
  }
  vapply(labels, function(lab) {
    paste(strwrap(lab, width = width), collapse = "\n")
  }, character(1), USE.NAMES = FALSE)
}

.cluster_event_dates <- function(dates, radius = NULL) {
  n <- length(dates)
  cluster_id <- seq_len(n)
  cluster_x <- dates
  if (is.null(radius) || !is.finite(radius) || radius <= 0 || n <= 1L) {
    return(list(id = cluster_id, x = cluster_x))
  }
  ord <- order(dates)
  sorted <- dates[ord]
  groups <- integer(n)
  groups[1] <- 1L
  g <- 1L
  for (i in seq_len(n)[-1]) {
    if (sorted[i] - sorted[i - 1L] <= radius) {
      groups[i] <- g
    } else {
      g <- g + 1L
      groups[i] <- g
    }
  }
  centers <- tapply(sorted, groups, mean)
  cluster_id[ord] <- groups
  cluster_x[ord] <- as.numeric(centers[as.character(groups)])
  list(id = cluster_id, x = cluster_x)
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
#'   `"above"`, `"below"`, or `"inside"` (centered in a thick bar arrow).
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
                                side = c("alternate", "above", "below", "inside"),
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
    inside = rep("inside", length(xs)),
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

#' Year-boundary positions for dashed timeline guides
#'
#' Returns January 1 dates at a fixed year interval for vertical year-change
#' markers. Used by [ggtimeline()] when `year_lines` is enabled.
#'
#' @param from,to Axis date range.
#' @param every Integer number of years between markers (default `1`).
#' @return A Date vector of year starts strictly inside `(from, to)`.
#' @export
#' @examples
#' compute_year_lines(
#'   from = as.Date("2020-05-01"),
#'   to = as.Date("2026-08-01"),
#'   every = 2
#' )
compute_year_lines <- function(from, to, every = 1L) {
  start <- .as_date_safe(from)
  end <- .as_date_safe(to)
  every <- as.integer(every)[1]
  if (!is.finite(every) || every < 1L) {
    every <- 1L
  }
  if (is.null(start) || is.null(end) || start >= end) {
    return(as.Date(character()))
  }

  start_year <- as.integer(format(start, "%Y"))
  end_year <- as.integer(format(end, "%Y")) + 1L
  # Anchor so markers land on calendar years divisible relative to start_year.
  years <- seq(start_year, end_year, by = every)
  xs <- as.Date(paste0(years, "-01-01"))
  xs[xs > start & xs < end]
}

.parse_year_line_every <- function(year_lines, year_breaks = NULL) {
  if (is.null(year_lines) || isFALSE(year_lines)) {
    return(NULL)
  }
  if (isTRUE(year_lines)) {
    if (is.character(year_breaks) && length(year_breaks) == 1L &&
          grepl("[0-9]+", year_breaks)) {
      return(as.integer(regmatches(year_breaks, regexpr("[0-9]+", year_breaks))[1]))
    }
    return(1L)
  }
  if (is.numeric(year_lines) && length(year_lines) >= 1L) {
    step <- as.integer(year_lines[1])
    if (is.finite(step) && step >= 1L) {
      return(step)
    }
  }
  if (is.character(year_lines) && length(year_lines) == 1L) {
    m <- regmatches(year_lines, regexpr("[0-9]+", year_lines))
    if (length(m) && nzchar(m[1])) {
      return(as.integer(m[1]))
    }
  }
  1L
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

.estimate_label_width <- function(labels, width_days, char_width = 6,
                                  date_span = NULL, label_size = 3.2) {
  # Prefer the shared span-aware estimator used by mark-style placement so
  # side assignment and collision boxes agree on reserved label widths.
  config <- list(label_width_days = width_days, min_gap_days = 14)
  .estimate_label_width_days(
    labels = labels,
    config = config,
    label_size = label_size,
    date_span = date_span
  )
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
  # Tier end-dates per side so we can balance resulting vertical height.
  above_ends <- numeric(0)
  below_ends <- numeric(0)
  date_span <- config$plot_span %||% diff(range(dates, na.rm = TRUE))
  if (!is.finite(date_span) || date_span <= 0) {
    date_span <- NULL
  }
  width <- .estimate_label_width(
    labels,
    config$label_width_days,
    date_span = date_span,
    label_size = config$label_size %||% 3.2
  ) * 0.75
  min_gap <- config$min_gap_days %||% 14
  centered <- isTRUE(config$boxed)

  place_cost <- function(ends, start, end) {
    if (length(ends) == 0L) {
      return(1L)
    }
    for (t in seq_along(ends)) {
      if (start > ends[t] + min_gap) {
        return(as.integer(t))
      }
    }
    as.integer(length(ends) + 1L)
  }

  update_ends <- function(ends, start, end, tier) {
    if (tier > length(ends)) {
      ends <- c(ends, end)
    } else {
      ends[tier] <- end
    }
    ends
  }

  for (i in ord) {
    w <- width[i]
    if (centered) {
      start <- dates[i] - w / 2
      end <- dates[i] + w / 2
    } else {
      start <- dates[i]
      end <- dates[i] + w
    }

    cost_above <- place_cost(above_ends, start, end)
    cost_below <- place_cost(below_ends, start, end)
    height_above <- max(length(above_ends), cost_above)
    height_below <- max(length(below_ends), cost_below)

    # Prefer the side that keeps peak stack height lower; break remaining
    # ties by lower placement tier, then by current occupancy.
    if (height_above < height_below) {
      chosen <- "above"
    } else if (height_below < height_above) {
      chosen <- "below"
    } else if (cost_above < cost_below) {
      chosen <- "above"
    } else if (cost_below < cost_above) {
      chosen <- "below"
    } else if (length(above_ends) <= length(below_ends)) {
      chosen <- "above"
    } else {
      chosen <- "below"
    }

    side[i] <- chosen
    if (chosen == "above") {
      above_ends <- update_ends(above_ends, start, end, cost_above)
    } else {
      below_ends <- update_ends(below_ends, start, end, cost_below)
    }
  }
  side
}

# Flip labels between sides to keep peak stack height balanced above/below.
.balance_side_heights <- function(dates, labels, sides, config,
                                  centered = FALSE, max_iter = 60L) {
  if (length(dates) < 2L) {
    return(sides)
  }

  score <- function(s) {
    tiers <- .compute_label_heights(
      dates, s, labels, config, centered = centered
    )
    h_above <- max(c(0L, tiers[s == "above"]), na.rm = TRUE)
    h_below <- max(c(0L, tiers[s == "below"]), na.rm = TRUE)
    list(
      tiers = tiers,
      h_above = as.integer(h_above),
      h_below = as.integer(h_below),
      imbalance = abs(as.integer(h_above) - as.integer(h_below)),
      peak = max(as.integer(h_above), as.integer(h_below))
    )
  }

  cur <- score(sides)
  if (cur$imbalance <= 1L) {
    return(sides)
  }

  for (iter in seq_len(max_iter)) {
    tall <- if (cur$h_above >= cur$h_below) "above" else "below"
    short <- if (identical(tall, "above")) "below" else "above"
    tall_idx <- which(sides == tall)
    if (length(tall_idx) == 0L) {
      break
    }
    # Try flipping from highest tiers first.
    tall_idx <- tall_idx[order(cur$tiers[tall_idx], decreasing = TRUE)]

    improved <- FALSE
    for (i in tall_idx) {
      trial <- sides
      trial[i] <- short
      nxt <- score(trial)
      better <- nxt$peak < cur$peak ||
        (nxt$peak == cur$peak && nxt$imbalance < cur$imbalance)
      if (better) {
        sides <- trial
        cur <- nxt
        improved <- TRUE
        break
      }
    }
    if (!improved || cur$imbalance <= 1L) {
      break
    }
  }
  sides
}

.compute_label_heights <- function(dates, sides, labels, config,
                                   centered = FALSE) {
  n <- length(dates)
  if (n == 0L) {
    return(numeric())
  }
  date_span <- config$plot_span %||% diff(range(dates, na.rm = TRUE))
  if (!is.finite(date_span) || date_span <= 0) {
    date_span <- NULL
  }
  width <- .estimate_label_width(
    labels,
    config$label_width_days,
    date_span = date_span,
    label_size = config$label_size %||% 3.2
  )
  # Boxed labels are centered on the connector; reserve padding for the box.
  if (isTRUE(centered)) {
    width <- width * 1.2
  }
  tier <- integer(n)
  ord <- order(dates)

  for (side in c("above", "below")) {
    idx <- ord[sides[ord] == side]
    if (length(idx) == 0L) {
      next
    }
    ends <- rep(-Inf, 0L)
    for (i in idx) {
      if (isTRUE(centered)) {
        start <- dates[i] - width[i] / 2
        end <- dates[i] + width[i] / 2
      } else {
        start <- dates[i]
        end <- dates[i] + width[i]
      }
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

.timeline_theme <- function(base_size = 11, background = "white") {
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

.timeline_style_params <- function(style = "ribbon") {
  style <- match.arg(style, "ribbon")
  # Additional styles will be added here as new visualisation types land.
  list(
    axis_size = 1.1,
    axis_color = "#6B6B66",
    axis_fill = "#F4F4F0",
    axis_shape = "bar",
    axis_height = 0.5,
    axis_tip = 0.015,
    point_shape = NA,
    point_fill = NA,
    point_stroke = 0,
    connector_linetype = "solid",
    connector_colour = "#A8A8A4",
    label_box = TRUE,
    endpoint = FALSE,
    show_axis_ends = FALSE,
    axis_arrow = TRUE,
    start_cap = FALSE,
    year_side_default = "inside",
    year_colour_default = "#555555",
    elbowed_default = FALSE,
    label_method_default = "simple"
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
      date_end = NULL,
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
  # Prefer xend; also accept xmax as an alias for interval end.
  date_end <- get_col("xend", NULL) %||% get_col("xmax", NULL)
  list(
    date = get_col("x", default_date) %||% get_col("xmin", default_date),
    date_end = date_end,
    topic = get_col("label", default_topic),
    group = get_col("group"),
    fill = get_col("fill"),
    colour = get_col("colour"),
    shape = get_col("shape")
  )
}
