# Shared helper for reserved / unavailable APIs.

.ggtimeline_not_implemented <- function(feature, details = NULL) {
  msgs <- c(
    sprintf("`%s` is not available yet.", feature)
  )
  if (!is.null(details) && nzchar(details)) {
    msgs <- c(msgs, i = details)
  }
  rlang::abort(msgs, class = "ggtimeline_not_implemented")
}

.check_reserved <- function(arg_name, value, default = NULL) {
  # Abort when a reserved argument is intentionally set to a non-default.
  if (identical(value, default)) {
    return(invisible(NULL))
  }
  .ggtimeline_not_implemented(
    arg_name,
    details = sprintf("Leave `%s` at its default for now.", arg_name)
  )
}
