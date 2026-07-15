#' Import timeline rows from OpenAlex
#'
#' Resolves DOIs or OpenAlex work IDs into a [ggtimeline()]-ready data frame
#' via the [OpenAlex Works API](https://docs.openalex.org/api-entities/works).
#' Requires the **httr2** (preferred) or **httr** package, plus **jsonlite**.
#'
#' @param ids Character vector of DOIs (e.g. `"10.1000/xyz"`,
#'   `"https://doi.org/10.1000/xyz"`) or OpenAlex work IDs
#'   (e.g. `"W2741809807"`).
#' @param mailto Optional contact email added to requests for OpenAlex's
#'   "polite pool" (higher rate limits). Defaults to
#'   `getOption("ggtimeline.mailto")`.
#' @param quiet If `FALSE` (default), warn about IDs that failed to resolve.
#' @param ... Reserved for forward compatibility.
#' @return A data frame with columns `date` (publication date), `topic`
#'   (truncated title), `citations` (cited-by count), `status`
#'   (`"peer-reviewed"` or `"preprint"`), `openalex_id`, and `doi`.
#' @export
#' @examples
#' \dontrun{
#' from_openalex(c("10.1038/s41586-020-2649-2", "W2741809807"))
#' }
from_openalex <- function(ids, mailto = getOption("ggtimeline.mailto"),
                          quiet = FALSE, ...) {
  ids <- as.character(ids)
  ids <- ids[!is.na(ids) & nzchar(ids)]
  if (length(ids) == 0L) {
    rlang::abort("`ids` must contain at least one non-empty DOI or OpenAlex ID.")
  }
  .require_json_client("from_openalex()")

  norm_id <- function(id) {
    id <- sub("^https?://doi\\.org/", "", id, ignore.case = TRUE)
    id <- sub("^https?://openalex\\.org/", "", id, ignore.case = TRUE)
    if (grepl("^10\\.", id)) {
      paste0("https://api.openalex.org/works/doi:", id)
    } else if (grepl("^W[0-9]+$", id, ignore.case = TRUE)) {
      paste0("https://api.openalex.org/works/", id)
    } else {
      paste0("https://api.openalex.org/works/doi:", id)
    }
  }

  rows <- vector("list", length(ids))
  for (i in seq_along(ids)) {
    url <- norm_id(ids[i])
    if (!is.null(mailto) && nzchar(mailto)) {
      url <- paste0(url, if (grepl("\\?", url)) "&" else "?", "mailto=", utils::URLencode(mailto))
    }
    resp <- .http_get_json(url)
    if (is.null(resp)) {
      if (!isTRUE(quiet)) {
        rlang::warn(sprintf("Could not resolve OpenAlex record for '%s'.", ids[i]))
      }
      next
    }
    title <- resp$display_name %||% resp$title %||% NA_character_
    pub_date <- resp$publication_date %||% NA_character_
    cited_by <- resp$cited_by_count %||% NA_integer_
    work_type <- tolower(as.character(resp$type %||% ""))
    is_preprint <- grepl("preprint", work_type) ||
      isTRUE(resp$primary_location$source$type == "repository")
    rows[[i]] <- data.frame(
      date = suppressWarnings(as.Date(pub_date)),
      topic = .truncate_title(title),
      citations = as.numeric(cited_by),
      status = if (is_preprint) "preprint" else "peer-reviewed",
      openalex_id = resp$id %||% NA_character_,
      doi = resp$doi %||% NA_character_,
      stringsAsFactors = FALSE
    )
  }
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    rlang::abort("None of the supplied `ids` could be resolved via OpenAlex.")
  }
  do.call(rbind, rows)
}

