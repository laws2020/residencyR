## Step 1 scan source: database hosting residency.
## Takes a config describing known DB endpoints (no live connection
## required -- config can be hand-maintained or generated from an
## infra inventory) and classifies each as local/offshore/unknown.

#' Scan database hosting residency
#'
#' @param config List of DB endpoint descriptors. Each element must
#'   be a list with `item` (name), `provider`, and `region`.
#'   Example:
#'   list(list(item = "core_banking_db", provider = "MainOne",
#'             region = "Lagos-NG"))
#' @return A data.frame with columns: source, item, location,
#'   jurisdiction, provider, status.
#' @export
scan_source_db <- function(config) {
  if (length(config) == 0L) {
    return(.empty_residency_frame())
  }

  valid <- vapply(config, function(entry) {
    all(c("item", "provider", "region") %in% names(entry))
  }, logical(1))
  if (!all(valid)) {
    stop("All database configuration entries must contain 'item', 'provider', and 'region' attributes.", call. = FALSE)
  }

  items     <- vapply(config, function(x) as.character(x$item), character(1))
  providers <- vapply(config, function(x) as.character(x$provider), character(1))
  regions   <- vapply(config, function(x) as.character(x$region), character(1))

  jurisdictions <- classify_jurisdiction(providers, regions)
  statuses <- ifelse(jurisdictions == "local", "ok", "flagged")

  data.frame(
    source = "db",
    item = items,
    location = regions,
    jurisdiction = jurisdictions,
    provider = providers,
    status = statuses,
    stringsAsFactors = FALSE
  )
}
