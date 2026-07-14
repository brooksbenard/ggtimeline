# Generates the README demo figure from phenotype_methods_timeline.
#
#   Rscript data-raw/build-demo-figures.R

suppressPackageStartupMessages({
  library(ggplot2)
  pkgload::load_all(".")
  data("phenotype_methods_timeline", package = "ggtimeline")
})

fig_dir <- "man/figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

eras <- data.frame(
  start = as.Date(c("2020-07-01", "2023-01-01", "2025-01-01")),
  end = as.Date(c("2022-12-31", "2024-12-31", "2026-12-31")),
  label = c("Emergence", "Expansion", "Acceleration"),
  fill = c("#4C72B0", "#55A868", "#C44E52"),
  alpha = c(0.14, 0.14, 0.18),
  stringsAsFactors = FALSE
)

p <- ggtimeline(
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

out <- file.path(fig_dir, "demo-phenotype-methods.png")
ggsave(out, p, width = 14, height = 10, dpi = 120, bg = "white")

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

message("Wrote demo figure to ", out)
