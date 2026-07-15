# Label layout: collision avoidance with anno_mark-style spreading.

.any_overlap <- function(boxes, xmin, xmax, ymin, ymax, pad_x = 0, pad_y = 0) {
  if (length(boxes) == 0L) {
    return(FALSE)
  }
  for (b in boxes) {
    if (!(xmax + pad_x < b[[1]] || xmin - pad_x > b[[2]] ||
            ymax + pad_y < b[[3]] || ymin - pad_y > b[[4]])) {
      return(TRUE)
    }
  }
  FALSE
}

.measure_label_width_inches <- function(labels, label_size = 3.2) {
  labels <- as.character(labels)
  if (!requireNamespace("grid", quietly = TRUE)) {
    return(rep(NA_real_, length(labels)))
  }

  # stringWidth needs an open device; use a null PDF when none is active.
  opened <- FALSE
  if (is.null(grDevices::dev.list())) {
    grDevices::pdf(NULL)
    opened <- TRUE
  }
  on.exit({
    if (opened) {
      grDevices::dev.off()
    }
  }, add = TRUE)

  vapply(labels, function(lab) {
    grob <- grid::textGrob(
      lab,
      gp = grid::gpar(
        fontsize = label_size * ggplot2::.pt,
        fontface = "bold",
        fontfamily = "sans"
      )
    )
    as.numeric(grid::convertWidth(grid::grobWidth(grob), "inches", valueOnly = TRUE))
  }, numeric(1), USE.NAMES = FALSE)
}

.estimate_label_width_days <- function(labels, config, label_size = 3.2,
                                       date_span = NULL) {
  size_factor <- label_size / 3.2
  labels <- as.character(labels)
  # `label_width_days` is the reserved width for a ~12-character label at the
  # default size. Scale by glyph count and font size.
  base_per_char <- (config$label_width_days / 12) * size_factor

  if (!is.null(date_span) && is.finite(date_span) && date_span >= 30) {
    # Convert inches into date units using the plot span.
    # Assumes ~14" usable panel width after margins on landscape figures.
    days_per_inch <- (date_span * 1.25) / 14
    inches <- .measure_label_width_inches(labels, label_size)
    if (all(is.finite(inches))) {
      # Include room for the endpoint marker (~0.14") ahead of left-aligned text,
      # plus padding so bold glyphs clear neighbors.
      lead <- 0.14 * days_per_inch
      return(pmax(lead + inches * days_per_inch * 1.3, config$min_gap_days * 2.5))
    }
    span_per_char <- 0.085 * days_per_inch * size_factor
    char_days <- pmax(base_per_char, span_per_char)
  } else {
    # Fixed-day fallback: inflate so AABB checks match bold GeomText.
    char_days <- base_per_char * 1.5
  }

  pmax(nchar(labels) * char_days * 1.25, config$min_gap_days * 2.5)
}

.estimate_year_label_half_days <- function(labels, year_size = 4.8,
                                           date_span = 2000) {
  labels <- as.character(labels)
  if (length(labels) == 0L) {
    return(35)
  }
  if (!is.finite(date_span) || date_span < 30) {
    date_span <- 2000
  }
  days_per_inch <- (date_span * 1.2) / 14
  inches <- .measure_label_width_inches(labels, year_size)
  if (all(is.finite(inches))) {
    half <- max(inches, na.rm = TRUE) * days_per_inch * 0.55
  } else {
    half <- max(nchar(labels), na.rm = TRUE) * year_size * 0.012 * days_per_inch
  }
  max(half, 30)
}

.estimate_label_height <- function(config, label_size = 3.2, boxed = FALSE) {
  # Keep boxes just under one height_step so vertical stacking at the same x
  # remains valid, while still clearing glyph ascenders/descenders.
  base <- config$height_step * 0.92
  if (isTRUE(boxed)) {
    base <- base * 1.15
  }
  base * (label_size / 3.2)
}

