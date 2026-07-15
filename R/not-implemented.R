# Shared helper for scaffolded APIs that are not implemented yet.

.ggtimeline_not_implemented <- function(feature, details = NULL) {
  msgs <- c(
    sprintf("`%s` is scaffolded but not implemented yet.", feature),
    i = "See the package ROADMAP.md for priority and design notes."
  )
  if (!is.null(details) && nzchar(details)) {
    msgs <- c(msgs, i = details)
  }
  rlang::abort(msgs, class = "ggtimeline_not_implemented")
}

.check_reserved <- function(arg_name, value, default = NULL) {
  # Abort when a reserved/upcoming argument is intentionally set.
  different <- !identical(value, default)
  if (!different) {
    return(invisible(NULL))
  }
  .ggtimeline_not_implemented(
    arg_name,
    details = sprintf(
      "Pass the default for now, or follow ROADMAP.md for when `%s` lands.",
      arg_name
    )
  )
}
