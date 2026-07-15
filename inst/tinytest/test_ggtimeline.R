library(tinytest)
library(ggtimeline)
library(ggplot2)

data("phenotype_methods_timeline", package = "ggtimeline")

# dataset
expect_equal(nrow(phenotype_methods_timeline), 41L)
expect_true(all(c("date", "topic", "category", "status", "citations") %in%
                  names(phenotype_methods_timeline)))

# ggtimeline returns ggplot (ribbon visualisation)
expect_inherits(
  ggtimeline(
    phenotype_methods_timeline,
    aes(x = date, label = topic, fill = category),
    side = "auto"
  ),
  "ggplot"
)

expect_inherits(
  ggtimeline(
    phenotype_methods_timeline,
    aes(x = date, label = topic, fill = category),
    style = "ribbon",
    side = "alternate"
  ),
  "ggplot"
)

expect_error(
  ggtimeline(
    head(phenotype_methods_timeline, 8),
    aes(x = date, label = topic, fill = category),
    style = "classic"
  ),
  "ribbon"
)

# stat layer composes
expect_inherits(
  ggplot(
    head(phenotype_methods_timeline, 5),
    aes(x = date, label = topic)
  ) +
    stat_timeline(side = "auto") +
    geom_timeline_connector(stat = "timeline"),
  "ggplot"
)

# scales
expect_inherits(scale_timeline_colour(), "ScaleDiscrete")
expect_inherits(scale_timeline_fill(), "ScaleDiscrete")
expect_inherits(scale_timeline_shape(), "ScaleDiscrete")

# side options
expect_inherits(
  ggtimeline(
    head(phenotype_methods_timeline, 6),
    aes(x = date, label = topic),
    side = "above",
    elbowed = FALSE
  ),
  "ggplot"
)

# layout and overlap avoidance
expect_true(nrow(compute_year_breaks(
  from = as.Date("2020-01-01"),
  to = as.Date("2026-12-01"),
  breaks = "2 years"
)) >= 3L)

# dense cluster layout produces distinct x positions via public API
p_dense <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category),
  style = "ribbon",
  label_method = "mark",
  base_height = 1.2,
  height_step = 0.8,
  min_gap_days = 24
)
expect_inherits(p_dense, "ggplot")
built <- ggplot2::ggplot_build(p_dense)
plot_layer <- built$data[[which(vapply(built$data, function(d) {
  ".timeline_label_x" %in% names(d)
}, logical(1)))[1]]]
expect_true(".timeline_label_x" %in% names(plot_layer))

# mark-style layout boxes do not overlap within a side
cfg <- list(
  axis_y = 0,
  base_height = 1.2,
  height_step = 0.8,
  label_width_days = 100,
  min_gap_days = 24,
  elbow_fraction = 0.35,
  label_size = 2.8,
  plot_span = diff(range(as.numeric(phenotype_methods_timeline$date))) * 1.24
)
dates <- as.numeric(phenotype_methods_timeline$date)
labs <- as.character(phenotype_methods_timeline$topic)
sides <- ggtimeline:::.compute_sides(dates, "auto", labs, cfg)
resolved <- ggtimeline:::.resolve_side_conflicts(
  dates, labs, sides, cfg, label_size = 2.8, boxed = FALSE
)
widths <- ggtimeline:::.estimate_label_width_days(
  labs, cfg, 2.8, date_span = diff(range(dates))
)
height <- ggtimeline:::.estimate_label_height(cfg, 2.8, FALSE)
pad_x <- cfg$min_gap_days * 0.65
pad_y <- cfg$height_step * 0.1
boxes_overlap <- FALSE
for (side_name in c("above", "below")) {
  idx <- which(sides == side_name)
  sign <- if (side_name == "above") 1 else -1
  for (a in seq_along(idx)) {
    i <- idx[a]
    for (b in seq_along(idx)) {
      if (b <= a) next
      j <- idx[b]
      xi <- resolved$label_x[i]
      xj <- resolved$label_x[j]
      yi <- resolved$label_y[i]
      yj <- resolved$label_y[j]
      if (sign > 0) {
        o <- !(xi + widths[i] + pad_x < xj || xj + widths[j] + pad_x < xi ||
                 yi + height + pad_y < yj || yj + height + pad_y < yi)
      } else {
        o <- !(xi + widths[i] + pad_x < xj || xj + widths[j] + pad_x < xi ||
                 yi - height - pad_y > yj || yj - height - pad_y > yi)
      }
      if (o) boxes_overlap <- TRUE
    }
  }
}
expect_false(boxes_overlap)
expect_true(max(resolved$tiers) >= 3L)