#' Import timeline rows from PubMed
#'
#' Resolves PubMed IDs (PMIDs) into a [ggtimeline()]-ready data frame via
#' the NCBI E-utilities `esummary` endpoint. Requires the **httr2**
#' (preferred) or **httr** package, plus **jsonlite**.
#'
#' @param ids Character or numeric vector of PMIDs.
#' @param api_key Optional NCBI API key (raises rate limits). Defaults to
#'   `getOption("ggtimeline.ncbi_key")`.
#' @param quiet If `FALSE` (default), warn about IDs that failed to resolve.
#' @param ... Reserved for forward compatibility.
#' @return A data frame with columns `date`, `topic` (title), `pmid`, and
#'   `citations` (when available from the summary payload; `NA` otherwise).
#' @export
#' @examples
#' \dontrun{
#' from_pubmed(c("32015508", "31978945"))
#' }
from_pubmed <- function(ids, api_key = getOption("ggtimeline.ncbi_key"),
                        quiet = FALSE, ...) {
  ids <- as.character(ids)
  ids <- ids[!is.na(ids) & nzchar(ids)]
  if (length(ids) == 0L) {
    rlang::abort("`ids` must contain at least one non-empty PMID.")
  }
  .require_json_client("from_pubmed()")

  url <- sprintf(
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=%s&retmode=json",
    paste(ids, collapse = ",")
  )
  if (!is.null(api_key) && nzchar(api_key)) {
    url <- paste0(url, "&api_key=", utils::URLencode(api_key))
  }
  resp <- .http_get_json(url)
  if (is.null(resp) || is.null(resp$result)) {
    rlang::abort("Could not retrieve PubMed records for the supplied `ids`.")
  }

  uids <- resp$result$uids
  if (is.null(uids) || length(unlist(uids)) == 0L) {
    rlang::abort("None of the supplied `ids` could be resolved via PubMed.")
  }
  uids <- unlist(uids)

  rows <- vector("list", length(uids))
  for (i in seq_along(uids)) {
    rec <- resp$result[[uids[i]]]
    if (is.null(rec)) {
      if (!isTRUE(quiet)) {
        rlang::warn(sprintf("Could not resolve PubMed record for PMID '%s'.", uids[i]))
      }
      next
    }
    pub_date <- .parse_pubmed_date(rec$pubdate %||% rec$sortpubdate %||% NA_character_)
    rows[[i]] <- data.frame(
      date = pub_date,
      topic = .truncate_title(rec$title %||% NA_character_),
      pmid = uids[i],
      citations = NA_real_,
      stringsAsFactors = FALSE
    )
  }
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    rlang::abort("None of the supplied `ids` could be resolved via PubMed.")
  }
  do.call(rbind, rows)
}

# --- Shared helpers -----------------------------------------------------

.require_json_client <- function(feature) {
  has_client <- requireNamespace("httr2", quietly = TRUE) ||
    requireNamespace("httr", quietly = TRUE)
  if (!has_client || !requireNamespace("jsonlite", quietly = TRUE)) {
    rlang::abort(
      c(
        sprintf("`%s` requires additional packages that are not installed.", feature),
        i = "Install one of {httr2} or {httr}, plus {jsonlite}: install.packages(c(\"httr2\", \"jsonlite\"))"
      ),
      class = "ggtimeline_missing_dependency"
    )
  }
}

# GET a URL and parse JSON; returns NULL (with a warning upstream) on failure.
.http_get_json <- function(url) {
  if (requireNamespace("httr2", quietly = TRUE)) {
    resp <- tryCatch({
      req <- httr2::request(url)
      httr2::req_perform(req)
    }, error = function(e) NULL)
    if (is.null(resp)) {
      return(NULL)
    }
    status <- httr2::resp_status(resp)
    if (status >= 400) {
      return(NULL)
    }
    body <- httr2::resp_body_string(resp)
    return(tryCatch(jsonlite::fromJSON(body, simplifyVector = TRUE), error = function(e) NULL))
  }
  if (requireNamespace("httr", quietly = TRUE)) {
    resp <- tryCatch(httr::GET(url), error = function(e) NULL)
    if (is.null(resp) || httr::http_error(resp)) {
      return(NULL)
    }
    body <- httr::content(resp, as = "text", encoding = "UTF-8")
    return(tryCatch(jsonlite::fromJSON(body, simplifyVector = TRUE), error = function(e) NULL))
  }
  NULL
}

.truncate_title <- function(title, max_chars = 70) {
  title <- as.character(title)
  ifelse(
    is.na(title), NA_character_,
    ifelse(
      nchar(title) > max_chars,
      paste0(substr(title, 1, max_chars - 1), "\u2026"),
      title
    )
  )
}

.parse_pubmed_date <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(x)) {
    return(as.Date(NA))
  }
  # PubMed dates are often "2020 Jan 15", "2020 Jan", or "2020/01/15".
  parsed <- suppressWarnings(as.Date(x, format = "%Y %b %d"))
  if (is.na(parsed)) {
    parsed <- suppressWarnings(as.Date(paste(x, "01"), format = "%Y %b %d"))
  }
  if (is.na(parsed)) {
    parsed <- suppressWarnings(as.Date(x, format = "%Y/%m/%d"))
  }
  if (is.na(parsed)) {
    year <- regmatches(x, regexpr("[0-9]{4}", x))
    if (length(year) && nzchar(year)) {
      parsed <- suppressWarnings(as.Date(paste0(year, "-01-01")))
    }
  }
  parsed
}
