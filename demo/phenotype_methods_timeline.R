# Phenotype mapping methods publication timeline
#
# Demo data derived from the comparison table in phenotype-mapping-methods.md:
# https://github.com/brooksbenard/scIMPEL/blob/main/docs/phenotype-mapping-methods.md

cat("Loading phenotype_methods_timeline demo data...\n")

library(ggplot2)
library(ggtimeline)
data("phenotype_methods_timeline")

## Classic timeline coloured by method category
p <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, colour = category, fill = category),
  style = "classic",
  side = "auto",
  date_breaks = "2 years",
  date_labels = "%Y"
) +
  scale_timeline_colour() +
  scale_timeline_fill() +
  labs(
    title = "Phenotype-to-cell mapping methods (2020\u20132026)",
    caption = "Data from phenotype-mapping-methods.md"
  )

print(p)

## Ribbon style with publication status as shape
p2 <- ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category, shape = status),
  style = "ribbon",
  side = "alternate"
) +
  scale_timeline_fill() +
  scale_timeline_shape()

print(p2)

cat("Demo complete.\n")
