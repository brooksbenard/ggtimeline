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

.estimate_label_width_days <- function(labels, config, label_size = 3.2) {
  size_factor <- label_size / 3.2
  char_days <- config$label_width_days / 90 * size_factor
  pmax(nchar(labels) * char_days * 5.5, config$min_gap_days * 1.5)
}

.estimate_label_height <- function(config, label_size = 3.2, boxed = FALSE) {
  base <- config$height_step * 0.82
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

.shift_sequence <- function(width, min_gap, n = 11L) {
  base <- max(width * 0.55, min_gap)
  offsets <- c(0)
  step <- 1L
  while (length(offsets) < n) {
    offsets <- c(offsets, step * base, -step * base)
    step <- step + 1L
  }
  offsets[seq_len(n)]
}

.place_side_labels <- function(dates, labels, idx, side_name, config,
                              label_size, boxed, cluster_ids) {
  n <- length(idx)
  if (n == 0L) {
    return(list())
  }

  sign <- if (side_name == "above") 1 else -1
  widths <- .estimate_label_width_days(labels[idx], config, label_size)
  height <- .estimate_label_height(config, label_size, boxed)
  pad_x <- config$min_gap_days * 0.35
  pad_y <- config$height_step * 0.08

  ord <- idx[order(dates[idx])]
  boxes <- list()
  results <- vector("list", length(ord))

  for (j in seq_along(ord)) {
    i <- ord[j]
    w <- widths[j]
    placed <- FALSE
    tier <- 1L
    max_tier <- 25L

    shifts <- .shift_sequence(w, config$min_gap_days, n = 15L)
    is_cluster <- cluster_ids[i] > 0 && sum(cluster_ids[idx] == cluster_ids[i]) > 1L
    if (is_cluster) {
      shifts <- .shift_sequence(w * 1.1, config$min_gap_days * 1.2, n = 21L)
    }

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
      tx <- dates[i] + shifts[length(shifts)]
      base_y <- sign * (config$base_height + (max_tier - 1L) * config$height_step)
      results[[j]] <- list(
        i = i,
        label_x = tx,
        label_y = base_y,
        tier = max_tier,
        width = w
      )
    }
  }

  results
}

.resolve_side_conflicts <- function(dates, labels, sides, config, label_size, boxed) {
  n <- length(dates)
  cluster_ids <- .detect_clusters(dates, threshold_days = max(config$min_gap_days * 3, 45))

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
      cluster_ids = cluster_ids
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
  if (!requireNamespace("ggrepel", quietly = TRUE)) {
    return(list(x = dates, y = label_y))
  }

  n <- length(dates)
  if (n < 2L) {
    return(list(x = dates, y = label_y))
  }

  span <- max(diff(range(dates)), 1)
  width_frac <- .estimate_label_width_days(labels, config, label_size) / span
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
                          label_method = c("auto", "mark", "repel", "simple")) {
  label_method <- match.arg(label_method)
  dates <- .date_to_numeric(data[[date_col]])
  labels <- as.character(data[[topic_col]])
  sides <- .compute_sides(dates, sides = side, labels = labels, config = config)

  if (label_method == "simple") {
    tiers <- .compute_label_heights(dates, sides, labels, config)
    sign <- ifelse(sides == "above", 1, -1)
    label_y <- sign * (config$base_height + (tiers - 1L) * config$height_step)
    label_x <- dates
  } else {
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

  out <- data.frame(
    .timeline_x = dates,
    .timeline_y = axis_y,
    .timeline_label = labels,
    .timeline_side = sides,
    .timeline_tier = tiers,
    .timeline_label_x = to_x(label_x),
    .timeline_label_y = label_y,
    .timeline_anchor_x = to_x(dates),
    stringsAsFactors = FALSE
  )

  if (!is.null(group_col) && group_col %in% names(data)) {
    out$.timeline_group <- data[[group_col]]
  }
  out
}
