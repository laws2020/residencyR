## Step 2 scan source: backup and disaster-recovery storage residency.

#' Scan backup and disaster-recovery storage residency
#'
#' @param config List of backup target descriptors. Each element
#'   must be a list with `item` (backup set name), `provider`, and
#'   `region`. Example:
#'   list(list(item = "dr_snapshot", provider = "Azure",
#'             region = "West Europe (Netherlands)"))
#' @return A data.frame with columns: source, item, location,
#'   jurisdiction, provider, status.
#' @export
scan_source_backups <- function(config) {
  if (length(config) == 0L) {
    return(.empty_residency_frame())
  }

  valid <- vapply(config, function(entry) {
    all(c("item", "provider", "region") %in% names(entry))
  }, logical(1))
  if (!all(valid)) {
    stop("All backup configuration entries must contain 'item', 'provider', and 'region' attributes.", call. = FALSE)
  }

  items     <- vapply(config, function(x) as.character(x$item), character(1))
  providers <- vapply(config, function(x) as.character(x$provider), character(1))
  regions   <- vapply(config, function(x) as.character(x$region), character(1))

  jurisdictions <- classify_jurisdiction(providers, regions)
  statuses <- ifelse(jurisdictions == "local", "ok", "flagged")

  data.frame(
    source = "backups",
    item = items,
    location = regions,
    jurisdiction = jurisdictions,
    provider = providers,
    status = statuses,
    stringsAsFactors = FALSE
  )
}
