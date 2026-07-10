# Internal helpers for timeline layout and drawing.

.timeline_defaults <- function() {
  list(
    axis_y = 0,
    base_height = 0.8,
    height_step = 0.55,
    label_width_days = 90,
    min_gap_days = 14,
    elbow_fraction = 0.35,
    point_size = 3,
    endpoint_size = 4.5,
    label_hjust = 0,
    label_size = 3.5
  )
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

.timeline_theme <- function(base_size = 12) {
  ggplot2::theme_void(base_size = base_size) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(20, 20, 20, 20),
      legend.position = "bottom"
    )
}

.timeline_style_params <- function(style) {
  style <- match.arg(style, c("classic", "ribbon", "minimal", "milestone"))
  switch(
    style,
    classic = list(
      axis_size = 0.8,
      axis_color = "grey30",
      point_shape = 21,
      point_fill = NA,
      point_stroke = 1.2,
      connector_linetype = "solid",
      label_box = FALSE,
      endpoint = TRUE,
      show_axis_ends = TRUE
    ),
    ribbon = list(
      axis_size = 4,
      axis_color = "grey75",
      point_shape = NA,
      point_fill = NA,
      point_stroke = 0,
      connector_linetype = "solid",
      label_box = TRUE,
      endpoint = FALSE,
      show_axis_ends = FALSE
    ),
    minimal = list(
      axis_size = 0.4,
      axis_color = "grey50",
      point_shape = 16,
      point_fill = NA,
      point_stroke = 0.8,
      connector_linetype = "dotted",
      label_box = FALSE,
      endpoint = FALSE,
      show_axis_ends = FALSE
    ),
    milestone = list(
      axis_size = 1.2,
      axis_color = "grey40",
      point_shape = 21,
      point_fill = "white",
      point_stroke = 1.5,
      connector_linetype = "solid",
      label_box = TRUE,
      endpoint = TRUE,
      show_axis_ends = TRUE
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
