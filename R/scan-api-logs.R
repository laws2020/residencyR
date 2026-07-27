## Step 2 scan source: outbound API call destination residency.

#' Scan API call destination residency
#'
#' @param config List of API call descriptors. Each element must be
#'   a list with `item` (endpoint/vendor name), `provider`, and
#'   `region`. Example:
#'   list(list(item = "fraud_scoring_api", provider = "AWS",
#'             region = "eu-west-1"))
#' @return A data.frame with columns: source, item, location,
#'   jurisdiction, provider, status.
#' @export
scan_source_api_logs <- function(config) {
  if (length(config) == 0L) {
    return(.empty_residency_frame())
  }

  valid <- vapply(config, function(entry) {
    all(c("item", "provider", "region") %in% names(entry))
  }, logical(1))
  if (!all(valid)) {
    stop("All API configuration entries must contain 'item', 'provider', and 'region' attributes.", call. = FALSE)
  }

  items     <- vapply(config, function(x) as.character(x$item), character(1))
  providers <- vapply(config, function(x) as.character(x$provider), character(1))
  regions   <- vapply(config, function(x) as.character(x$region), character(1))

  jurisdictions <- classify_jurisdiction(providers, regions)
  statuses <- ifelse(jurisdictions == "local", "ok", "flagged")

  data.frame(
    source = "api_logs",
    item = items,
    location = regions,
    jurisdiction = jurisdictions,
    provider = providers,
    status = statuses,
    stringsAsFactors = FALSE
  )
}