# width vector aligns with original row order after date sorting
idx_above <- which(sides == "above")
widths_idx <- ggtimeline:::.estimate_label_width_days(labs[idx_above], cfg, 2.8)
ord <- idx_above[order(dates[idx_above])]
expect_equal(
  widths_idx[match(ord, idx_above)],
  ggtimeline:::.estimate_label_width_days(labs[ord], cfg, 2.8)
)

# year annotations on plot
expect_inherits(
  ggtimeline(
    phenotype_methods_timeline,
    aes(x = date, label = topic, fill = category),
    style = "ribbon",
    year_breaks = "2 years",
    year_side = "inside",
    axis_arrow = TRUE,
    base_height = 1.2,
    height_step = 0.65
  ),
  "ggplot"
)

# eras + thick bar arrow axis + vertical stacking
eras <- data.frame(
  start = as.Date(c("2020-01-01", "2024-01-01")),
  end = as.Date(c("2023-12-31", "2026-12-31")),
  label = c("Early", "Late"),
  fill = c("#4C72B0", "#C44E52")
)
expect_inherits(
  ggtimeline(
    head(phenotype_methods_timeline, 12),
    aes(x = date, label = topic, fill = category),
    style = "ribbon",
    year_breaks = "2 years",
    eras = eras,
    axis_shape = "bar",
    elbowed = FALSE,
    label_method = "simple"
  ),
  "ggplot"
)

# simple stacking keeps labels at the event date (vertical connectors)
layout_simple <- ggtimeline:::.build_layout(
  data = head(phenotype_methods_timeline, 10),
  date_col = "date",
  topic_col = "topic",
  side = "auto",
  config = list(
    axis_y = 0,
    base_height = 1.2,
    height_step = 0.8,
    label_width_days = 100,
    min_gap_days = 24,
    plot_span = 2000,
    label_size = 2.8
  ),
  label_size = 2.8,
  label_method = "simple"
)
expect_equal(
  as.numeric(layout_simple$.timeline_label_x),
  as.numeric(head(phenotype_methods_timeline$date, 10))
)
expect_true(max(layout_simple$.timeline_tier) >= 1L)
expect_true(all(
  compute_year_breaks(
    from = as.Date("2020-01-01"),
    to = as.Date("2026-12-01"),
    breaks = "2 years",
    side = "inside"
  )$.timeline_year_side == "inside"
))

# ribbon axis clears labels + tip past the last event (not clipped)
last_date <- max(phenotype_methods_timeline$date, na.rm = TRUE)
p_axis <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category),
  style = "ribbon",
  year_breaks = "2 years",
  expand = 0.08,
  axis_width = 0.65,
  axis_tip = 0.012
)
axis_layer <- Filter(
  function(l) inherits(l$geom, "GeomTimelineAxis"),
  p_axis$layers
)[[1]]
axis_xmax <- max(axis_layer$data$xmax)
expect_true(axis_xmax > last_date + 30)
expect_true(axis_xmax <= last_date + 400)
expect_equal(axis_layer$geom_params$height, 0.65)
expect_equal(axis_layer$geom_params$tip_frac, 0.012)
# Tip depth grows with arrow height.
tip_thin <- ggtimeline:::.timeline_tip_length(0.3, 0.015, 2000)
tip_thick <- ggtimeline:::.timeline_tip_length(0.9, 0.015, 2000)
expect_true(tip_thick > tip_thin * 2)
p_col <- ggtimeline(
  head(phenotype_methods_timeline, 6),
  aes(x = date, label = topic),
  year_breaks = "1 year",
  year_side = "inside",
  axis_fill = "#FFF4E0",
  axis_colour = "#8B4513",
  year_colour = "#1B4F72"
)
axis_col_layer <- Filter(
  function(l) inherits(l$geom, "GeomTimelineAxis"),
  p_col$layers
)[[1]]
expect_equal(axis_col_layer$aes_params$fill %||% axis_col_layer$geom_params$fill, "#FFF4E0")
expect_equal(axis_col_layer$aes_params$colour %||% axis_col_layer$geom_params$colour, "#8B4513")
year_col_layer <- Filter(
  function(l) inherits(l$geom, "GeomTimelineYear"),
  p_col$layers
)[[1]]
expect_true(all(year_col_layer$data$colour == "#1B4F72" |
  year_col_layer$data$.timeline_year_colour == "#1B4F72"))
