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

# 1) Classic timeline — all methods coloured by category --------------------

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
  base_height = 1,
  height_step = 0.65,
  date_breaks = "2 years",
  date_labels = "%Y"
) +
  scale_timeline_colour(name = "Method category") +
  scale_timeline_fill(name = "Method category") +
  labs(
    title = "Publication timeline of phenotype mapping methods",
    subtitle = "Classic style with elbowed connectors and automatic label placement",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-classic.png"),
  p_classic,
  width = 14,
  height = 9,
  dpi = 120,
  bg = "white"
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
  date_breaks = "2 years",
  date_labels = "%Y"
) +
  scale_timeline_fill(name = "Method category") +
  scale_timeline_shape(name = "Publication status") +
  labs(
    title = "Method publication timeline by category",
    subtitle = "Ribbon style; filled circles = peer-reviewed, triangles = preprint",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-ribbon.png"),
  p_ribbon,
  width = 14,
  height = 9,
  dpi = 120,
  bg = "white"
)

# 3) Minimal style — high-citation methods only ------------------------------

high_impact <- subset(phenotype_methods_timeline, citations >= 10)

p_minimal <- ggtimeline(
  high_impact,
  aes(x = date, label = topic, colour = category),
  style = "minimal",
  side = "auto",
  date_breaks = "2 years",
  date_labels = "%Y"
) +
  scale_timeline_colour(name = "Method category") +
  labs(
    title = "High-impact phenotype mapping methods (\u2265 10 citations)",
    subtitle = "Minimal style with dotted connectors",
    caption = caption_source
  )

ggsave(
  file.path(fig_dir, "demo-phenotype-methods-minimal.png"),
  p_minimal,
  width = 12,
  height = 7,
  dpi = 120,
  bg = "white"
)

message("Wrote 3 demo figures to ", fig_dir, "/")
