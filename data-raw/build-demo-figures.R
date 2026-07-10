# Generates demo figures for README.md from phenotype_methods_timeline.
#
#   Rscript data-raw/build-demo-figures.R

suppressPackageStartupMessages({
  library(ggplot2)
  pkgload::load_all(".")
  data("phenotype_methods_timeline", package = "ggtimeline")
})

fig_dir <- "man/figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

caption_source <- paste(
  "Data: phenotype_methods_timeline (derived from phenotype-mapping-methods.md).",
  "OpenAlex citations retrieved 9 Jul 2026."
)

p_classic <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, colour = category, fill = category),
  style = "classic",
  side = "auto",
  year_breaks = "2 years",
  base_height = 1.2,
  height_step = 0.8,
  label_size = 2.8,
  min_gap_days = 24,
  label_method = "mark"
) +
  scale_timeline_colour(name = "Method category") +
  scale_timeline_fill(name = "Method category") +
  labs(
    title = "Publication timeline of phenotype mapping methods",
    subtitle = "Anno_mark-style label spreading with elbowed connectors",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-classic.png"),
  p_classic, width = 16, height = 10, dpi = 120, bg = "white"
)

p_ribbon <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category, shape = status),
  style = "ribbon",
  side = "auto",
  year_breaks = "2 years",
  base_height = 1.15,
  height_step = 0.85,
  label_size = 2.6,
  min_gap_days = 28,
  label_method = "mark"
) +
  scale_timeline_fill(name = "Method category") +
  scale_timeline_shape(name = "Publication status") +
  labs(
    title = "Method publication timeline by category",
    subtitle = "Ribbon style with collision-aware label placement",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-ribbon.png"),
  p_ribbon, width = 16, height = 10, dpi = 120, bg = "white"
)

high_impact <- subset(phenotype_methods_timeline, citations >= 10)

p_minimal <- ggtimeline(
  high_impact,
  aes(x = date, label = topic, colour = category),
  style = "minimal",
  side = "auto",
  year_breaks = "auto",
  base_height = 1,
  height_step = 0.7,
  label_size = 3.2
) +
  scale_timeline_colour(name = "Method category") +
  labs(
    title = "High-impact phenotype mapping methods (\u2265 10 citations)",
    subtitle = "Minimal style with auto year breaks",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-minimal.png"),
  p_minimal, width = 12, height = 7, dpi = 120, bg = "white"
)

message("Wrote 3 demo figures to ", fig_dir, "/")
