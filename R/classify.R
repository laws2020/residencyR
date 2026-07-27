## Shared classification logic: given provider/region text, decide
## whether it counts as Nigerian-resident, offshore, or
## unknown/needs-review. Kept as simple pattern matching so it has
## no dependency beyond base R and is easy to extend as new
## providers/regions come up.
##
## Properly vectorized: provider and region can be character vectors
## of equal length (one row per data point), and the result is a
## same-length character vector -- this is what lets the scan_source_*()
## functions classify an entire config in one call instead of looping
## row by row.
##
## New indicator names are only added here after verification against
## an external source -- an unverified provider name in this list is
## exactly the kind of error that could make an offshore deployment
## silently read as compliant. "wiocc" was added after confirming
## WIOCC operates a real Lagos, Nigeria facility (as OADC's parent).
## A few other candidate names (PAIX, Layer3, Cloudflex, Wichtech)
## were considered and left out -- PAIX's known facilities are in
## Ghana, Kenya, Cote d'Ivoire and Senegal, not Nigeria, and the
## other three had no verifiable Nigerian presence found.

.ng_indicators <- c(
  "nigeria", "lagos", "abuja", "ng-", "ng_", "naija",
  "mainone", "galaxy", "oadc", "wiocc", "rack centre", "medallion"
)

.offshore_indicators <- c(
  "us-east", "us-west", "eu-west", "eu-central", "ap-south",
  "aws", "azure", "gcp", "google cloud", "amazon", "microsoft",
  "ireland", "frankfurt", "virginia", "london", "singapore"
)

#' Classify provider/region text as local, offshore, or unknown
#'
#' @param provider Character vector. Hosting provider name(s).
#' @param region Character vector. Region/location string(s), same
#'   length as `provider`.
#' @return Character vector, same length as the input: "local",
#'   "offshore", or "unknown" per element. A row that matches both a
#'   local and an offshore indicator (e.g. an AWS region string with
#'   an "ng-" prefix) resolves to "unknown", not "local" -- a mixed
#'   signal is exactly the kind of thing worth a human's attention,
#'   not an automatic pass.
#' @export
classify_jurisdiction <- function(provider, region) {
  text <- tolower(paste(provider, region))
  n <- length(text)

  is_local <- rep(FALSE, n)
  for (ind in .ng_indicators) {
    is_local <- is_local | grepl(ind, text, fixed = TRUE)
  }

  is_offshore <- rep(FALSE, n)
  for (ind in .offshore_indicators) {
    is_offshore <- is_offshore | grepl(ind, text, fixed = TRUE)
  }

  ifelse(is_local & !is_offshore, "local",
    ifelse(is_offshore & !is_local, "offshore", "unknown")
  )
}
