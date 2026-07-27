## Real config ingestion, starting with CSV -- the format any CISO
## or infra team can export from an asset inventory, cloud billing
## console, or spreadsheet without engineering help. Base R only
## (read.csv), no new dependency.
##
## Expected CSV shape (column names case-insensitive, order-agnostic):
##   source,item,provider,region
##   db,core_banking_db,MainOne,Lagos-NG
##   api_logs,fraud_scoring_api,AWS,eu-west-1
##   backups,dr_snapshot,Azure,West Europe (Ireland)
##   third_party_calls,chargeback_processor,Stripe,us-east-1
##
## One CSV can describe every source at once -- the `source` column
## routes each row to the right scan source.

#' Build a scan_data_residency() config from a CSV inventory
#'
#' @param path Character. Path to a CSV file with columns `source`,
#'   `item`, `provider`, `region` (case-insensitive, any order).
#' @return A named list suitable for passing as `configs` to
#'   [scan_data_residency()], keyed by source name.
#' @export
ingest_csv_inventory <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("File not found: %s", path), call. = FALSE)
  }

  raw <- utils::read.csv(path, stringsAsFactors = FALSE, colClasses = "character")
  names(raw) <- tolower(trimws(names(raw)))

  required <- c("source", "item", "provider", "region")
  missing_cols <- setdiff(required, names(raw))
  if (length(missing_cols) > 0) {
    stop(
      sprintf(
        "CSV is missing required column(s): %s. Found columns: %s",
        paste(missing_cols, collapse = ", "),
        paste(names(raw), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  n_before <- nrow(raw)
  raw <- raw[!is.na(raw$source) & trimws(raw$source) != "", , drop = FALSE]
  n_dropped <- n_before - nrow(raw)
  if (n_dropped > 0L) {
    warning(
      sprintf(
        "%d row(s) dropped from the CSV: blank or missing 'source' value. These rows are NOT included in the resulting audit.",
        n_dropped
      ),
      call. = FALSE
    )
  }
  if (nrow(raw) == 0L) {
    return(list())
  }

  raw$source <- trimws(raw$source)
  known <- list_residency_sources()
  unknown_sources <- setdiff(unique(raw$source), known)
  if (length(unknown_sources) > 0) {
    warning(
      sprintf(
        "CSV references source(s) not registered: %s. These rows will still be grouped, but scan_data_residency() will error unless a matching source is registered first.",
        paste(unknown_sources, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  split_rows <- split(raw, raw$source)
  configs <- lapply(split_rows, function(df) {
    lapply(seq_len(nrow(df)), function(i) {
      list(
        item = df$item[i],
        provider = df$provider[i],
        region = df$region[i]
      )
    })
  })

  configs
}

#' Run a full residency audit directly from a CSV inventory
#'
#' Convenience wrapper: reads the CSV, builds the config, and runs
#' [scan_data_residency()] in one call.
#'
#' @param path Character. Path to the CSV inventory.
#' @return A data.frame, same shape as [scan_data_residency()].
#' @export
scan_from_csv <- function(path) {
  configs <- ingest_csv_inventory(path)
  if (length(configs) == 0L) {
    stop("CSV produced no usable rows.", call. = FALSE)
  }
  scan_data_residency(sources = names(configs), configs = configs)
}
