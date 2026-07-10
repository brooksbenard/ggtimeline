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

# year breaks helper
years <- compute_year_breaks(
  from = as.Date("2020-01-01"),
  to = as.Date("2026-12-01"),
  breaks = "2 years"
)
expect_true(nrow(years) >= 3L)
expect_true(all(c("x", "label", ".timeline_year_side") %in% names(years)))

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
