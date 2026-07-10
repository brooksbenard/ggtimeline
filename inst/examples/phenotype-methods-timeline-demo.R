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

# ---------------------------------------------------------------------------
# 1. Classic publication timeline (all methods, coloured by category)
# ---------------------------------------------------------------------------

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
    title = "Phenotype-to-cell mapping methods (2020\u20132026)",
    subtitle = paste(
      "Publication dates from the phenotype-mapping-methods reference guide;",
      "colours group methods by primary data modality"
    ),
    caption = paste0(
      "Data: phenotype_methods_timeline (n = ", nrow(phenotype_methods_timeline), " methods). ",
      "Source: github.com/brooksbenard/scIMPEL/docs/phenotype-mapping-methods.md"
    )
  )

print(p_classic)

# ---------------------------------------------------------------------------
# 2. Ribbon style with publication status encoded by point shape
# ---------------------------------------------------------------------------

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
    subtitle = "Ribbon style with alternate above/below label placement",
    caption = "Filled circles = peer-reviewed; triangles = preprint"
  )

print(p_ribbon)

# ---------------------------------------------------------------------------
# 3. Minimal style highlighting high-impact methods (citations >= 10)
# ---------------------------------------------------------------------------

high_impact <- subset(phenotype_methods_timeline, citations >= 10)

p_minimal <- ggtimeline(
  high_impact,
  aes(
    x = date,
    label = topic,
    colour = category
  ),
  style = "minimal",
  side = "auto",
  elbowed = TRUE,
  date_breaks = "2 years",
  date_labels = "%Y"
) +
  scale_timeline_colour(name = "Method category") +
  labs(
    title = "High-impact phenotype mapping methods",
    subtitle = "Methods with \u2265 10 OpenAlex citations (retrieved 9 Jul 2026)",
    caption = "Minimal style with dotted connectors"
  )

print(p_minimal)

invisible(list(
  classic = p_classic,
  ribbon = p_ribbon,
  minimal = p_minimal
))