first_date <- min(phenotype_methods_timeline$date, na.rm = TRUE)
axis_xmin <- min(axis_layer$data$xmin)
expect_true(as.numeric(first_date - axis_xmin) <= 140)
# Year glyphs must clear the left bar edge (first event is mid-2020).
year_layer <- Filter(
  function(l) inherits(l$geom, "GeomTimelineYear"),
  p_axis$layers
)[[1]]
year_left <- min(year_layer$data$x)
expect_true(as.numeric(year_left - axis_xmin) >= 25)

# year-boundary dashed guides
ylines <- compute_year_lines(
  from = as.Date("2020-05-01"),
  to = as.Date("2026-08-01"),
  every = 2L
)
expect_true(all(format(ylines, "%m-%d") == "01-01"))
expect_true(all(diff(as.numeric(format(ylines, "%Y"))) == 2))

p_lines <- ggtimeline(
  head(phenotype_methods_timeline, 10),
  aes(x = date, label = topic, fill = category),
  style = "ribbon",
  year_breaks = "2 years",
  year_lines = 1,
  axis_height = 0.5,
  year_line_width = 0.5,
  year_line_colour = "#555555",
  year_line_alpha = 0.6
)
seg <- Filter(function(l) {
  inherits(l$geom, "GeomSegment") &&
    nrow(l$data) > 0L &&
    all(l$data$x == l$data$xend)
}, p_lines$layers)[[1]]
expect_true(!is.null(seg))
# Inset from the bar outline (± axis_height), not flush with it.
expect_true(min(seg$data$y) > -0.5)
expect_true(max(seg$data$yend) < 0.5)
expect_equal(seg$aes_params$linewidth %||% seg$aes_params$size, 0.5)
expect_equal(seg$aes_params$alpha, 0.6)

# show_points opt-in for ribbon shape markers
p_pts <- ggtimeline(
  head(phenotype_methods_timeline, 8),
  aes(x = date, label = topic, fill = category, shape = status),
  style = "ribbon",
  show_points = TRUE
)
expect_true(any(vapply(p_pts$layers, function(l) {
  inherits(l$geom, "GeomPoint") && isTRUE(l$aes_params$alpha %||% 1 != 0)
}, logical(1))) || any(vapply(p_pts$layers, function(l) {
  "shape" %in% names(l$mapping)
}, logical(1))))

# palette
expect_true(length(timeline_palette()) >= 5L)
expect_equal(length(timeline_palette(3)), 3L)

# data validator
expect_identical(
  ggtimeline_data(phenotype_methods_timeline, date = "date", label = "topic"),
  phenotype_methods_timeline
)
expect_error(
  ggtimeline_data(phenotype_methods_timeline, date = "missing_col"),
  "not found"
)

# size scale helper
expect_inherits(scale_timeline_size(), "ScaleContinuous")

# annotations: add_milestone() / add_span() build via ggplot_add.timeline_annotation
milestone <- add_milestone(as.Date("2024-01-01"), label = "Key event")
expect_inherits(milestone, "timeline_annotation")
p_milestone <- ggtimeline(
  head(phenotype_methods_timeline, 8),
  aes(x = date, label = topic, fill = category)
) + milestone
expect_inherits(p_milestone, "ggplot")
expect_inherits(ggplot2::ggplot_build(p_milestone), "ggplot_built")

span_annot <- add_span(as.Date("2024-01-01"), as.Date("2025-01-01"), label = "Range")
expect_inherits(span_annot, "timeline_annotation")
p_span <- ggtimeline(
  head(phenotype_methods_timeline, 8),
  aes(x = date, label = topic, fill = category)
) + span_annot
expect_inherits(p_span, "ggplot")
expect_inherits(ggplot2::ggplot_build(p_span), "ggplot_built")

# theme_timeline() returns a usable ggplot2 theme
expect_inherits(theme_timeline("minimal"), "theme")
expect_inherits(theme_timeline("nature"), "theme")
expect_inherits(theme_timeline("dark"), "theme")
expect_inherits(
  ggtimeline(head(phenotype_methods_timeline, 5), aes(x = date, label = topic)) +
    theme_timeline("nature"),
  "ggplot"
)

