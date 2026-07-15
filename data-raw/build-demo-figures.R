# Generates README / pkgdown demo figures.
#
#   Rscript data-raw/build-demo-figures.R

suppressPackageStartupMessages({
  library(ggplot2)
  pkgload::load_all(".")
  data("phenotype_methods_timeline", package = "ggtimeline")
})

fig_dir <- "man/figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

save_demo <- function(plot, name, width = 12, height = 7) {
  out <- file.path(fig_dir, name)
  ggsave(out, plot, width = width, height = height, dpi = 120, bg = "white")
  message("Wrote ", out)
  invisible(out)
}

eras <- data.frame(
  start = as.Date(c("2020-07-01", "2023-01-01", "2025-01-01")),
  end = as.Date(c("2022-12-31", "2024-12-31", "2026-12-31")),
  label = c("Emergence", "Expansion", "Acceleration"),
  fill = c("#4C72B0", "#55A868", "#C44E52"),
  alpha = c(0.14, 0.14, 0.18),
  stringsAsFactors = FALSE
)

trials <- data.frame(
  start = as.Date(c("2021-01-01", "2022-06-01", "2023-01-01", "2023-08-01")),
  end = as.Date(c("2021-09-01", "2023-02-01", "2023-11-01", "2024-04-01")),
  topic = c("Phase I", "Phase II", "Phase III", "Extension"),
  arm = c("A", "A", "B", "B"),
  stringsAsFactors = FALSE
)

# Main phenotype methods ribbon demo -----------------------------------------
p_methods <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category, shape = status),
  side = "auto",
  year_breaks = "1 year",
  year_side = "inside",
  year_lines = 1,
  year_line_colour = "#888888",
  year_line_width = 0.35,
  year_line_alpha = 0.75,
  eras = eras,
  era_alpha = 0.14,
  era_label_size = 4.2,
  connector_colour = "#888888",
  connector_size = 0.5,
  show_points = TRUE,
  base_height = 1.35,
  height_step = 1.0,
  label_size = 4.2,
  min_gap_days = 32,
  expand = 0.08
) +
  scale_timeline_fill(name = "Method category") +
  scale_timeline_shape(name = "Publication status") +
  labs(
    title = "Method publication timeline by category",
    subtitle = "Era bands, in-arrow years, and publication-status markers"
  )
save_demo(p_methods, "demo-phenotype-methods.png", width = 14, height = 10)

# Interval / range events ----------------------------------------------------
p_intervals <- ggtimeline(
  trials,
  aes(x = start, xend = end, label = topic, fill = arm),
  year_breaks = "1 year",
  span_height = 0.12,
  span_alpha = 0.85,
  base_height = 1.2,
  height_step = 0.9,
  label_size = 3.8
) +
  scale_fill_manual(values = c(A = "#4C72B0", B = "#DD8452"), name = "Arm") +
  labs(title = "Interval events (x + xend)")
save_demo(p_intervals, "demo-intervals.png", width = 11, height = 5.5)

# Annotations + styling ------------------------------------------------------
annot_df <- phenotype_methods_timeline[
  phenotype_methods_timeline$date >= as.Date("2021-01-01") &
    phenotype_methods_timeline$date <= as.Date("2024-12-31"),
  ,
  drop = FALSE
]
p_annotate <- ggtimeline(
  annot_df,
  aes(x = date, label = topic, fill = category),
  year_breaks = "1 year",
  year_side = "inside",
  label_wrap = 18,
  label_box = "shadow",
  connector_type = "curved",
  axis_tip_style = "circle",
  axis_gradient = TRUE,
  base_height = 1.2,
  height_step = 0.95,
  label_size = 3.6
) +
  add_milestone(as.Date("2023-01-01"), label = "Key event") +
  add_span(
    as.Date("2021-06-01"), as.Date("2022-06-01"),
    label = "Early methods", side = "below"
  ) +
  scale_timeline_fill(palette = "okabe", name = "Category") +
  theme_timeline("nature") +
  labs(title = "Annotations, curved connectors, and nature theme")
save_demo(p_annotate, "demo-annotations.png", width = 12, height = 7)

# Swimlanes ------------------------------------------------------------------
p_swim <- ggtimeline_swimlane(
  phenotype_methods_timeline,
  aes(x = date, label = topic, group = category, fill = category),
  lane_spacing = 3.2,
  year_breaks = "1 year",
  year_side = "inside",
  label_size = 2.8,
  base_height = 0.85,
  height_step = 0.7
) +
  scale_timeline_fill(name = "Category") +
  labs(title = "Swimlane timeline by method category")
save_demo(p_swim, "demo-swimlane.png", width = 12, height = 9)

# Gantt ----------------------------------------------------------------------
p_gantt <- ggtimeline_gantt(
  trials,
  aes(x = start, xend = end, label = topic, fill = arm)
) +
  scale_fill_manual(values = c(A = "#4C72B0", B = "#DD8452"), name = "Arm") +
  labs(title = "Gantt-style project timeline")
save_demo(p_gantt, "demo-gantt.png", width = 10, height = 4.5)

# Faceted timeline -----------------------------------------------------------
p_facet <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category),
  year_breaks = "1 year",
  year_side = "inside",
  show_points = FALSE,
  base_height = 0.9,
  height_step = 0.7,
  label_size = 2.6
) +
  facet_timeline(~category) +
  scale_timeline_fill(name = "Category") +
  labs(title = "Faceted timeline by category")
save_demo(p_facet, "demo-facet.png", width = 11, height = 10)

# Remove legacy figure names if present.
legacy <- file.path(
  fig_dir,
  c(
    "demo-phenotype-methods-ribbon.png",
    "demo-phenotype-methods-classic.png",
    "demo-phenotype-methods-minimal.png"
  )
)
unlink(legacy[file.exists(legacy)])

message("All demo figures written to ", normalizePath(fig_dir))
