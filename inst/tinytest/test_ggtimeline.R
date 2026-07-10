library(tinytest)
library(ggtimeline)
library(ggplot2)

data("phenotype_methods_timeline", package = "ggtimeline")

# dataset
expect_equal(nrow(phenotype_methods_timeline), 40L)
expect_true(all(c("date", "topic", "category", "status", "citations") %in%
                  names(phenotype_methods_timeline)))

# ggtimeline returns ggplot for all styles
expect_inherits(
  ggtimeline(
    phenotype_methods_timeline,
    aes(x = date, label = topic, colour = category, fill = category),
    style = "classic"
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

expect_inherits(
  ggtimeline(
    head(phenotype_methods_timeline, 8),
    aes(x = date, label = topic, colour = category),
    style = "minimal"
  ),
  "ggplot"
)

expect_inherits(
  ggtimeline(
    head(phenotype_methods_timeline, 8),
    aes(x = date, label = topic, fill = category),
    style = "milestone"
  ),
  "ggplot"
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
  aes(x = date, label = topic, colour = category),
  style = "classic",
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

# year annotations on plot
expect_inherits(
  ggtimeline(
    phenotype_methods_timeline,
    aes(x = date, label = topic, colour = category),
    style = "classic",
    year_breaks = "2 years",
    axis_arrow = TRUE,
    base_height = 1.2,
    height_step = 0.65
  ),
  "ggplot"
)

# palette
expect_true(length(timeline_palette()) >= 5L)
expect_equal(length(timeline_palette(3)), 3L)
