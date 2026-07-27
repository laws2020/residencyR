## Step 3 scan source: third-party vendor data flow residency.

#' Scan third-party vendor data flow residency
#'
#' @param config List of vendor descriptors. Each element must be a
#'   list with `item` (vendor/purpose name), `provider`, and
#'   `region`. Example:
#'   list(list(item = "chargeback_processor", provider = "Stripe",
#'             region = "US"))
#' @return A data.frame with columns: source, item, location,
#'   jurisdiction, provider, status.
#' @export
scan_source_third_party_calls <- function(config) {
  if (length(config) == 0L) {
    return(.empty_residency_frame())
  }

  valid <- vapply(config, function(entry) {
    all(c("item", "provider", "region") %in% names(entry))
  }, logical(1))
  if (!all(valid)) {
    stop("All third-party configuration entries must contain 'item', 'provider', and 'region' attributes.", call. = FALSE)
  }

  items     <- vapply(config, function(x) as.character(x$item), character(1))
  providers <- vapply(config, function(x) as.character(x$provider), character(1))
  regions   <- vapply(config, function(x) as.character(x$region), character(1))

  jurisdictions <- classify_jurisdiction(providers, regions)
  statuses <- ifelse(jurisdictions == "local", "ok", "flagged")

  data.frame(
    source = "third_party_calls",
    item = items,
    location = regions,
    jurisdiction = jurisdictions,
    provider = providers,
    status = statuses,
    stringsAsFactors = FALSE
  )
}
