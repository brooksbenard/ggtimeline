#' Phenotype mapping methods publication timeline
#'
#' Demo dataset derived from the method comparison table in the
#' phenotype-mapping-methods reference guide. Each row is a published
#' computational method linking sample-level phenotypes to single-cell
#' and/or spatial transcriptomics.
#'
#' @format A data frame with 40 rows and 5 columns:
#' \describe{
#'   \item{date}{Publication date (`Date`; `YYYY-MM-01` from the source table).}
#'   \item{topic}{Method name used as the timeline label.}
#'   \item{category}{Method category for colour grouping:
#'     bulk+sc, sc cohort, spatial+bulk, meta-framework, or other.}
#'   \item{status}{Publication status: peer-reviewed or preprint.}
#'   \item{citations}{OpenAlex citation count (retrieved 9 Jul 2026).}
#' }
#' @source Derived from the comparison table in
#'   \url{https://github.com/brooksbenard/scIMPEL/blob/main/docs/phenotype-mapping-methods.md}
#' @examples
#' data("phenotype_methods_timeline")
#' head(phenotype_methods_timeline)
"phenotype_methods_timeline"
