#' Validate timeline input data
#'
#' Checks that a data frame has the columns needed by [ggtimeline()] and
#' returns it (invisibly) after light validation. Use before plotting to get
#' clearer errors than a cryptic ggplot failure.
#'
#' @param data A data frame of timeline events.
#' @param date Name of the event date column for point events. Ignored when
#'   both `start` and `end` are supplied.
#' @param start,end Optional start/end date columns for interval events
#'   (mapped to `x` / `xend` in [ggtimeline()]).
#' @param label Name of the label column.
#' @param require_label If `TRUE`, require `label` to exist.
#' @return The input `data`, invisibly (after light checks).
#' @export
#' @examples
#' data("phenotype_methods_timeline")
#' ggtimeline_data(phenotype_methods_timeline, date = "date", label = "topic")
#'
#' intervals <- data.frame(
#'   start = as.Date(c("2021-01-01", "2022-01-01")),
#'   end = as.Date(c("2021-06-01", "2022-09-01")),
#'   topic = c("A", "B")
#' )
#' ggtimeline_data(intervals, start = "start", end = "end", label = "topic")
ggtimeline_data <- function(data,
                            date = "date",
                            start = NULL,
                            end = NULL,
                            label = "topic",
                            require_label = TRUE) {
  if (!is.data.frame(data)) {
    rlang::abort("`data` must be a data frame.")
  }
  if (nrow(data) == 0L) {
    rlang::abort("`data` has 0 rows.")
  }

  has_start_end <- !is.null(start) && !is.null(end)
  if (xor(!is.null(start), !is.null(end))) {
    rlang::abort("Provide both `start` and `end` for interval validation, or neither.")
  }

  check_date_col <- function(col) {
    if (!col %in% names(data)) {
      rlang::abort(sprintf("Date column '%s' not found in `data`.", col))
    }
    dates <- data[[col]]
    if (!inherits(dates, c("Date", "POSIXt")) && !is.numeric(dates)) {
      parsed <- suppressWarnings(as.Date(as.character(dates)))
      if (all(is.na(parsed)) && any(!is.na(dates))) {
        rlang::abort(
          sprintf(
            "Column '%s' must be Date/POSIXt (or coercible to Date).",
            col
          )
        )
      }
    }
    if (anyNA(dates)) {
      rlang::warn(sprintf("Column '%s' contains missing values.", col))
    }
  }

  if (has_start_end) {
    check_date_col(start)
    check_date_col(end)
    inverted <- .date_to_numeric(data[[end]]) < .date_to_numeric(data[[start]])
    if (any(inverted, na.rm = TRUE)) {
      rlang::warn(
        sprintf(
          "%d row(s) have end < start; ggtimeline() will swap them.",
          sum(inverted, na.rm = TRUE)
        )
      )
    }
  } else {
    check_date_col(date)
  }

  if (require_label && !label %in% names(data)) {
    rlang::abort(sprintf("Label column '%s' not found in `data`.", label))
  }

  invisible(data)
}
