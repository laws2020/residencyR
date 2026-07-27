## Public entry point: dispatches across registered sources and
## combines their results into a single residency audit table.
##
## Each source is scanned inside a tryCatch, so one broken scan
## source (a bad custom extension, bad config) doesn't crash the
## entire audit -- but a failure is never *silent*. It's recorded in
## a "scan_errors" attribute on the returned data.frame, and both
## certificate generators check for it and surface it prominently.
## An audit that quietly dropped a source and looked smaller and
## cleaner than it should have is worse than one that visibly failed.

#' Scan payment data residency across registered sources
#'
#' @param sources Character vector of source names to scan. Defaults
#'   to all registered sources.
#' @param configs Named list, keyed by source name, of the config to
#'   pass to that source's scan function. E.g.
#'   list(db = list(list(item = "core_banking_db",
#'                        provider = "MainOne", region = "Lagos-NG")))
#' @return A data.frame combining results from all requested sources.
#'   If any source failed to scan, the result carries a
#'   "scan_errors" attribute: a character vector of
#'   "source: message" entries.
#' @export
scan_data_residency <- function(sources = list_residency_sources(),
                                 configs = list()) {
  if (length(sources) == 0L) {
    stop("No residency sources registered or requested.", call. = FALSE)
  }

  errors <- character(0)

  results <- lapply(sources, function(src) {
    tryCatch({
      scan_fn <- get_residency_source(src)
      cfg <- if (!is.null(configs[[src]])) configs[[src]] else list()
      scan_fn(cfg)
    }, error = function(e) {
      errors[[length(errors) + 1L]] <<- sprintf("%s: %s", src, conditionMessage(e))
      .empty_residency_frame()
    })
  })

  out <- do.call(rbind, results)
  if (is.null(out)) out <- .empty_residency_frame()
  rownames(out) <- NULL

  if (length(errors) > 0L) {
    attr(out, "scan_errors") <- errors
  }
  out
}

#' Flag offshore residency records
#'
#' @param audit A data.frame as returned by [scan_data_residency()].
#' @return Subset of `audit` where jurisdiction is "offshore" or
#'   "unknown" (needs manual review). Carries over any "scan_errors"
#'   attribute from `audit`.
#' @export
flag_offshore_calls <- function(audit) {
  stopifnot(is.data.frame(audit), "jurisdiction" %in% names(audit))
  out <- audit[audit$jurisdiction %in% c("offshore", "unknown"), , drop = FALSE]
  scan_errors <- attr(audit, "scan_errors")
  if (!is.null(scan_errors)) attr(out, "scan_errors") <- scan_errors
  out
}
