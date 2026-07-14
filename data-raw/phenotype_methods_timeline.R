# Build phenotype_methods_timeline from the phenotype-mapping-methods
# comparison table (OpenAlex citations retrieved 14 Jul 2026).
#
# Source snapshot: data-raw/phenotype-mapping-methods.md
# (from PhenoMapR/manuscript/docs/phenotype-mapping-methods.*)
#
#   Rscript data-raw/build-data.R

phenotype_methods_timeline <- data.frame(
  date = as.Date(c(
    "2026-06-01", "2026-05-01", "2026-04-01", "2026-04-01", "2026-04-01",
    "2026-03-01", "2026-02-01", "2026-02-01", "2026-01-01", "2026-01-01",
    "2026-01-01", "2026-01-01", "2025-12-01", "2025-12-01", "2025-12-01",
    "2025-11-01", "2025-11-01", "2025-11-01", "2025-11-01", "2025-09-01",
    "2025-08-01", "2025-08-01", "2025-08-01", "2025-06-01", "2025-06-01",
    "2025-04-01", "2025-03-01", "2024-11-01", "2024-08-01", "2024-05-01",
    "2024-05-01", "2024-04-01", "2023-11-01", "2023-07-01", "2023-05-01",
    "2023-03-01", "2022-11-01", "2022-02-01", "2021-11-01", "2020-08-01",
    "2020-07-01"
  )),
  topic = c(
    "SP-printer", "SigBridgeR", "scSurvival", "SpaPheno",
    "DEGAS spatial smoothing", "PaSCient", "BiSCALE", "TiRank",
    "ScPP", "scPhase", "Shears", "stSurvTrans", "SpacePhenotyper",
    "SIDISH", "MultiMIL", "scSurv", "TinydenseR", "scPER", "DEGAS-ST",
    "CellPhenoX", "SCTP", "scBGDL", "ATSDP-NET", "stClinic", "SpaLinker",
    "scTransMIL", "SSDA4Drug", "scPAS", "SCellBOW", "PIPET", "SCIPAC",
    "scRANK", "LP_SGL", "PACSI", "Pencil", "scRank-XMBD", "scAB", "DEGAS",
    "Scissor", "scPrognosis", "Augur"
  ),
  category = c(
    "spatial+bulk", "meta-framework", "sc cohort", "spatial+bulk",
    "spatial+bulk", "sc cohort", "other", "spatial+bulk",
    "bulk+sc", "sc cohort", "bulk+sc", "spatial+bulk", "spatial+bulk",
    "bulk+sc", "sc cohort", "bulk+sc", "sc cohort", "bulk+sc",
    "spatial+bulk", "sc cohort", "spatial+bulk", "bulk+sc", "bulk+sc",
    "spatial+bulk", "spatial+bulk", "sc cohort", "bulk+sc",
    "bulk+sc", "bulk+sc", "bulk+sc", "bulk+sc", "sc cohort",
    "bulk+sc", "bulk+sc", "sc cohort", "bulk+sc", "bulk+sc", "bulk+sc",
    "bulk+sc", "bulk+sc", "sc cohort"
  ),
  status = c(
    "peer-reviewed", "preprint", "peer-reviewed", "peer-reviewed",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "preprint", "peer-reviewed", "preprint", "peer-reviewed", "preprint",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "preprint", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed",
    "peer-reviewed", "peer-reviewed", "peer-reviewed", "peer-reviewed"
  ),
  citations = c(
    0L, 0L, 0L, 0L, 0L, 1L, 0L, 2L, 0L, 2L, 13L, 0L, 0L, 5L, 19L,
    0L, 0L, 2L, 0L, 3L, 2L, 6L, 1L, 15L, 3L, 3L, 13L, 7L, 2L, 6L, 9L,
    3L, 5L, 12L, 13L, 7L, 35L, 49L, 520L, 24L, 40L
  ),
  stringsAsFactors = FALSE
)

phenotype_methods_timeline$category <- factor(
  phenotype_methods_timeline$category,
  levels = c(
    "bulk+sc", "sc cohort", "spatial+bulk", "meta-framework", "other"
  )
)

phenotype_methods_timeline$status <- factor(
  phenotype_methods_timeline$status,
  levels = c("peer-reviewed", "preprint")
)

save(phenotype_methods_timeline,
     file = "data/phenotype_methods_timeline.rda",
     compress = "xz")