# scale_timeline_fill() named presets
expect_inherits(scale_timeline_fill(palette = "okabe"), "ScaleDiscrete")
expect_inherits(scale_timeline_fill(palette = "nature"), "ScaleDiscrete")
expect_inherits(scale_timeline_colour(palette = "nejm"), "ScaleDiscrete")

# label_wrap builds and actually wraps long labels
p_wrap <- ggtimeline(
  head(phenotype_methods_timeline, 5),
  aes(x = date, label = topic),
  label_wrap = 4
)
expect_inherits(p_wrap, "ggplot")
expect_inherits(ggplot2::ggplot_build(p_wrap), "ggplot_built")
wrapped_labels <- ggtimeline:::.wrap_labels(c("A really long label here"), width = 6)
expect_true(grepl("\n", wrapped_labels))

# cluster_radius snaps nearby label positions to a shared centre
p_cluster <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category),
  cluster_radius = 200
)
expect_inherits(p_cluster, "ggplot")
expect_inherits(ggplot2::ggplot_build(p_cluster), "ggplot_built")

# connector_type: straight / elbow / curved / none all build
for (ct in c("straight", "elbow", "curved", "none")) {
  p_ct <- ggtimeline(
    head(phenotype_methods_timeline, 6),
    aes(x = date, label = topic),
    connector_type = ct
  )
  expect_inherits(p_ct, "ggplot")
  expect_inherits(ggplot2::ggplot_build(p_ct), "ggplot_built")
}
# "none" omits the connector layer entirely
p_none <- ggtimeline(
  head(phenotype_methods_timeline, 6),
  aes(x = date, label = topic),
  connector_type = "none"
)
expect_false(any(vapply(p_none$layers, function(l) {
  inherits(l$geom, "GeomTimelineConnector")
}, logical(1))))

# label_box: TRUE / FALSE / "shadow" all build; shadow adds an extra geom_label layer
p_box_true <- ggtimeline(head(phenotype_methods_timeline, 5), aes(x = date, label = topic), label_box = TRUE)
p_box_false <- ggtimeline(head(phenotype_methods_timeline, 5), aes(x = date, label = topic), label_box = FALSE)
p_box_shadow <- ggtimeline(head(phenotype_methods_timeline, 5), aes(x = date, label = topic), label_box = "shadow")
expect_inherits(p_box_true, "ggplot")
expect_inherits(p_box_false, "ggplot")
expect_inherits(p_box_shadow, "ggplot")
n_labels_plain <- sum(vapply(p_box_true$layers, function(l) inherits(l$geom, "GeomLabel"), logical(1)))
n_labels_shadow <- sum(vapply(p_box_shadow$layers, function(l) inherits(l$geom, "GeomLabel"), logical(1)))
expect_true(n_labels_shadow > n_labels_plain)

# label_box_fill/colour/alpha/radius honoured without erroring
p_box_style <- ggtimeline(
  head(phenotype_methods_timeline, 5),
  aes(x = date, label = topic),
  label_box_fill = "steelblue",
  label_box_colour = "black",
  label_box_alpha = 0.6,
  label_box_radius = 8
)
expect_inherits(ggplot2::ggplot_build(p_box_style), "ggplot_built")

# axis_tip_style + axis_gradient
for (ts in c("arrow", "flat", "none", "circle")) {
  p_tip <- ggtimeline(
    head(phenotype_methods_timeline, 5),
    aes(x = date, label = topic),
    axis_tip_style = ts,
    axis_gradient = TRUE
  )
  expect_inherits(p_tip, "ggplot")
  expect_inherits(ggplot2::ggplot_build(p_tip), "ggplot_built")
}

# era_label_position / era_border / era_label_angle
eras_extra <- data.frame(
  start = as.Date("2020-01-01"),
  end = as.Date("2026-12-31"),
  label = "Full span"
)
for (pos in c("top", "bottom", "center")) {
  p_era <- ggtimeline(
    head(phenotype_methods_timeline, 5),
    aes(x = date, label = topic),
    eras = eras_extra,
    era_label_position = pos,
    era_border = FALSE,
    era_label_angle = 10
  )
  expect_inherits(p_era, "ggplot")
  expect_inherits(ggplot2::ggplot_build(p_era), "ggplot_built")
}

