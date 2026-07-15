# ggtimeline roadmap

Feature surface implemented in the package API. Historical planning notes are
kept below for context; all Priority 1–4 items are now implemented (see
`NEWS`/commit history for details). Remaining "planned" rows describe
optional future polish, not scaffolded stubs.

## Priority 1 — highest leverage

| Feature | Surface | Status |
|---------|---------|--------|
| Interval / range events (`x` + `xend`) | `ggtimeline()`, `geom_timeline_span()` | **done** |
| Milestone markers | `add_milestone()` | **done** |
| Labeled date-range brackets | `add_span()` | **done** |
| Label wrap | `ggtimeline(..., label_wrap =)` | **done** |
| Size / citation bubbles | `scale_timeline_size()` | **done** |
| Input validation | `ggtimeline_data()` | **done** |

## Priority 2 — layout & dense timelines

| Feature | Surface | Status |
|---------|---------|--------|
| Swimlane / stacked parallel arrows | `ggtimeline_swimlane()`, `facet_timeline()` | **done** |
| Clustered callouts | `ggtimeline(..., cluster_radius =)` | **done** |
| Gantt mode | `ggtimeline_gantt()` | **done** |
| Connector styles | `connector_type = c("straight","curved","elbow","none")` | **done** |
| Label box styles | `label_box`, `label_box_*` | **done** |

## Priority 3 — aesthetics & publication polish

| Feature | Surface | Status |
|---------|---------|--------|
| Arrow tip styles | `axis_tip_style` | **done** |
| Era label position / border / angle | `era_label_position`, `era_border`, `era_label_angle` | **done** |
| Gradient arrow fill | `axis_gradient` | **done** (requires R >= 4.1; falls back to a solid fill otherwise) |
| Theme presets | `theme_timeline()` | **done** |
| Fill palette presets | `scale_timeline_fill(palette = )` | **done** (`"okabe"`, `"nature"`, `"nejm"`, `"default"`, or a custom vector) |

## Priority 4 — data & docs

| Feature | Surface | Status |
|---------|---------|--------|
| OpenAlex import | `from_openalex()` | **done** (soft dep: httr2/httr + jsonlite) |
| PubMed import | `from_pubmed()` | **done** (soft dep: httr2/httr + jsonlite) |
| pkgdown gallery | `_pkgdown.yml` + articles | scaffold |
| patchwork multi-panel checks | vignette / tests | planned |

## Known limitations / follow-ups

- `ggtimeline_swimlane()` uses a fixed `lane_spacing` per lane; very dense
  categories (many overlapping events within one lane) can still produce
  label overlap within that lane. Increase `lane_spacing`, `base_height`, or
  `height_step`, or pre-filter/aggregate dense lanes.
- `axis_gradient = TRUE` requires R >= 4.1 (`grid::linearGradient()`); on
  older R it falls back to a solid fill with a one-time warning.
- `from_openalex()` / `from_pubmed()` require network access and one of
  **httr2**/**httr** plus **jsonlite** (all Suggests, not hard dependencies).
- `label_box_fill` (a fixed colour) disables the per-category fill legend
  for that label layer, since it replaces the mapped `fill` aesthetic.

## Notes

- High-level entry points (`ggtimeline()`, `ggtimeline_swimlane()`,
  `ggtimeline_gantt()`) are thin composers over shared geoms in
  `R/geom-*.R` and layout helpers in `R/layout-labels.R`.
- Layers are ggplot2-native so patchwork / cowplot composition stays easy.
- Soft-depend on **ggrepel**, **httr2** / **httr** / **jsonlite** (imports),
  and **stringr** (label wrapping) — none are hard dependencies for the base
  ribbon plot.
