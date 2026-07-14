# Phenotype mapping methods publication timeline
#
# Demo using the bundled phenotype_methods_timeline dataset, derived from
# the method comparison table in phenotype-mapping-methods.md:
# https://github.com/brooksbenard/scIMPEL/blob/main/docs/phenotype-mapping-methods.md
#
# Run interactively:
#   demo(phenotype_methods_timeline, package = "ggtimeline")
#
# Or as a script:
#   Rscript inst/examples/phenotype-methods-timeline-demo.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggtimeline)
})

data("phenotype_methods_timeline", package = "ggtimeline")

eras <- data.frame(
  start = as.Date(c("2020-07-01", "2023-01-01", "2025-01-01")),
  end = as.Date(c("2022-12-31", "2024-12-31", "2026-12-31")),
  label = c("Emergence", "Expansion", "Acceleration"),
  fill = c("#4C72B0", "#55A868", "#C44E52"),
  alpha = c(0.14, 0.14, 0.18),
  stringsAsFactors = FALSE
)

p_ribbon <- ggtimeline(
  phenotype_methods_timeline,
  aes(
    x = date,
    label = topic,
    fill = category,
    shape = status
  ),
  side = "auto",
  year_breaks = "1 year",
  year_side = "inside",
  eras = eras,
  era_alpha = 0.14,
  show_points = TRUE,
  base_height = 1.35,
  height_step = 1.0,
  label_size = 4.2
) +
  scale_timeline_fill(name = "Method category") +
  scale_timeline_shape(name = "Publication status") +
  labs(
    title = "Method publication timeline by category",
    subtitle = "Ribbon timeline with era backgrounds and vertically stacked labels"
  )

print(p_ribbon)

invisible(p_ribbon)