# ggtimeline_swimlane(): smoke test with a tiny grouped dataset
swim_data <- data.frame(
  date = as.Date(c("2020-01-01", "2020-06-01", "2021-01-01", "2021-06-01")),
  topic = c("A1", "A2", "B1", "B2"),
  grp = c("Alpha", "Alpha", "Beta", "Beta"),
  stringsAsFactors = FALSE
)
p_swim <- ggtimeline_swimlane(
  swim_data,
  aes(x = date, label = topic, group = grp, fill = grp)
)
expect_inherits(p_swim, "ggplot")
expect_inherits(ggplot2::ggplot_build(p_swim), "ggplot_built")
expect_error(
  ggtimeline_swimlane(swim_data, aes(x = date, label = topic)),
  "grouping column"
)

# facet_timeline(): returns a facet_wrap-compatible Facet object
facet_obj <- facet_timeline(~category)
expect_inherits(facet_obj, "Facet")
p_facet <- ggtimeline(
  head(phenotype_methods_timeline, 10),
  aes(x = date, label = topic, fill = category)
) + facet_obj
expect_inherits(p_facet, "ggplot")

# ggtimeline_gantt(): smoke test with tiny interval + point data
gantt_data <- data.frame(
  start = as.Date(c("2021-01-01", "2022-01-01", "2022-06-01")),
  end = as.Date(c("2021-08-01", "2022-01-01", "2023-01-01")),
  topic = c("Phase I", "Kickoff", "Phase II"),
  arm = c("A", "A", "B"),
  stringsAsFactors = FALSE
)
p_gantt <- ggtimeline_gantt(
  gantt_data,
  aes(x = start, xend = end, label = topic, fill = arm)
)
expect_inherits(p_gantt, "ggplot")
built_gantt <- ggplot2::ggplot_build(p_gantt)
expect_inherits(built_gantt, "ggplot_built")
gantt_fill <- built_gantt$data[[1]]$fill
expect_true(length(unique(gantt_fill)) == 2L)

# from_openalex() / from_pubmed(): error clearly on empty ids
expect_error(from_openalex(character(0)), "ids")
expect_error(from_pubmed(character(0)), "ids")
if (requireNamespace("httr2", quietly = TRUE) || requireNamespace("httr", quietly = TRUE)) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    net_ok <- tryCatch({
      Sys.setenv(TZ = Sys.getenv("TZ", unset = "UTC"))
      res <- from_openalex("10.1038/s41586-020-2649-2")
      is.data.frame(res) && nrow(res) == 1L
    }, error = function(e) NA)
    if (!is.na(net_ok)) {
      expect_true(net_ok)
    }
  }
}

# interval / range events (x + xend)
intervals <- data.frame(
  start = as.Date(c("2021-01-01", "2022-03-01", "2023-01-01")),
  end = as.Date(c("2021-08-01", "2022-03-01", "2023-11-01")),
  topic = c("Phase I", "Milestone", "Phase II"),
  category = c("A", "B", "A"),
  stringsAsFactors = FALSE
)
expect_identical(
  ggtimeline_data(intervals, start = "start", end = "end", label = "topic"),
  intervals
)
p_int <- ggtimeline(
  intervals,
  aes(x = start, xend = end, label = topic, fill = category),
  style = "ribbon",
  year_breaks = "1 year",
  span_height = 0.1
)
expect_inherits(p_int, "ggplot")
expect_true(any(vapply(p_int$layers, function(l) {
  inherits(l$geom, "GeomTimelineSpan")
}, logical(1))))

# layout midpoint for a proper interval
layout_int <- ggtimeline:::.build_layout(
  data = intervals[1, , drop = FALSE],
  date_col = "start",
  topic_col = "topic",
  side = "above",
  config = list(
    axis_y = 0, base_height = 1.2, height_step = 0.8,
    label_width_days = 100, min_gap_days = 24, plot_span = 800
  ),
  label_size = 3,
  label_method = "simple",
  date_end_col = "end"
)
expect_true(isTRUE(layout_int$.timeline_is_interval[1]))
expect_equal(
  as.numeric(layout_int$.timeline_anchor_x[1]),
  mean(as.numeric(c(intervals$start[1], intervals$end[1])))
)
# zero-length xend collapses to a point event (no span layer needed)
p_pt <- ggtimeline(
  intervals[2, , drop = FALSE],
  aes(x = start, xend = end, label = topic),
  style = "ribbon"
)
expect_false(any(vapply(p_pt$layers, function(l) {
  inherits(l$geom, "GeomTimelineSpan")
}, logical(1))))