.detect_clusters <- function(dates, threshold_days = 45) {
  if (length(dates) <= 1L) {
    return(seq_along(dates))
  }
  ord <- order(dates)
  cluster <- integer(length(dates))
  cid <- 1L
  cluster[ord[1]] <- cid
  for (i in seq_along(ord)[-1]) {
    prev <- ord[i - 1L]
    curr <- ord[i]
    if (dates[curr] - dates[prev] <= threshold_days) {
      cluster[curr] <- cid
    } else {
      cid <- cid + 1L
      cluster[curr] <- cid
    }
  }
  cluster
}

.shift_sequence <- function(width, min_gap, n = 11L, max_shift = Inf) {
  base <- max(width * 0.4, min_gap)
  offsets <- c(0)
  step <- 1L
  while (length(offsets) < n) {
    cand <- c(step * base, -step * base)
    cand <- cand[abs(cand) <= max_shift + 1e-9]
    if (length(cand) == 0L) {
      break
    }
    offsets <- c(offsets, cand)
    step <- step + 1L
  }
  offsets[seq_len(min(n, length(offsets)))]
}

.place_side_labels <- function(dates, labels, idx, side_name, config,
                              label_size, boxed, cluster_ids,
                              date_span = NULL) {
  n <- length(idx)
  if (n == 0L) {
    return(list())
  }

  sign <- if (side_name == "above") 1 else -1
  # Widths are aligned to `idx` order (unsorted). Index with match(i, idx).
  widths <- .estimate_label_width_days(
    labels[idx], config, label_size, date_span = date_span
  )
  height <- .estimate_label_height(config, label_size, boxed)
  pad_x <- config$min_gap_days * 0.65
  pad_y <- config$height_step * 0.1

  # Keep elbow connectors local: prefer vertical tiers over multi-year shifts.
  span_cap <- if (!is.null(date_span) && is.finite(date_span)) {
    date_span * 0.2
  } else {
    Inf
  }

  ord <- idx[order(dates[idx])]
  boxes <- list()
  results <- vector("list", length(ord))

  for (j in seq_along(ord)) {
    i <- ord[j]
    w <- widths[match(i, idx)]
    placed <- FALSE
    tier <- 1L
    max_tier <- 30L

    cluster_size <- sum(cluster_ids[idx] == cluster_ids[i])
    is_cluster <- cluster_ids[i] > 0 && cluster_size > 1L
    max_shift <- min(max(w * 1.1, config$min_gap_days * 4), span_cap)
    shifts <- .shift_sequence(
      w,
      config$min_gap_days,
      n = if (is_cluster) 15L else 13L,
      max_shift = max_shift
    )

    while (!placed && tier <= max_tier) {
      base_y <- sign * (config$base_height + (tier - 1L) * config$height_step)

      for (shift in shifts) {
        tx <- dates[i] + shift
        xmin <- tx
        xmax <- tx + w
        if (sign > 0) {
          ymin <- base_y
          ymax <- base_y + height
        } else {
          ymin <- base_y - height
          ymax <- base_y
        }

        if (!.any_overlap(boxes, xmin, xmax, ymin, ymax, pad_x, pad_y)) {
          results[[j]] <- list(
            i = i,
            label_x = tx,
            label_y = base_y,
            tier = tier,
            width = w
          )
          boxes[[length(boxes) + 1L]] <- list(xmin, xmax, ymin, ymax)
          placed <- TRUE
          break
        }
      }
      tier <- tier + 1L
    }

    if (!placed) {
      # Fail-open, but still register the box so later labels avoid it.
      tx <- dates[i] + shifts[min(3L, length(shifts))]
      base_y <- sign * (config$base_height + (max_tier - 1L) * config$height_step)
      if (sign > 0) {
        ymin <- base_y
        ymax <- base_y + height
      } else {
        ymin <- base_y - height
        ymax <- base_y
      }
      results[[j]] <- list(
        i = i,
        label_x = tx,
        label_y = base_y,
        tier = max_tier,
        width = w
      )
      boxes[[length(boxes) + 1L]] <- list(tx, tx + w, ymin, ymax)
    }
  }

  results
}

