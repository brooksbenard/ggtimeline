# ggtimeline

Publication-ready timeline charts for [ggplot2](https://ggplot2.tidyverse.org/).

Build a thick arrow axis with boxed event labels, optional era bands, in-arrow
year labels and ticks, and automatic above/below stacking when labels collide.

## Installation

```r
# install.packages("remotes")
remotes::install_github("brooksbenard/ggtimeline")
```

## Quick start

The bundled `phenotype_methods_timeline` dataset has 41 methods from the
[phenotype-mapping-methods](https://github.com/brooksbenard/scIMPEL/blob/main/docs/phenotype-mapping-methods.md)
guide (publication dates, categories, and OpenAlex citations).

```r
library(ggplot2)
library(ggtimeline)

data("phenotype_methods_timeline")

eras <- data.frame(
  start = as.Date(c("2020-07-01", "2023-01-01", "2025-01-01")),
  end   = as.Date(c("2022-12-31", "2024-12-31", "2026-12-31")),
  label = c("Emergence", "Expansion", "Acceleration"),
  fill  = c("#4C72B0", "#55A868", "#C44E52")
)

ggtimeline(
  phenotype_methods_timeline,
  aes(x = date, label = topic, fill = category, shape = status),
  year_breaks = "1 year",
  year_side = "inside",
  year_lines = 1,
  eras = eras,
  show_points = TRUE,
  base_height = 1.35,
  height_step = 1.0,
  label_size = 4.2
) +
  scale_timeline_fill(name = "Method category") +
  scale_timeline_shape(name = "Publication status")
```

<img src="man/figures/demo-phenotype-methods.png" alt="Phenotype mapping methods timeline" width="100%" />

Interactive demo:

```r
demo(phenotype_methods_timeline)
```

## Input data

| Column | Role |
|--------|------|
| `date` | Event date (horizontal position) |
| `topic` | Label text (`aes(label = …)`) |
| Aesthetic columns | `colour`, `fill`, `shape`, `size`, … |
| Grouping | Optional `aes(group = …)` for shared styling |

## Useful options

| Argument | Purpose |
|----------|---------|
| `eras` | Background era bands (`start`/`end`, optional `label`/`fill`/`alpha`) |
| `year_breaks` | In-arrow year labels (`"1 year"`, `"auto"`, or explicit years) |
| `year_lines` | In-arrow dashed year-boundary ticks (`TRUE`, `1`, `"2 years"`, …) |
| `show_points` | Publication-status (or other) markers on the arrow edges |
| `axis_width` / `axis_tip` | Arrow thickness and tip depth |
| `connector_colour` / `connector_size` | Stem colour and width |
| `side`, `base_height`, `height_step` | Label placement and stacking |

Year tick styling: `year_line_colour`, `year_line_width`, `year_line_alpha`.

Plots are standard `ggplot` objects—add `labs()`, scales, and themes as usual.

```r
ggtimeline(..., year_breaks = "1 year", eras = eras) +
  scale_timeline_fill() +
  labs(title = "Phenotype mapping methods (2020\u20132026)")
```

## License

MIT © Brooks Benard
