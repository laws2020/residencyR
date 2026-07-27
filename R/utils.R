## Shared empty-frame schema, used by every scan_source_*() function
## when given an empty config. Defined once here instead of
## duplicated per source file.

#' @keywords internal
.empty_residency_frame <- function() {
  data.frame(
    source = character(0),
    item = character(0),
    location = character(0),
    jurisdiction = character(0),
    provider = character(0),
    status = character(0),
    stringsAsFactors = FALSE
  )
}
