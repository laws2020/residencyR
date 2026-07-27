## Registry-driven dispatch for residency scan sources. An internal
## environment holds named scan functions; sources register
## themselves at load time, and scan_data_residency() dispatches
## across whichever sources are requested.
##
## Names are normalized (lowercase, trimmed) on both register and
## lookup, so "DB", " db ", and "db" all resolve to the same source
## -- a small robustness improvement for anyone building configs by
## hand or from a CSV where casing/whitespace isn't guaranteed clean.

.residency_registry <- new.env(parent = emptyenv())

#' @keywords internal
.normalize_source_name <- function(name) {
  tolower(trimws(name))
}

#' Register a residency scan source
#'
#' @param name Character. Unique source name (e.g. "db", "api_logs").
#'   Matching is case-insensitive and whitespace-tolerant.
#' @param scan_fn Function. Takes a config list, returns a data.frame
#'   with columns: source, item, location, jurisdiction, provider, status.
#' @export
register_residency_source <- function(name, scan_fn) {
  stopifnot(is.character(name), length(name) == 1L)
  stopifnot(is.function(scan_fn))
  assign(.normalize_source_name(name), scan_fn, envir = .residency_registry)
  invisible(TRUE)
}

#' List registered residency scan sources
#'
#' @return Character vector of registered source names.
#' @export
list_residency_sources <- function() {
  sort(ls(envir = .residency_registry))
}

#' Retrieve a registered scan source function
#'
#' @param name Character. Source name.
#' @return The scan function registered under `name`.
#' @keywords internal
get_residency_source <- function(name) {
  clean_name <- .normalize_source_name(name)
  if (!exists(clean_name, envir = .residency_registry, inherits = FALSE)) {
    stop(
      sprintf(
        "Unknown residency source '%s'. Registered sources: %s",
        name,
        paste(list_residency_sources(), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  get(clean_name, envir = .residency_registry, inherits = FALSE)
}
