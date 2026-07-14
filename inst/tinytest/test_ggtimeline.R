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