.resolve_side_conflicts <- function(dates, labels, sides, config, label_size, boxed) {
  n <- length(dates)
  date_span <- config$plot_span %||% diff(range(dates, na.rm = TRUE))
  if (!is.finite(date_span) || date_span <= 0) {
    date_span <- NULL
  }
  cluster_ids <- .detect_clusters(
    dates,
    threshold_days = max(config$min_gap_days * 3, 45)
  )

  label_x <- dates
  label_y <- rep(0, n)
  tiers <- rep(1L, n)

  for (side_name in c("above", "below")) {
    idx <- which(sides == side_name)
    if (length(idx) == 0L) {
      next
    }
    placed <- .place_side_labels(
      dates = dates,
      labels = labels,
      idx = idx,
      side_name = side_name,
      config = config,
      label_size = label_size,
      boxed = boxed,
      cluster_ids = cluster_ids,
      date_span = date_span
    )
    for (item in placed) {
      if (is.null(item)) {
        next
      }
      i <- item$i
      label_x[i] <- item$label_x
      label_y[i] <- item$label_y
      tiers[i] <- item$tier
    }
  }

  list(
    label_x = label_x,
    label_y = label_y,
    tiers = tiers,
    cluster_ids = cluster_ids
  )
}

.apply_ggrepel_nudge <- function(dates, label_y, sides, labels, config,
                                label_size, boxed) {
  # Optional soft-repulsion pass. Uses ggrepel only as an installed-package
  # gate; the nudge itself is a lightweight pairwise push in normalized space.
  if (!requireNamespace("ggrepel", quietly = TRUE)) {
    return(list(x = dates, y = label_y))
  }

  n <- length(dates)
  if (n < 2L) {
    return(list(x = dates, y = label_y))
  }

  span <- max(diff(range(dates)), 1)
  width_frac <- .estimate_label_width_days(
    labels, config, label_size, date_span = span
  ) / span
  height_frac <- rep(.estimate_label_height(config, label_size, boxed), n)

  x_norm <- (dates - min(dates)) / span
  y_range <- max(abs(label_y), config$base_height)
  if (y_range <= 0) {
    y_range <- 1
  }
  y_norm <- label_y / y_range

  x_rep <- x_norm
  y_rep <- y_norm

  for (side_name in c("above", "below")) {
    idx <- which(sides == side_name)
    if (length(idx) < 2L) {
      next
    }

    for (iter in seq_len(80L)) {
      moved <- FALSE
      for (a in seq_along(idx)) {
        i <- idx[a]
        for (b in seq_along(idx)) {
          if (a == b) {
            next
          }
          j <- idx[b]
          dx <- x_rep[i] - x_rep[j]
          dy <- y_rep[i] - y_rep[j]
          overlap_x <- (width_frac[i] + width_frac[j]) / 2 - abs(dx)
          overlap_y <- (height_frac[i] + height_frac[j]) / 2 - abs(dy)
          if (overlap_x > 0 && overlap_y > 0) {
            dist <- sqrt(dx^2 + dy^2)
            if (dist < 1e-6) {
              dx <- stats::runif(1, -0.01, 0.01)
              dy <- stats::runif(1, -0.01, 0.01)
              dist <- sqrt(dx^2 + dy^2)
            }
            push <- min(overlap_x, overlap_y) * 0.55
            x_rep[i] <- x_rep[i] + push * dx / dist
            y_rep[i] <- y_rep[i] + push * dy / dist
            moved <- TRUE
          }
        }
      }
      if (!moved) {
        break
      }
    }
  }

  list(
    x = x_norm * span + min(dates) + (x_rep - x_norm) * span,
    y = y_rep * y_range
  )
}

