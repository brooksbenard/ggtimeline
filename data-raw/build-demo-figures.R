# Generates demo figures for README.md from phenotype_methods_timeline.
#
#   Rscript data-raw/build-demo-figures.R
#
# Outputs PNGs into man/figures/.

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

# 1) Classic timeline — year annotations, arrow axis, professional palette ----

p_classic <- ggtimeline(
  phenotype_methods_timeline,
  aes(
    x = date,
    label = topic,
    colour = category,
    fill = category
  ),
  style = "classic",
  side = "auto",
  elbowed = TRUE,
  year_breaks = "2 years",
  year_side = "alternate",
  base_height = 1.1,
  height_step = 0.7,
  label_size = 3,
  expand = 0.06
) +
  scale_timeline_colour(name = "Method category") +
  scale_timeline_fill(name = "Method category") +
  labs(
    title = "Publication timeline of phenotype mapping methods",
    subtitle = "Classic style with year annotations and future-pointing axis arrow",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-classic.png"),
  p_classic,
  width = 14,
  height = 9,
  dpi = 120,
  bg = "#F5F4F0"
)

# 2) Ribbon style — alternate above/below labels -----------------------------

p_ribbon <- ggtimeline(
  phenotype_methods_timeline,
  aes(
    x = date,
    label = topic,
    fill = category,
    shape = status
  ),
  style = "ribbon",
  side = "alternate",
  year_breaks = "2 years",
  base_height = 1,
  height_step = 0.65
) +
  scale_timeline_fill(name = "Method category") +
  scale_timeline_shape(name = "Publication status") +
  labs(
    title = "Method publication timeline by category",
    subtitle = "Ribbon style with alternate above/below label placement",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-ribbon.png"),
  p_ribbon,
  width = 14,
  height = 9,
  dpi = 120,
  bg = "#F5F4F0"
)

# 3) Minimal style — high-citation methods only ------------------------------

high_impact <- subset(phenotype_methods_timeline, citations >= 10)

p_minimal <- ggtimeline(
  high_impact,
  aes(x = date, label = topic, colour = category),
  style = "minimal",
  side = "auto",
  year_breaks = "auto",
  base_height = 0.9,
  height_step = 0.55,
  label_size = 3.4
) +
  scale_timeline_colour(name = "Method category") +
  labs(
    title = "High-impact phenotype mapping methods (\u2265 10 citations)",
    subtitle = "Minimal style with auto year breaks and dotted connectors",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-minimal.png"),
  p_minimal,
  width = 12,
  height = 7,
  dpi = 120,
  bg = "#F5F4F0"
)

message("Wrote 3 demo figures to ", fig_dir, "/")