.build_layout <- function(data, date_col, topic_col, side, config, group_col = NULL,
                          label_size = 3.2, boxed = FALSE,
                          label_method = c("auto", "mark", "repel", "simple"),
                          date_end_col = NULL) {
  label_method <- match.arg(label_method)
  date_start <- .date_to_numeric(data[[date_col]])
  date_end <- if (!is.null(date_end_col) && date_end_col %in% names(data)) {
    .date_to_numeric(data[[date_end_col]])
  } else {
    date_start
  }
  # Swap inverted intervals so midpoints / extent stay well-defined.
  swap <- is.finite(date_end) & is.finite(date_start) & date_end < date_start
  if (any(swap)) {
    tmp <- date_start[swap]
    date_start[swap] <- date_end[swap]
    date_end[swap] <- tmp
  }
  # Layout/collision use the interval midpoint (falls back to start for points).
  dates <- (date_start + date_end) / 2
  labels <- as.character(data[[topic_col]])
  config$label_size <- label_size
  config$boxed <- isTRUE(boxed)
  sides <- .compute_sides(dates, sides = side, labels = labels, config = config)

  if (label_method == "simple") {
    # Boxed labels are drawn centered on the connector tip.
    sides <- .balance_side_heights(
      dates = dates,
      labels = labels,
      sides = sides,
      config = config,
      centered = isTRUE(boxed)
    )
    tiers <- .compute_label_heights(
      dates, sides, labels, config, centered = isTRUE(boxed)
    )
    sign <- ifelse(sides == "above", 1, -1)
    label_y <- sign * (config$base_height + (tiers - 1L) * config$height_step)
    label_x <- dates
  } else {
    sides <- .balance_side_heights(
      dates = dates,
      labels = labels,
      sides = sides,
      config = config,
      centered = isTRUE(boxed)
    )
    resolved <- .resolve_side_conflicts(
      dates = dates,
      labels = labels,
      sides = sides,
      config = config,
      label_size = label_size,
      boxed = boxed
    )
    label_x <- resolved$label_x
    label_y <- resolved$label_y
    tiers <- resolved$tiers

    if (label_method == "repel" || max(tiers) >= 4L) {
      nudged <- .apply_ggrepel_nudge(
        dates = label_x,
        label_y = label_y,
        sides = sides,
        labels = labels,
        config = config,
        label_size = label_size,
        boxed = boxed
      )
      label_x <- nudged$x
      label_y <- nudged$y
    }
  }

  axis_y <- rep(config$axis_y, length(dates))
  is_date <- inherits(data[[date_col]], "Date")

  to_x <- function(x_num) {
    if (is_date) {
      as.Date(x_num, origin = "1970-01-01")
    } else {
      x_num
    }
  }

  # Offset text to the right of endpoint markers while keeping connectors on the
  # marker position. Gap is ~0.14" converted via plot span.
  span_for_gap <- config$plot_span %||% max(diff(range(dates, na.rm = TRUE)), 365)
  text_gap <- (span_for_gap * 1.25 / 14) * 0.14
  text_x <- label_x + text_gap

  out <- data.frame(
    .timeline_x = to_x(dates),
    .timeline_x_start = to_x(date_start),
    .timeline_x_end = to_x(date_end),
    .timeline_y = axis_y,
    .timeline_label = labels,
    .timeline_side = sides,
    .timeline_tier = tiers,
    .timeline_label_x = to_x(label_x),
    .timeline_text_x = to_x(text_x),
    .timeline_label_y = label_y,
    .timeline_anchor_x = to_x(dates),
    .timeline_is_interval = abs(date_end - date_start) > 1e-8,
    stringsAsFactors = FALSE
  )

  if (!is.null(group_col) && group_col %in% names(data)) {
    out$.timeline_group <- data[[group_col]]
  }
  out
}
